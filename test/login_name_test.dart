import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pakeaja/core/providers/service_providers.dart';
import 'package:pakeaja/core/utils/auth_result.dart';
import 'package:pakeaja/data/models/user_model.dart';
import 'package:pakeaja/data/services/auth_service.dart';
import 'package:pakeaja/features/auth/presentation/screens/login_screen.dart';
import 'package:pakeaja/features/auth/providers/auth_provider.dart';
import 'package:pakeaja/features/home/presentation/screens/home_screen.dart';
import 'package:pakeaja/features/outfits/providers/outfit_provider.dart';
import 'package:pakeaja/features/profile/presentation/screens/profile_screen.dart';
import 'package:pakeaja/features/wardrobe/providers/wardrobe_provider.dart';

class _FakeAuthService implements AuthService {
  String? lastLoginEmail;
  String? lastLoginName;
  String? lastUpdatedName;

  @override
  Stream<User?> get authStateChanges => Stream.value(null);

  @override
  User? get currentUser => null;

  @override
  String? get currentUid => null;

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
    String? name,
  }) async {
    lastLoginEmail = email;
    lastLoginName = name;
    return AuthResult.ok(null);
  }

  @override
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async =>
      AuthResult.ok(null);

  @override
  Future<AuthResult> signInWithGoogle({String? name}) async {
    lastLoginName = name;
    return AuthResult.ok(null);
  }

  @override
  Future<AuthResult> updateProfile({String? name, String? photoUrl}) async {
    lastUpdatedName = name;
    return AuthResult.ok(null);
  }

  @override
  Future<AuthResult> sendPasswordResetEmail(String email) async =>
      AuthResult.ok(null);

  @override
  Future<AuthResult> logout() async => AuthResult.ok(null);

  @override
  Future<AuthResult> deleteAccount(String password) async =>
      AuthResult.ok(null);
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  testWidgets('User can input name on LoginScreen and it displays on HomeScreen',
      (tester) async {
    final fakeAuth = _FakeAuthService();

    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(fakeAuth),
          authStateProvider.overrideWith((ref) => Stream.value(null)),
          userDataProvider.overrideWith((ref) => Stream.value(null)),
          clothesListProvider.overrideWith((ref) => Stream.value([])),
          outfitHistoryProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Nama field is rendered on LoginScreen
    final nameField = find.widgetWithText(TextFormField, 'Nama');
    final emailField = find.widgetWithText(TextFormField, 'Email');
    final passwordField = find.widgetWithText(TextFormField, 'Password');

    expect(nameField, findsOneWidget);
    expect(emailField, findsOneWidget);
    expect(passwordField, findsOneWidget);

    await tester.enterText(nameField, 'Aditiya Pratama');
    await tester.enterText(emailField, 'adit@test.com');
    await tester.enterText(passwordField, '123456');

    final loginBtn = find.widgetWithText(FilledButton, 'Masuk');
    await tester.ensureVisible(loginBtn);
    await tester.tap(loginBtn);
    await tester.pumpAndSettle();

    expect(fakeAuth.lastLoginEmail, 'adit@test.com');
    expect(fakeAuth.lastLoginName, 'Aditiya Pratama');

    // HomeScreen should greet with the inputted name, NOT 'Sarah'
    expect(find.text('Halo, Aditiya!'), findsOneWidget);
    expect(find.text('Halo, Sarah!'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ProfileScreen displays and updates user name reactively',
      (tester) async {
    final fakeAuth = _FakeAuthService();
    final initialUser = UserModel(
      uid: 'uid_1',
      name: 'Aditiya Pratama',
      email: 'adit@test.com',
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(fakeAuth),
          authStateProvider.overrideWith((ref) => Stream.value(null)),
          userDataProvider.overrideWith((ref) => Stream.value(initialUser)),
          clothesListProvider.overrideWith((ref) => Stream.value([])),
          favoriteOutfitsProvider.overrideWith((ref) => Stream.value([])),
          outfitHistoryProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: const MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Aditiya Pratama'), findsOneWidget);

    // Tap Ubah Profil to edit name
    await tester.tap(find.text('Ubah Profil'));
    await tester.pumpAndSettle();

    final editField = find.widgetWithText(TextField, 'Nama Lengkap');
    expect(editField, findsOneWidget);
    await tester.enterText(editField, 'Budi Santoso');

    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(fakeAuth.lastUpdatedName, 'Budi Santoso');
    expect(find.text('Budi Santoso'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
