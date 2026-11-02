import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pakeaja/data/models/cloth_model.dart';
import 'package:pakeaja/data/models/outfit_model.dart';
import 'package:pakeaja/features/outfits/presentation/screens/favorites_history_screen.dart';
import 'package:pakeaja/features/outfits/providers/outfit_provider.dart';
import 'package:pakeaja/features/wardrobe/providers/wardrobe_provider.dart';

void main() {
  testWidgets('FavoritesHistoryScreen renders correctly when empty', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          favoriteOutfitsProvider.overrideWith((ref) => Stream.value([])),
          outfitHistoryProvider.overrideWith((ref) => Stream.value([])),
          clothesListProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: const MaterialApp(
          home: FavoritesHistoryScreen(),
        ),
      ),
    );

    await tester.pump();
    expect(find.text('Outfit Favorit'), findsOneWidget);
    expect(find.text('KOLEKSI TERKURASI'), findsOneWidget);
    expect(find.text('Rencana Minggu Ini'), findsOneWidget);
    expect(find.text('Lookbook Pilihan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('FavoritesHistoryScreen handles error state gracefully without red screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          favoriteOutfitsProvider.overrideWith((ref) => Stream.error(Exception('Terjadi kesalahan. Silakan coba lagi.'))),
          outfitHistoryProvider.overrideWith((ref) => Stream.error(Exception('Terjadi kesalahan. Silakan coba lagi.'))),
          clothesListProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: const MaterialApp(
          home: FavoritesHistoryScreen(),
        ),
      ),
    );

    await tester.pump();
    expect(find.text('Outfit Favorit'), findsOneWidget);
    expect(find.text('Rencana Minggu Ini'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('FavoritesHistoryScreen renders lookbook cards when data is available', (tester) async {
    final mockOutfit = OutfitModel(
      id: 'outfit_1',
      itemIds: ['cloth_1'],
      occasion: 'Kuliah Pagi',
      isFavorite: true,
      wornDates: [DateTime.now()],
      createdAt: DateTime.now(),
    );

    final mockCloth = ClothModel(
      id: 'cloth_1',
      name: 'Kemeja Katun Garis',
      category: ClothCategory.top,
      color: 'cream',
      styles: const [ClothStyle.casual],
      weather: ClothWeather.cool,
      imageUrl: '',
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          favoriteOutfitsProvider.overrideWith((ref) => Stream.value([mockOutfit])),
          outfitHistoryProvider.overrideWith((ref) => Stream.value([mockOutfit])),
          clothesListProvider.overrideWith((ref) => Stream.value([mockCloth])),
        ],
        child: const MaterialApp(
          home: FavoritesHistoryScreen(),
        ),
      ),
    );

    await tester.pump();
    expect(find.text('Outfit Favorit'), findsOneWidget);
    expect(find.text('Kuliah Pagi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
