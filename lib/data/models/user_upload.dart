import 'template.dart';

class UserUpload {
  final String id;
  final String imageUrl;
  final String? outlineUrl;
  final DateTime createdAt;

  UserUpload({
    required this.id,
    required this.imageUrl,
    this.outlineUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'image_url': imageUrl,
        'outline_url': outlineUrl,
        'created_at': createdAt.toIso8601String(),
      };

  factory UserUpload.fromJson(Map<String, dynamic> json) => UserUpload(
        id: json['id'] as String,
        imageUrl: json['image_url'] as String,
        outlineUrl: json['outline_url'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
      );

  Template toTemplate() {
    final displayUrl = (outlineUrl != null && outlineUrl!.isNotEmpty)
        ? outlineUrl!
        : imageUrl;
    return Template(
      id: id,
      title: 'My Upload',
      imageUrl: displayUrl,
      categoryId: 'my_uploads',
      isPremium: false,
    );
  }
}
