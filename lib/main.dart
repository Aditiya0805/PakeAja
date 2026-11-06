import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/constants/app_constants.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  // Inisialisasi Firebase
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint('Firebase init error: $e');
    // Tangani error duplicate-app saat hot restart atau konfigurasi web belum siap
    if (!e.toString().contains('duplicate-app') && !kIsWeb) {
      rethrow;
    }
  }

  // Set status bar & navigation bar style (hanya di platform non-web)
  if (!kIsWeb) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  runApp(
    const ProviderScope(
      child: PakeAjaApp(),
    ),
  );
}

class PakeAjaApp extends ConsumerWidget {
  const PakeAjaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
