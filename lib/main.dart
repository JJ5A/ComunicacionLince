import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'firebase_options.dart';
export 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAppCheck.instance.activate(
    providerAndroid: const AndroidDebugProvider(),
    providerApple: const AppleAppAttestWithDeviceCheckFallbackProvider(),
  );
  await _initializeSupabase();
  runApp(const ProviderScope(child: ComunicacionLinceApp()));
}

Future<void> _initializeSupabase() async {
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    if (kDebugMode) {
      debugPrint('Supabase env vars not set. Skipping Supabase.initialize.');
    }
    return;
  }
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
}
