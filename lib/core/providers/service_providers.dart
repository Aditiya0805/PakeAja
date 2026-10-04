import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pakeaja/data/repositories/cloth_repository.dart';
import 'package:pakeaja/data/repositories/user_repository.dart';
import 'package:pakeaja/data/services/auth_service.dart';
import 'package:pakeaja/data/services/image_service.dart';
import 'package:pakeaja/data/services/recommendation_service.dart';

// ==================== SERVICE PROVIDERS ====================
/// Semua service/repository di-root di sini agar tidak terjadi circular import.
final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final userRepositoryProvider = Provider<UserRepository>((ref) => UserRepository());
final clothRepositoryProvider = Provider<ClothRepository>((ref) => ClothRepository());
final imageServiceProvider = Provider<ImageService>((ref) => ImageService());
final recommendationServiceProvider =
    Provider<RecommendationService>((ref) => RecommendationService());
