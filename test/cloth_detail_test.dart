import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pakeaja/core/providers/service_providers.dart';
import 'package:pakeaja/data/models/cloth_model.dart';
import 'package:pakeaja/data/repositories/cloth_repository.dart';
import 'package:pakeaja/features/auth/providers/auth_provider.dart';
import 'package:pakeaja/features/wardrobe/presentation/screens/cloth_detail_screen.dart';
import 'package:pakeaja/features/wardrobe/presentation/screens/wardrobe_screen.dart';
import 'package:pakeaja/features/wardrobe/providers/wardrobe_provider.dart';

class _FakeUser implements User {
  @override
  String get uid => 'user_test_1';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeClothRepository implements ClothRepository {
  final ClothModel? singleCloth;
  final bool hangStream;

  _FakeClothRepository({this.singleCloth, this.hangStream = false});

  @override
  Stream<ClothModel?> watchCloth(String uid, String clothId) {
    if (hangStream) {
      return const Stream<ClothModel?>.empty();
    }
    return Stream.value(singleCloth);
  }

  @override
  Stream<List<ClothModel>> watchClothes(String uid) =>
      Stream.value(singleCloth != null ? [singleCloth!] : const []);

  @override
  Stream<List<ClothModel>> watchClothesPaged(
    String uid, {
    int limit = 30,
    DocumentSnapshot<Object?>? startAfter,
  }) =>
      const Stream.empty();

  @override
  Future<ClothModel> addCloth({
    required String uid,
    required ClothModel cloth,
  }) async =>
      cloth;

  @override
  Future<void> updateCloth({
    required String uid,
    required String clothId,
    required Map<String, dynamic> data,
  }) async {}

  @override
  Future<void> deleteCloth({
    required String uid,
    required String clothId,
  }) async {}

  @override
  Future<void> deleteClothImage(String? imageUrl) async {}

  @override
  Future<void> updateWearStats({
    required String uid,
    required String clothId,
    required DateTime wornAt,
  }) async {}
}

void main() {
  final sampleCloth = ClothModel(
    id: 'cloth_123',
    name: 'Kemeja Linen Putih',
    category: ClothCategory.top,
    color: ClothColor.white,
    styles: const [ClothStyle.semiFormal, ClothStyle.casual],
    weather: ClothWeather.hot,
    imageUrl: '',
    wearCount: 4,
    lastWornAt: DateTime(2026, 10, 1), // >7 hari lalu (menguji DateFormatter)
    createdAt: DateTime(2026, 9, 15),
  );

  testWidgets(
      'ClothDetailScreen displays cached cloth immediately even if single-doc stream hangs and without id_ID crash',
      (tester) async {
    final user = _FakeUser();
    final repo = _FakeClothRepository(hangStream: true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(user)),
          clothRepositoryProvider.overrideWithValue(repo),
          clothesListProvider.overrideWith((ref) => Stream.value([sampleCloth])),
        ],
        child: const MaterialApp(
          home: ClothDetailScreen(clothId: 'cloth_123'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Detail Pakaian'), findsOneWidget);
    expect(find.text('Kemeja Linen Putih'), findsOneWidget);
    expect(find.text('Atasan'), findsOneWidget);
    expect(find.text('Putih'), findsOneWidget);
    expect(find.text('Semi-formal, Casual'), findsOneWidget);
    expect(find.text('Panas'), findsOneWidget);
    expect(find.text('4x'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ClothDetailScreen shows error state when cloth does not exist',
      (tester) async {
    final user = _FakeUser();
    final repo = _FakeClothRepository(singleCloth: null);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(user)),
          clothRepositoryProvider.overrideWithValue(repo),
          clothesListProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        child: const MaterialApp(
          home: ClothDetailScreen(clothId: 'missing_id'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Pakaian tidak ditemukan.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tapping cloth card on WardrobeScreen navigates to ClothDetailScreen',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final user = _FakeUser();
    final repo = _FakeClothRepository(singleCloth: sampleCloth);

    final router = GoRouter(
      initialLocation: '/wardrobe',
      routes: [
        GoRoute(
          path: '/wardrobe',
          builder: (_, __) => const WardrobeScreen(),
        ),
        GoRoute(
          path: '/cloth/:id',
          builder: (_, state) =>
              ClothDetailScreen(clothId: state.pathParameters['id']!),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(user)),
          clothRepositoryProvider.overrideWithValue(repo),
          clothesListProvider.overrideWith((ref) => Stream.value([sampleCloth])),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pumpAndSettle();

    final cardTitle = find.text('Kemeja Linen Putih');
    await tester.ensureVisible(cardTitle);
    await tester.tap(cardTitle);
    await tester.pumpAndSettle();

    expect(find.text('Detail Pakaian'), findsOneWidget);
    expect(find.text('Kemeja Linen Putih'), findsOneWidget);
    expect(find.text('Semi-formal, Casual'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
