import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/auth_result.dart';
import '../../../core/utils/error_handler.dart';

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  GoogleSignIn? _googleSignIn;

  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn;

  GoogleSignIn _getGoogleSignIn() {
    return _googleSignIn ??= GoogleSignIn(
      clientId: kIsWeb ? null : null,
    );
  }

  // Stream user saat ini
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  String? get currentUid => _auth.currentUser?.uid;

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

      // Update display name
      await user.updateDisplayName(name.trim());

      // Buat dokumen user di Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'name': name.trim(),
        'email': email.trim(),
        'photoUrl': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return AuthResult.ok(user);
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
      final trimmedName = name?.trim() ?? '';

      if (user != null) {
        if (trimmedName.isNotEmpty) {
          await _syncUserName(user, trimmedName);
        } else {
          await _ensureUserDocExists(user);
        }
      }

      return AuthResult.ok(user);
    } on Exception catch (e) {
      return AuthResult.fail(ErrorHandler.handle(e));
    }
  }

  /// Sinkronkan nama yang diinputkan user ke Firebase Auth & dokumen Firestore.
  Future<void> _syncUserName(User user, String name) async {
    try {
      await user.updateDisplayName(name);
    } catch (_) {
      // Lanjutkan ke Firestore meskipun updateDisplayName gagal
    }
    try {
      final userDoc = _firestore.collection('users').doc(user.uid);
      final doc = await userDoc.get();
      if (!doc.exists) {
        await userDoc.set({
          'name': name,
          'email': user.email ?? '',
          'photoUrl': user.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await userDoc.set({'name': name}, SetOptions(merge: true));
      }
    } catch (_) {
      // Jangan blokir proses login jika penulisan ke Firestore tertunda/offline
    }
  }

  /// Pastikan dokumen user ada di Firestore saat login tanpa input nama.
  Future<void> _ensureUserDocExists(User user) async {
    try {
      final userDoc = _firestore.collection('users').doc(user.uid);
      final doc = await userDoc.get();
      if (!doc.exists) {
        final fallbackName = (user.displayName?.trim().isNotEmpty ?? false)
            ? user.displayName!.trim()
            : (user.email?.split('@').first ?? 'Pengguna');
        await userDoc.set({
          'name': fallbackName,
          'email': user.email ?? '',
          'photoUrl': user.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {
      // Abaikan agar tidak memblokir login
    }
  }

  // ==================== GOOGLE SIGN-IN ====================
  Future<AuthResult> signInWithGoogle({String? name}) async {
    if (kIsWeb) {
      return AuthResult.fail(
        'Login Google belum didukung di versi web. Silakan daftar/login dengan email dan password, atau gunakan aplikasi Android.',
      );
    }
    try {
      final googleUser = await _getGoogleSignIn().signIn();
      if (googleUser == null) {
        return AuthResult.fail('Login Google dibatalkan.');
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        return AuthResult.fail('Gagal login dengan Google.');
      }

      final trimmedName = name?.trim() ?? '';
      if (trimmedName.isNotEmpty) {
        try {
          await user.updateDisplayName(trimmedName);
        } catch (_) {}
      }

      // Buat/update dokumen user
      final userDoc = _firestore.collection('users').doc(user.uid);
      final doc = await userDoc.get();
      if (!doc.exists) {
        await userDoc.set({
          'name': trimmedName.isNotEmpty
              ? trimmedName
              : (user.displayName ?? 'Pengguna'),
          'email': user.email ?? '',
          'photoUrl': user.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        final existingName = (doc.data()?['name'] as String?)?.trim() ?? '';
        final resolvedName = trimmedName.isNotEmpty
            ? trimmedName
            : (existingName.isNotEmpty
                ? existingName
                : (user.displayName ?? 'Pengguna'));
        await userDoc.set({
          'photoUrl': user.photoURL,
          'name': resolvedName,
        }, SetOptions(merge: true));
      }

      return AuthResult.ok(user);
    } on Exception catch (e) {
      return AuthResult.fail(ErrorHandler.handle(e));
    }
  }

  // ==================== FORGOT PASSWORD ====================
  Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return AuthResult.ok(null);
    } on Exception catch (e) {
      return AuthResult.fail(ErrorHandler.handle(e));
    }
  }

  // ==================== LOGOUT ====================
  Future<AuthResult> logout() async {
    try {
      if (!kIsWeb) {
        await _getGoogleSignIn().signOut();
      }
      await _auth.signOut();
      return AuthResult.ok(null);
    } on Exception catch (e) {
      return AuthResult.fail(ErrorHandler.handle(e));
    }
  }

  // ==================== DELETE ACCOUNT ====================
  Future<AuthResult> deleteAccount(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return AuthResult.fail('Kamu belum login.');

      // Re-authenticate (wajib untuk delete)
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(cred);

      // Hapus data terkait
      await _deleteUserData(user.uid);

      // Hapus akun
      await user.delete();
      return AuthResult.ok(null);
    } on Exception catch (e) {
      return AuthResult.fail(ErrorHandler.handle(e));
    }
  }

  Future<void> _deleteUserData(String uid) async {
    // Hapus subcollections
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

    // Hapus dokumen user
    await _firestore.collection('users').doc(uid).delete();
  }

  // ==================== UPDATE PROFILE ====================
  Future<AuthResult> updateProfile({String? name, String? photoUrl}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return AuthResult.fail('Kamu belum login.');

      final trimmedName = name?.trim();
      if (trimmedName != null && trimmedName.isNotEmpty) {
        await user.updateDisplayName(trimmedName);
      }

      final data = <String, dynamic>{};
      if (trimmedName != null && trimmedName.isNotEmpty) {
        data['name'] = trimmedName;
      }
      if (photoUrl != null) data['photoUrl'] = photoUrl;

      if (data.isNotEmpty) {
        final userDoc = _firestore.collection('users').doc(user.uid);
        final doc = await userDoc.get();
        if (!doc.exists) {
          await userDoc.set({
            'name': trimmedName ?? user.displayName ?? 'Pengguna',
            'email': user.email ?? '',
            'photoUrl': photoUrl ?? user.photoURL,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } else {
          await userDoc.set(data, SetOptions(merge: true));
        }
      }
      return AuthResult.ok(user);
    } on Exception catch (e) {
      return AuthResult.fail(ErrorHandler.handle(e));
    }
  }
}
