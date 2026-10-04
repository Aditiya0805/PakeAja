import 'package:firebase_auth/firebase_auth.dart';

class AuthResult {
  final bool success;
  final String? message;
  final User? user;

  const AuthResult({
    required this.success,
    this.message,
    this.user,
  });

  factory AuthResult.ok(User? user) => AuthResult(success: true, user: user);

  factory AuthResult.fail(String message) =>
      AuthResult(success: false, message: message);
}
