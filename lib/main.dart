import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/app.dart';
import 'data/repositories/template_repository.dart';
import 'data/services/local_cache_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await LocalCacheService.init();

  SupabaseClient? client;
  try {
    const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
    const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
    
    if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
      await Supabase.initialize(
        url: supabaseUrl,
        publishableKey: supabaseAnonKey,
      );
      client = Supabase.instance.client;
      debugPrint("Supabase initialized successfully.");
    }
  } catch (e) {
    debugPrint("Failed to initialize Supabase: $e");
  }

  // Pre-seed and sync metadata locally on launch
  final tempRepo = TemplateRepository(client);
  await LocalCacheService.syncMetadata(client, tempRepo);

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
