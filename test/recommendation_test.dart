import 'package:flutter_test/flutter_test.dart';
import 'package:pakeaja/data/models/cloth_model.dart';
import 'package:pakeaja/data/services/recommendation_service.dart';
import 'package:pakeaja/features/wardrobe/providers/wardrobe_provider.dart';

void main() {
  late RecommendationService service;

  setUp(() {
    service = RecommendationService();
  });

  test('Recommends Semi-Formal Top paired with Semi-Formal Bottom for Semi Formal occasion', () {
    final clothes = [
      // Tops
      ClothModel(
        id: 'top_semi',
        name: 'Kemeja Katun Oxford',
        category: ClothCategory.top,
        color: 'white',
        styles: const [ClothStyle.semiFormal],
        weather: ClothWeather.cool,
        imageUrl: '',
        createdAt: DateTime.now(),
      ),
      ClothModel(
        id: 'top_casual',
        name: 'Kaos Oblong Santai',
        category: ClothCategory.top,
        color: 'black',
        styles: const [ClothStyle.casual],
        weather: ClothWeather.cool,
        imageUrl: '',
        createdAt: DateTime.now(),
      ),
      ClothModel(
        id: 'top_sport',
        name: 'Jersey Futsal',
        category: ClothCategory.top,
        color: 'red',
        styles: const [ClothStyle.sport],
        weather: ClothWeather.cool,
        imageUrl: '',
        createdAt: DateTime.now(),
      ),

      // Bottoms
      ClothModel(
        id: 'bottom_semi',
        name: 'Celana Chino Slim',
        category: ClothCategory.bottom,
        color: 'cream',
        styles: const [ClothStyle.semiFormal],
        weather: ClothWeather.cool,
        imageUrl: '',
        createdAt: DateTime.now(),
      ),
      ClothModel(
        id: 'bottom_casual',
        name: 'Ripped Jeans Sobek',
        category: ClothCategory.bottom,
        color: 'blue',
        styles: const [ClothStyle.casual],
        weather: ClothWeather.cool,
        imageUrl: '',
        createdAt: DateTime.now(),
      ),
      ClothModel(
        id: 'bottom_sport',
        name: 'Celana Training Parasut',
        category: ClothCategory.bottom,
        color: 'black',
        styles: const [ClothStyle.sport],
        weather: ClothWeather.cool,
        imageUrl: '',
        createdAt: DateTime.now(),
      ),

      // Shoes
      ClothModel(
        id: 'shoe_semi',
        name: 'Leather Penny Loafers',
        category: ClothCategory.shoes,
        color: 'brown',
        styles: const [ClothStyle.semiFormal],
        weather: ClothWeather.cool,
        imageUrl: '',
        createdAt: DateTime.now(),
      ),
      ClothModel(
        id: 'shoe_sport',
        name: 'Sepatu Running Gel',
        category: ClothCategory.shoes,
        color: 'blue',
        styles: const [ClothStyle.sport],
        weather: ClothWeather.cool,
        imageUrl: '',
        createdAt: DateTime.now(),
      ),
    ];

    final rec = service.recommend(
      clothes: clothes,
      occasion: 'Semi Formal',
    );

    // Verifikasi Atasan Semi Formal dipasangkan dengan Bawahan Semi Formal!
    expect(rec.itemIds.contains('top_semi'), isTrue,
        reason: 'Atasan harus kemeja semi formal');
    expect(rec.itemIds.contains('bottom_semi'), isTrue,
        reason: 'Bawahan harus celana chino semi formal');
    expect(rec.itemIds.contains('shoe_semi'), isTrue,
        reason: 'Sepatu harus loafers semi formal');
    expect(rec.score, greaterThanOrEqualTo(90.0));
  });

  test('Recommends Formal Top paired with Formal Bottom for Formal occasion', () {
    final clothes = [
      ClothModel(
        id: 'top_formal',
        name: 'Kemeja Batik Tulis Sutra',
        category: ClothCategory.top,
        color: 'brown',
        styles: const [ClothStyle.formal],
        weather: ClothWeather.cool,
        imageUrl: '',
        createdAt: DateTime.now(),
      ),
      ClothModel(
        id: 'top_casual',
        name: 'Kaos Polos Putih',
        category: ClothCategory.top,
        color: 'white',
        styles: const [ClothStyle.casual],
        weather: ClothWeather.cool,
        imageUrl: '',
        createdAt: DateTime.now(),
      ),
      ClothModel(
        id: 'bottom_formal',
        name: 'Celana Bahan Wol Formal',
        category: ClothCategory.bottom,
        color: 'black',
        styles: const [ClothStyle.formal],
        weather: ClothWeather.cool,
        imageUrl: '',
        createdAt: DateTime.now(),
      ),
      ClothModel(
        id: 'bottom_casual',
        name: 'Celana Pendek Pantai',
        category: ClothCategory.bottom,
        color: 'blue',
        styles: const [ClothStyle.casual],
        weather: ClothWeather.cool,
        imageUrl: '',
        createdAt: DateTime.now(),
      ),
      ClothModel(
        id: 'shoe_formal',
        name: 'Sepatu Pantofel Oxford Kulit',
        category: ClothCategory.shoes,
        color: 'black',
        styles: const [ClothStyle.formal],
        weather: ClothWeather.cool,
        imageUrl: '',
        createdAt: DateTime.now(),
      ),
    ];

    final rec = service.recommend(
      clothes: clothes,
      occasion: 'Formal',
    );

    expect(rec.itemIds.contains('top_formal'), isTrue);
    expect(rec.itemIds.contains('bottom_formal'), isTrue);
    expect(rec.itemIds.contains('shoe_formal'), isTrue);
  });

  test('Recommends Sport Top paired with Sport Bottom for Olahraga occasion', () {
    final clothes = [
      ClothModel(
        id: 'top_sport',
        name: 'Baju Jersey Dryfit',
        category: ClothCategory.top,
        color: 'black',
        styles: const [ClothStyle.sport],
        weather: ClothWeather.cool,
        imageUrl: '',
        createdAt: DateTime.now(),
      ),
      ClothModel(
        id: 'top_formal',
        name: 'Kemeja Putih Lengan Panjang',
        category: ClothCategory.top,
        color: 'white',
        styles: const [ClothStyle.formal],
        weather: ClothWeather.cool,
        imageUrl: '',
        createdAt: DateTime.now(),
      ),
      ClothModel(
        id: 'bottom_sport',
        name: 'Celana Training Olahraga',
        category: ClothCategory.bottom,
        color: 'black',
        styles: const [ClothStyle.sport],
        weather: ClothWeather.cool,
        imageUrl: '',
        createdAt: DateTime.now(),
      ),
      ClothModel(
        id: 'bottom_formal',
        name: 'Celana Bahan Hitam',
        category: ClothCategory.bottom,
        color: 'black',
        styles: const [ClothStyle.formal],
        weather: ClothWeather.cool,
        imageUrl: '',
        createdAt: DateTime.now(),
      ),
      ClothModel(
        id: 'shoe_sport',
        name: 'Sepatu Running Sport',
        category: ClothCategory.shoes,
        color: 'white',
        styles: const [ClothStyle.sport],
        weather: ClothWeather.cool,
        imageUrl: '',
        createdAt: DateTime.now(),
      ),
    ];

    final rec = service.recommend(
      clothes: clothes,
      occasion: 'Olahraga',
    );

    expect(rec.itemIds.contains('top_sport'), isTrue);
    expect(rec.itemIds.contains('bottom_sport'), isTrue);
    expect(rec.itemIds.contains('shoe_sport'), isTrue);
  });

  test('Auto-detects style from keywords (Chino, Batik, Jersey, Kaos)', () {
    final clothes = [
      ClothModel(
        id: 'top_batik',
        name: 'Kemeja Batik Solo', // Tanpa styles: [ClothStyle.formal]
        category: ClothCategory.top,
        color: 'brown',
        styles: const [ClothStyle.casual],
        weather: ClothWeather.cool,
        imageUrl: '',
        createdAt: DateTime.now(),
      ),
      ClothModel(
        id: 'top_kaos',
        name: 'Kaos Hitam Basic',
        category: ClothCategory.top,
        color: 'black',
        styles: const [ClothStyle.casual],
        weather: ClothWeather.cool,
        imageUrl: '',
        createdAt: DateTime.now(),
      ),
      ClothModel(
        id: 'bottom_bahan',
        name: 'Celana Bahan Hitam',
        category: ClothCategory.bottom,
        color: 'black',
        styles: const [ClothStyle.casual],
        weather: ClothWeather.cool,
        imageUrl: '',
        createdAt: DateTime.now(),
      ),
      ClothModel(
        id: 'bottom_jeans',
        name: 'Celana Jeans Denim',
        category: ClothCategory.bottom,
        color: 'blue',
        styles: const [ClothStyle.casual],
        weather: ClothWeather.cool,
        imageUrl: '',
        createdAt: DateTime.now(),
      ),
      ClothModel(
        id: 'shoe_pantofel',
        name: 'Sepatu Pantofel Hitam',
        category: ClothCategory.shoes,
        color: 'black',
        styles: const [ClothStyle.casual],
        weather: ClothWeather.cool,
        imageUrl: '',
        createdAt: DateTime.now(),
      ),
      ClothModel(
        id: 'shoe_sneakers',
        name: 'Sneakers Putih',
        category: ClothCategory.shoes,
        color: 'white',
        styles: const [ClothStyle.casual],
        weather: ClothWeather.cool,
        imageUrl: '',
        createdAt: DateTime.now(),
      ),
    ];

    // Formal: Harus otomatis memilih Batik + Celana Bahan + Pantofel
    final formalRec = service.recommend(clothes: clothes, occasion: 'Formal');
    expect(formalRec.itemIds.contains('top_batik'), isTrue);
    expect(formalRec.itemIds.contains('bottom_bahan'), isTrue);
    expect(formalRec.itemIds.contains('shoe_pantofel'), isTrue);

    // Santai: Harus otomatis memilih Kaos + Celana Jeans + Sneakers
    final casualRec = service.recommend(clothes: clothes, occasion: 'Santai');
    expect(casualRec.itemIds.contains('top_kaos'), isTrue);
    expect(casualRec.itemIds.contains('bottom_jeans'), isTrue);
    expect(casualRec.itemIds.contains('shoe_sneakers'), isTrue);
  });

  test('Casual clothes usable for Santai are rejected for Formal', () {
    final casualOnlyWardrobe = [
      ClothModel(
        id: 'top_santai',
        name: 'Kaos Oblong Santai',
        category: ClothCategory.top,
        color: 'white',
        styles: const [ClothStyle.casual],
        weather: ClothWeather.hot,
        imageUrl: '',
        createdAt: DateTime.now(),
      ),
      ClothModel(
        id: 'bottom_santai',
        name: 'Celana Pendek Pantai',
        category: ClothCategory.bottom,
        color: 'cream',
        styles: const [ClothStyle.casual],
        weather: ClothWeather.hot,
        imageUrl: '',
        createdAt: DateTime.now(),
      ),
      ClothModel(
        id: 'shoe_santai',
        name: 'Sandal Slop Santai',
        category: ClothCategory.shoes,
        color: 'black',
        styles: const [ClothStyle.casual],
        weather: ClothWeather.hot,
        imageUrl: '',
        createdAt: DateTime.now(),
      ),
    ];

    final santaiRec = service.recommend(
      clothes: casualOnlyWardrobe,
      occasion: 'Santai',
    );
    expect(santaiRec.itemIds, containsAll(['top_santai', 'bottom_santai', 'shoe_santai']));

    expect(
      () => service.recommend(
        clothes: casualOnlyWardrobe,
        occasion: 'Formal',
      ),
      throwsA(isA<NoSuitableOutfitException>()),
    );

    expect(
      () => service.recommend(
        clothes: casualOnlyWardrobe,
        occasion: 'Semi Formal',
      ),
      throwsA(isA<NoSuitableOutfitException>()),
    );
  });

  test('Strict Formal clothes are not forced into Santai or Olahraga', () {
    final formalOnlyWardrobe = [
      ClothModel(
        id: 'top_jas',
        name: 'Jas Formal Hitam',
        category: ClothCategory.top,
        color: 'black',
        styles: const [ClothStyle.formal],
        weather: ClothWeather.cool,
        imageUrl: '',
        createdAt: DateTime.now(),
      ),
      ClothModel(
        id: 'bottom_bahan',
        name: 'Celana Bahan Formal',
        category: ClothCategory.bottom,
        color: 'black',
        styles: const [ClothStyle.formal],
        weather: ClothWeather.cool,
        imageUrl: '',
        createdAt: DateTime.now(),
      ),
      ClothModel(
        id: 'shoe_pantofel',
        name: 'Sepatu Pantofel Kulit',
        category: ClothCategory.shoes,
        color: 'black',
        styles: const [ClothStyle.formal],
        weather: ClothWeather.cool,
        imageUrl: '',
        createdAt: DateTime.now(),
      ),
    ];

    final formalRec = service.recommend(
      clothes: formalOnlyWardrobe,
      occasion: 'Formal',
    );
    expect(formalRec.itemIds, containsAll(['top_jas', 'bottom_bahan', 'shoe_pantofel']));

    expect(
      () => service.recommend(
        clothes: formalOnlyWardrobe,
        occasion: 'Santai',
      ),
      throwsA(isA<NoSuitableOutfitException>()),
    );

    expect(
      () => service.recommend(
        clothes: formalOnlyWardrobe,
        occasion: 'Olahraga',
      ),
      throwsA(isA<NoSuitableOutfitException>()),
    );
  });

  test('Versatile Smart-Casual items fit Santai/Kuliah/Semi Formal without leaking into Formal', () {
    final smartCasualWardrobe = [
      ClothModel(
        id: 'top_polo',
        name: 'Polo Shirt Pique',
        category: ClothCategory.top,
        color: 'navy',
        styles: const [ClothStyle.semiFormal, ClothStyle.casual],
        weather: ClothWeather.cool,
        imageUrl: '',
        createdAt: DateTime.now(),
      ),
      ClothModel(
        id: 'bottom_chino',
        name: 'Celana Chino Beige',
        category: ClothCategory.bottom,
        color: 'cream',
        styles: const [ClothStyle.semiFormal, ClothStyle.casual],
        weather: ClothWeather.cool,
        imageUrl: '',
        createdAt: DateTime.now(),
      ),
      ClothModel(
        id: 'shoe_court',
        name: 'Court Sneakers Putih',
        category: ClothCategory.shoes,
        color: 'white',
        styles: const [ClothStyle.casual],
        weather: ClothWeather.cool,
        imageUrl: '',
        createdAt: DateTime.now(),
      ),
    ];

    expect(
      service.recommend(clothes: smartCasualWardrobe, occasion: 'Santai').itemIds,
      isNotEmpty,
    );
    expect(
      service.recommend(clothes: smartCasualWardrobe, occasion: 'Kuliah').itemIds,
      isNotEmpty,
    );
    expect(
      service.recommend(clothes: smartCasualWardrobe, occasion: 'Semi Formal').itemIds,
      isNotEmpty,
    );
    expect(
      () => service.recommend(clothes: smartCasualWardrobe, occasion: 'Formal'),
      throwsA(isA<NoSuitableOutfitException>()),
    );
  });

  test('suggestStylesForName and ClothFilter classify clothing accurately', () {
    expect(
      service.suggestStylesForName('Kemeja Pantai Santai'),
      equals(const [ClothStyle.casual]),
    );
    expect(
      service.suggestStylesForName('Kemeja Batik Formal'),
      equals(const [ClothStyle.formal, ClothStyle.semiFormal]),
    );
    expect(
      service.suggestStylesForName('Jersey Futsal Dryfit'),
      equals(const [ClothStyle.sport]),
    );

    final kaosSantai = ClothModel(
      id: 'c1',
      name: 'Kaos Polos Santai',
      category: ClothCategory.top,
      color: 'black',
      styles: const [ClothStyle.casual],
      weather: ClothWeather.hot,
      imageUrl: '',
      createdAt: DateTime.now(),
    );
    const formalFilter = ClothFilter(style: 'formal');
    const casualFilter = ClothFilter(style: 'casual');
    expect(casualFilter.matches(kaosSantai), isTrue);
    expect(formalFilter.matches(kaosSantai), isFalse);
  });
}

