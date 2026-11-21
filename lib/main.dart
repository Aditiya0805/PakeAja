import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  // 1. Flutter binding wajib dijalankan pertama kali
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Tangani uncaught error global agar tidak menyebabkan layar putih beku di device mana pun
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('PlatformDispatcher error: $error');
    return true; // Mencegah crash fatal pada engine web
  };

  // 3. Load .env secara aman (jika file .env tidak ditemukan di web, proses tetap lanjut)
  try {
    await dotenv.load();
  } catch (e) {
    debugPrint('dotenv.load info: Menggunakan konfigurasi environment bawaan ($e)');
  }

  // 4. Inisialisasi locale bahasa Indonesia secara aman
  try {
    await initializeDateFormatting('id_ID', null);
  } catch (e) {
    debugPrint('initializeDateFormatting info: $e');
  }

  // 5. Inisialisasi Firebase secara langsung lintas platform (tidak diskip jika dotenv gagal)
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    // Khusus untuk platform Web (kIsWeb)
    if (kIsWeb) {
      // a. Atur Firestore settings untuk kestabilan koneksi WebKit iOS
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false,
        webExperimentalForceLongPolling: true,
      );

      // b. Atur Persistence FirebaseAuth dengan fallback aman jika WebKit memblokir local storage
      try {
        await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
      } catch (e) {
        debugPrint('FirebaseAuth setPersistence LOCAL fallback to SESSION: $e');
        try {
          await FirebaseAuth.instance.setPersistence(Persistence.SESSION);
        } catch (_) {
          try {
            await FirebaseAuth.instance.setPersistence(Persistence.NONE);
          } catch (_) {}
        }
      }
    }
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  // 6. Set status bar & navigation bar style (hanya di platform non-web)
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
