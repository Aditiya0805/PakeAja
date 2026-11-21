import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/constants/app_constants.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Tangani uncaught error global agar tidak menyebabkan layar putih beku di device mana pun
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('PlatformDispatcher error: $error');
    return true; // Mencegah crash fatal pada engine web
  };

  // 2. Load .env secara aman (fallback otomatis tersedia jika hosting/web memblokir file .env)
  try {
    await dotenv.load();
  } catch (e) {
    debugPrint('dotenv.load info: Menggunakan konfigurasi environment bawaan ($e)');
  }

  // 3. Inisialisasi locale bahasa Indonesia secara aman
  try {
    await initializeDateFormatting('id_ID', null);
  } catch (e) {
    debugPrint('initializeDateFormatting info: $e');
  }

  // 4. Inisialisasi Firebase secara aman lintas platform dengan timeout agar tidak pernah nge-stuck
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(
        const Duration(seconds: 4),
        onTimeout: () {
          debugPrint('Firebase init timeout (melanjutkan render UI agar tidak stuck)');
          if (Firebase.apps.isNotEmpty) {
            return Firebase.app();
          }
          throw TimeoutException('Firebase inisialisasi terlalu lama.');
        },
      );
    }
  } catch (e) {
    debugPrint('Firebase init info: $e');
  }

  // 5. Set status bar & navigation bar style (hanya di platform non-web)
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
