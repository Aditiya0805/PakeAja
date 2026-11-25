import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../../../core/utils/auth_result.dart';
import '../../../core/utils/error_handler.dart';
import '../../../firebase_options.dart';

class AuthService {
  FirebaseAuth? _authInstance;
  FirebaseFirestore? _firestoreInstance;
  GoogleSignIn? _googleSignIn;

  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _authInstance = auth,
        _firestoreInstance = firestore,
        _googleSignIn = googleSignIn;

  Future<void> _ensureInitialized() async {
    if (Firebase.apps.isEmpty) {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        if (kIsWeb) {
          try {
            FirebaseFirestore.instance.settings = const Settings(
              persistenceEnabled: false,
              webExperimentalForceLongPolling: true,
            );
          } catch (_) {}
        }
      } catch (e) {
        debugPrint('AuthService lazy init Firebase info: $e');
      }
    }
  }

  FirebaseAuth get _auth {
    final cached = _authInstance;
    if (cached != null) return cached;
    try {
      return _authInstance = FirebaseAuth.instance;
    } catch (_) {
      try {
        if (Firebase.apps.isNotEmpty) {
          return _authInstance = FirebaseAuth.instanceFor(app: Firebase.app());
        }
      } catch (_) {}
    }
    throw StateError('Firebase Auth belum terinisialisasi.');
  }

  FirebaseFirestore get _firestore {
    final cached = _firestoreInstance;
    if (cached != null) return cached;
    try {
      final fs = FirebaseFirestore.instance;
      if (kIsWeb) {
        try {
          fs.settings = const Settings(
            persistenceEnabled: false,
            webExperimentalForceLongPolling: true,
          );
        } catch (_) {}
      }
      return _firestoreInstance = fs;
    } catch (_) {
      try {
        if (Firebase.apps.isNotEmpty) {
          return _firestoreInstance =
              FirebaseFirestore.instanceFor(app: Firebase.app());
        }
      } catch (_) {}
    }
    throw StateError('Cloud Firestore belum terinisialisasi.');
  }

  GoogleSignIn _getGoogleSignIn() {
    return _googleSignIn ??= GoogleSignIn(
      clientId: kIsWeb ? null : null,
    );
  }

  // Stream user saat ini (aman jika Firebase belum siap / di web)
  Stream<User?> get authStateChanges {
    try {
      if (Firebase.apps.isNotEmpty || _authInstance != null) {
        return _auth.authStateChanges();
      }
    } catch (_) {}
    return Stream.value(null);
  }

  User? get currentUser {
    try {
      if (Firebase.apps.isNotEmpty || _authInstance != null) {
        return _auth.currentUser;
      }
    } catch (_) {}
    return null;
  }

  String? get currentUid => currentUser?.uid;

  // ==================== REGISTER ====================
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await _ensureInitialized();
    User? user;
    try {
      try {
        final credential = await _auth
            .createUserWithEmailAndPassword(
              email: email.trim(),
              password: password,
            )
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () => throw TimeoutException(
                'Proses pendaftaran melebihi batas waktu (timeout). Silakan periksa koneksi internet Anda.',
              ),
            );
        user = credential.user;
      } catch (e) {
        if (kIsWeb) {
          try {
            await _auth.setPersistence(Persistence.NONE);
            final credential = await _auth
                .createUserWithEmailAndPassword(
                  email: email.trim(),
                  password: password,
                )
                .timeout(const Duration(seconds: 15));
            user = credential.user;
          } catch (_) {}
        }
        if (user == null) rethrow;
      }

      if (user == null) {
        return AuthResult.fail('Gagal membuat akun.');
      }
    } on TimeoutException catch (e) {
      return AuthResult.fail(e.message ?? 'Waktu koneksi habis. Silakan coba lagi.');
    } on FirebaseAuthException catch (e) {
      return AuthResult.fail(ErrorHandler.handle(e));
    } on Exception catch (e) {
      return AuthResult.fail(ErrorHandler.handle(e));
    } catch (e) {
      return AuthResult.fail(ErrorHandler.handle(e));
    }

    // === TAHAP 2: PROFIL & FIRESTORE TERISOLASI (TIDAK MEMBATALKAN HASIL REGISTER) ===
    try {
      await user
          .updateDisplayName(name.trim())
          .timeout(const Duration(seconds: 4));
      await user.reload().timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('Update display name tertunda: $e');
    }

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set({
            'name': name.trim(),
            'email': email.trim(),
            'photoUrl': null,
            'createdAt': FieldValue.serverTimestamp(),
          })
          .timeout(const Duration(seconds: 6));
    } catch (e) {
      debugPrint('Penulisan data pengguna ke Firestore dilewati/tertunda: $e');
    }

    return AuthResult.ok(user);
  }

  // ==================== REST API FALLBACK (WEB) ====================
  Future<AuthResult> _verifyViaRestApi(String email, String password) async {
    try {
      final apiKey = DefaultFirebaseOptions.web.apiKey;
      final uri = Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey',
      );
      final client = http.Client();
      try {
        final response = await client
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'email': email.trim(),
                'password': password,
                'returnSecureToken': true,
              }),
            )
            .timeout(const Duration(seconds: 12));

        if (response.statusCode == 200) {
          return AuthResult.ok(null);
        } else {
          final dynamic body = jsonDecode(response.body);
          if (body is Map<String, dynamic>) {
            final error = body['error'];
            if (error is Map<String, dynamic>) {
              final errorMsg = error['message'] as String? ?? '';
              if (errorMsg.contains('INVALID_LOGIN_CREDENTIALS') ||
                  errorMsg.contains('INVALID_PASSWORD')) {
                return AuthResult.fail(
                    'Email atau password salah. Silakan periksa kembali.');
              } else if (errorMsg.contains('EMAIL_NOT_FOUND')) {
                return AuthResult.fail('Akun tidak ditemukan. Cek email kamu.');
              } else if (errorMsg.contains('USER_DISABLED')) {
                return AuthResult.fail('Akun kamu telah dinonaktifkan.');
              } else if (errorMsg.contains('TOO_MANY_ATTEMPTS_TRY_LATER')) {
                return AuthResult.fail(
                    'Terlalu banyak percobaan. Coba beberapa saat lagi.');
              }
            }
          }
        }
      } finally {
        client.close();
      }
    } catch (e) {
      debugPrint('REST API verify error: $e');
    }
    return AuthResult.fail('Gagal masuk.');
  }

  // ==================== LOGIN ====================
  Future<AuthResult> login({
    required String email,
    required String password,
    String? name,
  }) async {
    await _ensureInitialized();
    User? user;
    final cleanEmail = email.trim();
    final trimmedName = name?.trim() ?? '';

    try {
      try {
        final credential = await _auth
            .signInWithEmailAndPassword(
              email: cleanEmail,
              password: password,
            )
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () => throw TimeoutException(
                'Proses masuk melebihi batas waktu (timeout). Silakan periksa koneksi internet Anda.',
              ),
            );
        user = credential.user;
      } catch (e) {
        if (kIsWeb) {
          // Jika gagal di WebKit iOS, cek kredensial langsung via REST API Firebase
          final restCheck = await _verifyViaRestApi(cleanEmail, password);
          if (!restCheck.success) {
            // Jika akun memang salah password/tidak ada, laporkan error spesifiknya
            return restCheck;
          }
          // Kredensial valid! Coba login ulang dengan Persistence.NONE (in-memory)
          try {
            await _auth.setPersistence(Persistence.NONE);
            final credential = await _auth
                .signInWithEmailAndPassword(
                  email: cleanEmail,
                  password: password,
                )
                .timeout(const Duration(seconds: 15));
            user = credential.user;
          } catch (_) {}
        }
        if (user == null) rethrow;
      }

      if (user == null) {
        return AuthResult.fail('Gagal masuk.');
      }
    } on TimeoutException catch (e) {
      return AuthResult.fail(e.message ?? 'Waktu koneksi habis. Silakan coba lagi.');
    } on FirebaseAuthException catch (e) {
      return AuthResult.fail(ErrorHandler.handle(e));
    } on Exception catch (e) {
      return AuthResult.fail(ErrorHandler.handle(e));
    } catch (e) {
      return AuthResult.fail(ErrorHandler.handle(e));
    }

    // === TAHAP 2: PROFIL & FIRESTORE TERISOLASI SECARA TOTAL ===
    try {
      final currentUser = user;
      if (trimmedName.isNotEmpty) {
        if ((currentUser.displayName ?? '') != trimmedName) {
          try {
            await currentUser
                .updateDisplayName(trimmedName)
                .timeout(const Duration(seconds: 4));
            await currentUser.reload().timeout(const Duration(seconds: 4));
          } catch (_) {}
        }
        try {
          final userDoc = _firestore.collection('users').doc(currentUser.uid);
          final snap = await userDoc.get().timeout(const Duration(seconds: 6));
          if (snap.exists) {
            await userDoc.update({
              'name': trimmedName,
              'updatedAt': FieldValue.serverTimestamp(),
            }).timeout(const Duration(seconds: 6));
          } else {
            await userDoc.set({
              'name': trimmedName,
              'email': currentUser.email ?? cleanEmail,
              'photoUrl': currentUser.photoURL,
              'createdAt': FieldValue.serverTimestamp(),
            }).timeout(const Duration(seconds: 6));
          }
        } catch (e) {
          debugPrint('Sinkronisasi Firestore saat login tertunda: $e');
        }
      }
    } catch (e) {
      debugPrint('Tahap 2 non-fatal: $e');
    }

    return AuthResult.ok(user);
  }

  // ==================== GOOGLE SIGN-IN ====================
  Future<AuthResult> signInWithGoogle({String? name}) async {
    await _ensureInitialized();
    User? user;
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        userCredential = await _auth
            .signInWithPopup(googleProvider)
            .timeout(
              const Duration(seconds: 60),
              onTimeout: () => throw TimeoutException(
                'Waktu masuk dengan Google melebihi batas waktu.',
              ),
            );
      } else {
        final GoogleSignInAccount? googleUser =
            await _getGoogleSignIn().signIn().timeout(
                  const Duration(seconds: 60),
                  onTimeout: () => throw TimeoutException(
                    'Waktu pemilihan akun Google habis.',
                  ),
                );

        if (googleUser == null) {
          return AuthResult.fail('Login Google dibatalkan.');
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication.timeout(
              const Duration(seconds: 15),
              onTimeout: () => throw TimeoutException(
                'Waktu autentikasi Google habis.',
              ),
            );

        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await _auth
            .signInWithCredential(credential)
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () => throw TimeoutException(
                'Waktu verifikasi akun Google habis.',
              ),
            );
      }

      user = userCredential.user;
      if (user == null) {
        return AuthResult.fail('Gagal masuk dengan Google.');
      }
    } on TimeoutException catch (e) {
      return AuthResult.fail(e.message ?? 'Waktu koneksi habis. Silakan coba lagi.');
    } on FirebaseAuthException catch (e) {
      return AuthResult.fail(ErrorHandler.handle(e));
    } on Exception catch (e) {
      return AuthResult.fail(ErrorHandler.handle(e));
    } catch (e) {
      return AuthResult.fail('Terjadi kesalahan masuk dengan Google: $e');
    }

    // === TAHAP 2: PROFIL & FIRESTORE TERISOLASI (TIDAK MEMBATALKAN HASIL SIGN IN GOOGLE) ===
    final effectiveName = (name != null && name.trim().isNotEmpty)
        ? name.trim()
        : (user.displayName ?? 'Pengguna');

    if (user.displayName != effectiveName) {
      try {
        await user
            .updateDisplayName(effectiveName)
            .timeout(const Duration(seconds: 4));
        await user.reload().timeout(const Duration(seconds: 4));
      } catch (_) {}
    }

    try {
      final userDoc = _firestore.collection('users').doc(user.uid);
      final docSnapshot =
          await userDoc.get().timeout(const Duration(seconds: 6));

      if (!docSnapshot.exists) {
        await userDoc.set({
          'name': effectiveName,
          'email': user.email,
          'photoUrl': user.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
        }).timeout(const Duration(seconds: 6));
      } else if (name != null && name.trim().isNotEmpty) {
        await userDoc.update({
          'name': effectiveName,
          'updatedAt': FieldValue.serverTimestamp(),
        }).timeout(const Duration(seconds: 6));
      }
    } catch (e) {
      debugPrint('Sinkronisasi profil Firestore saat login Google tertunda: $e');
    }

    return AuthResult.ok(user);
  }

  // ==================== RESET PASSWORD ====================
  Future<AuthResult> sendPasswordResetEmail(String email) async {
    await _ensureInitialized();
    try {
      await _auth
          .sendPasswordResetEmail(email: email.trim())
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException(
              'Waktu pengiriman email reset password habis. Periksa koneksi internet Anda.',
            ),
          );
      return AuthResult.ok(null);
    } on TimeoutException catch (e) {
      return AuthResult.fail(e.message ?? 'Waktu koneksi habis.');
    } on FirebaseAuthException catch (e) {
      return AuthResult.fail(ErrorHandler.handle(e));
    } on Exception catch (e) {
      return AuthResult.fail(ErrorHandler.handle(e));
    } catch (e) {
      return AuthResult.fail('Gagal mengirim email reset password: $e');
    }
  }

  // ==================== LOGOUT ====================
  Future<AuthResult> logout() async {
    try {
      if (!kIsWeb) {
        try {
          await _getGoogleSignIn()
              .signOut()
              .timeout(const Duration(seconds: 5));
        } catch (_) {}
      }
      await _auth.signOut().timeout(const Duration(seconds: 6));
      return AuthResult.ok(null);
    } on Exception catch (e) {
      return AuthResult.fail(ErrorHandler.handle(e));
    } catch (e) {
      return AuthResult.fail('Gagal logout: $e');
    }
  }

  // ==================== HAPUS AKUN ====================
  Future<AuthResult> deleteAccount(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return AuthResult.fail('Pengguna tidak ditemukan.');

      final isPasswordUser = user.providerData
          .any((p) => p.providerId == 'password');

      if (isPasswordUser) {
        final email = user.email;
        if (email == null) return AuthResult.fail('Email pengguna tidak valid.');

        final cred = EmailAuthProvider.credential(
          email: email,
          password: password,
        );
        await user
            .reauthenticateWithCredential(cred)
            .timeout(const Duration(seconds: 15));
      } else {
        if (!kIsWeb) {
          final googleUser = await _getGoogleSignIn().signIn().timeout(
                const Duration(seconds: 60),
              );
          if (googleUser == null) {
            return AuthResult.fail('Re-autentikasi Google dibatalkan.');
          }
          final googleAuth = await googleUser.authentication.timeout(
            const Duration(seconds: 15),
          );
          final cred = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );
          await user
              .reauthenticateWithCredential(cred)
              .timeout(const Duration(seconds: 15));
        }
      }

      final uid = user.uid;

      try {
        final clothes = await _firestore
            .collection('users')
            .doc(uid)
            .collection('clothes')
            .get()
            .timeout(const Duration(seconds: 8));
        for (final doc in clothes.docs) {
          await doc.reference.delete().timeout(const Duration(seconds: 3));
        }

        final outfits = await _firestore
            .collection('users')
            .doc(uid)
            .collection('outfits')
            .get()
            .timeout(const Duration(seconds: 8));
        for (final doc in outfits.docs) {
          await doc.reference.delete().timeout(const Duration(seconds: 3));
        }

        await _firestore
            .collection('users')
            .doc(uid)
            .delete()
            .timeout(const Duration(seconds: 8));
      } catch (e) {
        debugPrint('Pembersihan dokumen Firestore sebelum hapus akun tertunda: $e');
      }

      await user.delete().timeout(const Duration(seconds: 15));

      return AuthResult.ok(null);
    } on FirebaseAuthException catch (e) {
      return AuthResult.fail(ErrorHandler.handle(e));
    } on Exception catch (e) {
      return AuthResult.fail(ErrorHandler.handle(e));
    } catch (e) {
      return AuthResult.fail('Gagal menghapus akun: $e');
    }
  }

  // ==================== UPDATE PROFILE ====================
  Future<AuthResult> updateProfile({String? name, String? photoUrl}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return AuthResult.fail('Pengguna belum masuk.');

      if (name != null) {
        await user
            .updateDisplayName(name.trim())
            .timeout(const Duration(seconds: 6));
      }
      if (photoUrl != null) {
        await user
            .updatePhotoURL(photoUrl)
            .timeout(const Duration(seconds: 6));
      }
      await user.reload().timeout(const Duration(seconds: 6));

      final data = <String, dynamic>{};
      if (name != null) data['name'] = name.trim();
      if (photoUrl != null) data['photoUrl'] = photoUrl;

      if (data.isNotEmpty) {
        data['updatedAt'] = FieldValue.serverTimestamp();
        final userDoc = _firestore.collection('users').doc(user.uid);
        final snap = await userDoc.get().timeout(const Duration(seconds: 6));
        if (snap.exists) {
          await userDoc.update(data).timeout(const Duration(seconds: 6));
        } else {
          data['email'] = user.email;
          data['createdAt'] = FieldValue.serverTimestamp();
          await userDoc.set(data).timeout(const Duration(seconds: 6));
        }
      }

      return AuthResult.ok(_auth.currentUser);
    } on FirebaseAuthException catch (e) {
      return AuthResult.fail(ErrorHandler.handle(e));
    } on Exception catch (e) {
      return AuthResult.fail(ErrorHandler.handle(e));
    } catch (e) {
      return AuthResult.fail('Gagal memperbarui profil: $e');
    }
  }
}
