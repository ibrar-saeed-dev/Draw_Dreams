import 'package:supabase_flutter/supabase_flutter.dart';

class Template {
  final String id;
  final String title;
  final String categoryId;
  final String imageUrl;
  final bool isPremium;
  final String? difficulty; // 'easy', 'medium', 'hard'
  final String? colorType; // 'bw', 'colorful'

  Template({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.imageUrl,
    required this.isPremium,
    this.difficulty,
    this.colorType,
  });

  factory Template.fromJson(Map<String, dynamic> json) {
    String url = json['image_url'] as String? ?? '';
    if (url.isNotEmpty &&
        !url.startsWith('http://') &&
        !url.startsWith('https://') &&
        !url.startsWith('assets/') &&
        !url.startsWith('file:') &&
        !url.startsWith('/')) {
      try {
        url = Supabase.instance.client.storage.from('templates').getPublicUrl(url);
      } catch (_) {}
    }

    return Template(
      id: json['id'] as String,
      title: json['title'] as String,
      categoryId: json['category_id'] as String,
      imageUrl: url,
      isPremium: json['is_premium'] as bool? ?? false,
      difficulty: json['difficulty'] as String?,
      colorType: json['color_type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category_id': categoryId,
      'image_url': imageUrl,
      'is_premium': isPremium,
      'difficulty': difficulty,
      'color_type': colorType,
    };
  }
}
