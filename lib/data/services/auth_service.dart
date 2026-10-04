import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/auth_result.dart';
import '../../../core/utils/error_handler.dart';

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

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
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return AuthResult.ok(credential.user);
    } on Exception catch (e) {
      return AuthResult.fail(ErrorHandler.handle(e));
    }
  }

  // ==================== GOOGLE SIGN-IN ====================
  Future<AuthResult> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
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

      // Buat/update dokumen user
      final userDoc = _firestore.collection('users').doc(user.uid);
      final doc = await userDoc.get();
      if (!doc.exists) {
        await userDoc.set({
          'name': user.displayName ?? 'Pengguna',
          'email': user.email ?? '',
          'photoUrl': user.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await userDoc.update({
          'photoUrl': user.photoURL,
          'name': user.displayName ?? doc['name'],
        });
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
      await _googleSignIn.signOut();
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

      if (name != null) {
        await user.updateDisplayName(name.trim());
      }

      final data = <String, dynamic>{};
      if (name != null) data['name'] = name.trim();
      if (photoUrl != null) data['photoUrl'] = photoUrl;

      await _firestore.collection('users').doc(user.uid).update(data);
      return AuthResult.ok(user);
    } on Exception catch (e) {
      return AuthResult.fail(ErrorHandler.handle(e));
    }
  }
}
