import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/utils/auth_result.dart';
import '../../../core/utils/error_handler.dart';

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

  FirebaseAuth get _auth {
    if (_authInstance != null) return _authInstance!;
    try {
      if (Firebase.apps.isNotEmpty) {
        return _authInstance = FirebaseAuth.instance;
      }
    } catch (_) {}
    throw StateError('Firebase Auth belum terinisialisasi.');
  }

  FirebaseFirestore get _firestore {
    if (_firestoreInstance != null) return _firestoreInstance!;
    try {
      if (Firebase.apps.isNotEmpty) {
        return _firestoreInstance = FirebaseFirestore.instance;
      }
    } catch (_) {}
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
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        return AuthResult.fail('Gagal membuat akun.');
      }

      await user.updateDisplayName(name.trim());
      await user.reload();

      await _firestore.collection('users').doc(user.uid).set({
        'name': name.trim(),
        'email': email.trim(),
        'photoUrl': null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return AuthResult.ok(user);
    } on FirebaseAuthException catch (e) {
      return AuthResult.fail(ErrorHandler.handle(e));
    } on Exception catch (e) {
      return AuthResult.fail(ErrorHandler.handle(e));
    }
  }

  // ==================== LOGIN ====================
  Future<AuthResult> login({
    required String email,
    required String password,
    String? name,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        return AuthResult.fail('Gagal masuk.');
      }

      if (name != null && name.trim().isNotEmpty) {
        final trimmed = name.trim();
        if (user.displayName != trimmed) {
          try {
            await user.updateDisplayName(trimmed);
            await user.reload();
          } catch (_) {}
        }
        try {
          final userDoc = _firestore.collection('users').doc(user.uid);
          final snap = await userDoc.get();
          if (snap.exists) {
            await userDoc.update({
              'name': trimmed,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          } else {
            await userDoc.set({
              'name': trimmed,
              'email': user.email ?? email.trim(),
              'photoUrl': user.photoURL,
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
        } catch (_) {}
      }

      return AuthResult.ok(user);
    } on FirebaseAuthException catch (e) {
      return AuthResult.fail(ErrorHandler.handle(e));
    } on Exception catch (e) {
      return AuthResult.fail(ErrorHandler.handle(e));
    }
  }

  // ==================== GOOGLE SIGN-IN ====================
  Future<AuthResult> signInWithGoogle({String? name}) async {
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        final GoogleSignInAccount? googleUser =
            await _getGoogleSignIn().signIn();

        if (googleUser == null) {
          return AuthResult.fail('Login Google dibatalkan.');
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await _auth.signInWithCredential(credential);
      }

      final user = userCredential.user;
      if (user == null) {
        return AuthResult.fail('Gagal masuk dengan Google.');
      }

      final effectiveName = (name != null && name.trim().isNotEmpty)
          ? name.trim()
          : (user.displayName ?? 'Pengguna');

      if (user.displayName != effectiveName) {
        try {
          await user.updateDisplayName(effectiveName);
          await user.reload();
        } catch (_) {}
      }

      final userDoc = _firestore.collection('users').doc(user.uid);
      final docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        await userDoc.set({
          'name': effectiveName,
          'email': user.email,
          'photoUrl': user.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else if (name != null && name.trim().isNotEmpty) {
        await userDoc.update({
          'name': effectiveName,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      return AuthResult.ok(user);
    } on FirebaseAuthException catch (e) {
      return AuthResult.fail(ErrorHandler.handle(e));
    } on Exception catch (e) {
      return AuthResult.fail(ErrorHandler.handle(e));
    }
  }

  // ==================== RESET PASSWORD ====================
  Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return AuthResult.ok(null);
    } on FirebaseAuthException catch (e) {
      return AuthResult.fail(ErrorHandler.handle(e));
    } on Exception catch (e) {
      return AuthResult.fail(ErrorHandler.handle(e));
    }
  }

  // ==================== LOGOUT ====================
  Future<AuthResult> logout() async {
    try {
      if (!kIsWeb) {
        try {
          await _getGoogleSignIn().signOut();
        } catch (_) {}
      }
      await _auth.signOut();
      return AuthResult.ok(null);
    } on Exception catch (e) {
      return AuthResult.fail(ErrorHandler.handle(e));
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
        await user.reauthenticateWithCredential(cred);
      } else {
        if (!kIsWeb) {
          final googleUser = await _getGoogleSignIn().signIn();
          if (googleUser == null) {
            return AuthResult.fail('Re-autentikasi Google dibatalkan.');
          }
          final googleAuth = await googleUser.authentication;
          final cred = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );
          await user.reauthenticateWithCredential(cred);
        }
      }

      final uid = user.uid;

      final clothes = await _firestore
          .collection('users')
          .doc(uid)
          .collection('clothes')
          .get();
      for (final doc in clothes.docs) {
        await doc.reference.delete();
      }

      final outfits = await _firestore
          .collection('users')
          .doc(uid)
          .collection('outfits')
          .get();
      for (final doc in outfits.docs) {
        await doc.reference.delete();
      }

      await _firestore.collection('users').doc(uid).delete();
      await user.delete();

      return AuthResult.ok(null);
    } on FirebaseAuthException catch (e) {
      return AuthResult.fail(ErrorHandler.handle(e));
    } on Exception catch (e) {
      return AuthResult.fail(ErrorHandler.handle(e));
    }
  }

  // ==================== UPDATE PROFILE ====================
  Future<AuthResult> updateProfile({String? name, String? photoUrl}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return AuthResult.fail('Pengguna belum masuk.');

      if (name != null) {
        await user.updateDisplayName(name.trim());
      }
      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
      }
      await user.reload();

      final data = <String, dynamic>{};
      if (name != null) data['name'] = name.trim();
      if (photoUrl != null) data['photoUrl'] = photoUrl;

      if (data.isNotEmpty) {
        data['updatedAt'] = FieldValue.serverTimestamp();
        final userDoc = _firestore.collection('users').doc(user.uid);
        final snap = await userDoc.get();
        if (snap.exists) {
          await userDoc.update(data);
        } else {
          data['email'] = user.email;
          data['createdAt'] = FieldValue.serverTimestamp();
          await userDoc.set(data);
        }
      }

      return AuthResult.ok(_auth.currentUser);
    } on FirebaseAuthException catch (e) {
      return AuthResult.fail(ErrorHandler.handle(e));
    } on Exception catch (e) {
      return AuthResult.fail(ErrorHandler.handle(e));
    }
  }
}
