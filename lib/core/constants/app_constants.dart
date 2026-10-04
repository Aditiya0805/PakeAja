class AppConstants {
  // App Info
  static const String appName = 'PakeAja';
  static const String appTagline = 'Bingung mau pake apa? PakeAja.';

  // Validation
  static const int minPasswordLength = 6;
  static const int maxClothNameLength = 50;

  // Image
  static const int maxImageSize = 1048576; // 1 MB
  static const int imageQuality = 85;
  static const int thumbnailQuality = 60;
  static const int thumbnailSize = 200;

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String clothesSubcollection = 'clothes';
  static const String outfitsSubcollection = 'outfits';

  // Firebase Storage
  static const String clothesStoragePath = 'clothes';

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration imageUploadTimeout = Duration(seconds: 60);

  // Occasions
  static const List<String> occasions = [
    'Kuliah',
    'Santai',
    'Formal',
    'Semi Formal',
    'Olahraga',
    'Organisasi',
    'Lainnya',
  ];

  // Cloth Categories
  static const Map<String, String> clothCategories = {
    'top': 'Atasan',
    'bottom': 'Bawahan',
    'onepiece': 'One-piece',
    'outer': 'Outer',
    'shoes': 'Sepatu',
    'accessory': 'Aksesori',
  };

  // Styles
  static const Map<String, String> styles = {
    'casual': 'Casual',
    'formal': 'Formal',
    'semi-formal': 'Semi-formal',
    'sport': 'Sport',
  };

  // Weathers
  static const Map<String, String> weathers = {
    'hot': 'Panas',
    'cool': 'Sejuk',
    'rain': 'Hujan',
  };

  // Colors
  static const Map<String, String> clothColors = {
    'black': 'Hitam',
    'white': 'Putih',
    'gray': 'Abu-abu',
    'navy': 'Navy',
    'blue': 'Biru',
    'red': 'Merah',
    'green': 'Hijau',
    'brown': 'Coklat',
    'cream': 'Cream',
    'other': 'Lainnya',
  };

  // Occasion to Style Mapping
  static const Map<String, List<String>> occasionStyles = {
    'Kuliah': ['casual', 'semi-formal'],
    'Santai': ['casual'],
    'Formal': ['formal', 'semi-formal'],
    'Semi Formal': ['semi-formal', 'casual'],
    'Olahraga': ['sport'],
    'Organisasi': ['formal', 'semi-formal'],
    'Lainnya': ['casual', 'semi-formal', 'formal'],
  };

  // Minimum requirements for recommendation
  static const int minTopsRequired = 1;
  static const int minBottomsRequired = 1;
  static const int minShoesRequired = 1;
}
