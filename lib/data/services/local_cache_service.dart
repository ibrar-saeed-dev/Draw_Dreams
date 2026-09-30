import 'dart:convert';
import 'package:flutter/foundation.dart' hide Category;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/category.dart';
import '../models/template.dart';
import '../models/lesson.dart';
import '../repositories/template_repository.dart';

class LocalCacheService {
  static const String categoriesBoxName = 'categories_cache';
  static const String templatesBoxName = 'templates_cache';
  static const String lessonsBoxName = 'lessons_cache';
  static const String metadataBoxName = 'app_metadata_cache';
  static const String lastSyncKey = 'last_metadata_sync_timestamp';

  static Future<void> init() async {
    await Hive.initFlutter();
    final boxes = await Future.wait([
      Hive.openBox<String>(categoriesBoxName),
      Hive.openBox<String>(templatesBoxName),
      Hive.openBox<String>(lessonsBoxName),
      Hive.openBox(metadataBoxName),
    ]);
    // Clear stale development cache to reflect freshly added mock models
    await boxes[0].clear();
    await boxes[1].clear();
    await boxes[2].clear();
  }

  /// Check if sync is needed (never synced or > 24 hours)
  static bool isSyncNeeded() {
    final box = Hive.box(metadataBoxName);
    final int? lastSync = box.get(lastSyncKey);
    if (lastSync == null) return true;
    final now = DateTime.now().millisecondsSinceEpoch;
    return (now - lastSync) > const Duration(hours: 24).inMilliseconds;
  }

  /// Sync metadata from Supabase to local Hive database
  static Future<bool> syncMetadata(SupabaseClient? client, TemplateRepository templateRepo) async {
    try {
      if (client != null) {
        // Fetch Categories
        final catResponse = await client.from('categories').select().order('sort_order', ascending: true);
        final catList = (catResponse as List).map((json) => Category.fromJson(json as Map<String, dynamic>)).toList();
        final resolvedCategories = templateRepo.resolveAllCategories(catList);

        // Fetch Templates
        final tempResponse = await client.from('templates').select();
        final List<Template> tempTemplates = (tempResponse as List).map((json) => Template.fromJson(json as Map<String, dynamic>)).toList();

        // Fetch Lessons
        final lessonResponse = await client.from('lessons').select().order('created_at', ascending: true);
        final lessonList = (lessonResponse as List).map((json) => Lesson.fromJson(json as Map<String, dynamic>)).toList();

        await saveCategories(resolvedCategories);
        await saveTemplates(tempTemplates);
        await saveLessons(lessonList);

        final metaBox = Hive.box(metadataBoxName);
        await metaBox.put(lastSyncKey, DateTime.now().millisecondsSinceEpoch);
        return true;
      } else {
        // Offline / No client: seed/update mock data
        final mockCategories = templateRepo.getMockCategories();
        final mockTemplates = templateRepo.getMockTemplates();
        await saveCategories(mockCategories);
        await saveTemplates(mockTemplates);
        return true;
      }
    } catch (e) {
      debugPrint("Error syncing metadata to local database: $e");
      // If we have cached data, sync failed non-fatally
      final catBox = Hive.box<String>(categoriesBoxName);
      if (catBox.isNotEmpty) return true;
      return false;
    }
  }

  static Future<void> saveCategories(List<Category> categories) async {
    final box = Hive.box<String>(categoriesBoxName);
    await box.clear();
    for (var cat in categories) {
      await box.put(cat.id, jsonEncode(cat.toJson()));
    }
  }

  static List<Category> getCachedCategories() {
    final box = Hive.box<String>(categoriesBoxName);
    return box.values.map((raw) => Category.fromJson(jsonDecode(raw))).toList();
  }

  static Future<void> saveTemplates(List<Template> templates) async {
    final box = Hive.box<String>(templatesBoxName);
    await box.clear();
    for (var t in templates) {
      await box.put(t.id, jsonEncode(t.toJson()));
    }
  }

  static List<Template> getCachedTemplates() {
    final box = Hive.box<String>(templatesBoxName);
    return box.values.map((raw) => Template.fromJson(jsonDecode(raw))).toList();
  }

  static Future<void> saveLessons(List<Lesson> lessons) async {
    final box = Hive.box<String>(lessonsBoxName);
    await box.clear();
    for (var l in lessons) {
      await box.put(l.id, jsonEncode(l.toJson()));
    }
  }

  static List<Lesson> getCachedLessons() {
    final box = Hive.box<String>(lessonsBoxName);
    return box.values.map((raw) => Lesson.fromJson(jsonDecode(raw))).toList();
  }
}
