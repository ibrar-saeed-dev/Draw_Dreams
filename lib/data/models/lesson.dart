class Lesson {
  final String id;
  final String title;
  final String thumbnailUrl;
  final String difficulty; // 'easy', 'medium', 'hard'
  final String? colorType; // 'bw', 'colorful'
  final int stepCount;
  final int completionCount;
  final bool isPremium;
  final String? categoryId;

  Lesson({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.difficulty,
    this.colorType,
    required this.stepCount,
    required this.completionCount,
    required this.isPremium,
    this.categoryId,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] as String,
      title: json['title'] as String,
      thumbnailUrl: json['thumbnail_url'] as String,
      difficulty: (json['difficulty'] as String? ?? 'easy').toLowerCase(),
      colorType: json['color_type'] as String?,
      stepCount: json['step_count'] as int? ?? 0,
      completionCount: json['completion_count'] as int? ?? 0,
      isPremium: json['is_premium'] as bool? ?? false,
      categoryId: json['category_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'thumbnail_url': thumbnailUrl,
      'difficulty': difficulty,
      'color_type': colorType,
      'step_count': stepCount,
      'completion_count': completionCount,
      'is_premium': isPremium,
      'category_id': categoryId,
    };
  }
}
