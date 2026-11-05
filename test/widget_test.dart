import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pakeaja/data/models/cloth_model.dart';
import 'package:pakeaja/data/models/outfit_model.dart';
import 'package:pakeaja/features/outfits/presentation/screens/favorites_history_screen.dart';
import 'package:pakeaja/features/outfits/providers/outfit_provider.dart';
import 'package:pakeaja/features/wardrobe/providers/wardrobe_provider.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

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
    expect(find.text('0/7 Outfit Terjadwal'), findsOneWidget);
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

  testWidgets('FavoritesHistoryScreen renders lookbook cards and reflects real-time scheduled count', (tester) async {
    final today = DateTime.now();
    final mockOutfit = OutfitModel(
      id: 'outfit_1',
      itemIds: ['cloth_1'],
      occasion: 'Kuliah Pagi',
      isFavorite: true,
      wornDates: [today],
      createdAt: today,
    );

    final mockCloth = ClothModel(
      id: 'cloth_1',
      name: 'Kemeja Katun Garis',
      category: ClothCategory.top,
      color: 'cream',
      styles: const [ClothStyle.casual],
      weather: ClothWeather.cool,
      imageUrl: '',
      createdAt: today,
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
    // Real-time scheduled count: 1/7
    expect(find.text('1/7 Outfit Terjadwal'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Tap on the day to open the agenda bottom sheet
    await tester.tap(find.text('${today.day}').first);
    await tester.pumpAndSettle();

    // Verify bottom sheet opened with scheduled outfit details
    expect(find.text('Kuliah Pagi'), findsWidgets);
    expect(find.text('Ganti Outfit'), findsOneWidget);
  });
}
