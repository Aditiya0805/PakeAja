import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pakeaja/features/auth/presentation/screens/login_screen.dart';
import 'package:pakeaja/features/auth/presentation/screens/register_screen.dart';
import 'package:pakeaja/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:pakeaja/features/auth/providers/auth_provider.dart';
import 'package:pakeaja/features/main/presentation/screens/main_screen.dart';
import 'package:pakeaja/features/wardrobe/presentation/screens/cloth_detail_screen.dart';
import 'package:pakeaja/features/wardrobe/presentation/screens/add_cloth_screen.dart';
import 'package:pakeaja/features/wardrobe/presentation/screens/edit_cloth_screen.dart';
import 'package:pakeaja/features/recommendation/presentation/screens/recommendation_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final user = ref.read(authStateProvider).value;
      final isLoggedIn = user != null;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password';

      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }
      if (isLoggedIn && isAuthRoute) {
        return '/';
      }
      return null;
    },
    routes: [
      // Auth
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Main (bottom nav)
      GoRoute(
        path: '/',
        name: 'main',
        builder: (context, state) => const MainScreen(),
      ),

      // Wardrobe
      GoRoute(
        path: '/cloth/add',
        name: 'add-cloth',
        builder: (context, state) => const AddClothScreen(),
      ),
      GoRoute(
        path: '/cloth/:id',
        name: 'cloth-detail',
        builder: (context, state) =>
            ClothDetailScreen(clothId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/cloth/:id/edit',
        name: 'edit-cloth',
        builder: (context, state) =>
            EditClothScreen(clothId: state.pathParameters['id']!),
      ),

      // Recommendation
      GoRoute(
        path: '/recommendation',
        name: 'recommendation',
        builder: (context, state) {
          final occasion = state.uri.queryParameters['occasion'] ?? 'Kuliah';
          return RecommendationScreen(occasion: occasion);
        },
      ),
    ],
    errorBuilder: (context, state) => const Scaffold(
      body: Center(child: Text('Halaman tidak ditemukan')),
    ),
  );

  return router;
});
