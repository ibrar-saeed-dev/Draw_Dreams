import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CategoryStyle {
  final String name;
  final IconData icon;
  final Color backgroundColor;

  const CategoryStyle({
    required this.name,
    required this.icon,
    required this.backgroundColor,
  });
}

final Map<String, CategoryStyle> categoryStyles = {
  'all': const CategoryStyle(name: 'All', icon: LucideIcons.star, backgroundColor: Color(0xFFEDE4FF)),
  'trending': const CategoryStyle(name: 'Trending', icon: LucideIcons.flame, backgroundColor: Color(0xFFFFEDE0)),
  'anime': const CategoryStyle(name: 'Anime', icon: LucideIcons.sparkles, backgroundColor: Color(0xFFFFF6D9)),
  'anatomy': const CategoryStyle(name: 'Anatomy', icon: LucideIcons.hand, backgroundColor: Color(0xFFFFE4EC)),
  'tattoo': const CategoryStyle(name: 'Tattoo', icon: LucideIcons.penTool, backgroundColor: Color(0xFFE4E9FF)),
  'aesthetic': const CategoryStyle(name: 'Aesthetic', icon: LucideIcons.wand2, backgroundColor: Color(0xFFF3E4FF)),
  'love': const CategoryStyle(name: 'Love', icon: LucideIcons.heart, backgroundColor: Color(0xFFFFE0E9)),
  'people': const CategoryStyle(name: 'People', icon: LucideIcons.user, backgroundColor: Color(0xFFE0F2FF)),
  'cute': const CategoryStyle(name: 'Cute', icon: LucideIcons.smile, backgroundColor: Color(0xFFFFEAE0)),
  'kawaii': const CategoryStyle(name: 'Kawaii', icon: LucideIcons.cat, backgroundColor: Color(0xFFFFE9F3)),
  'food': const CategoryStyle(name: 'Food', icon: LucideIcons.utensils, backgroundColor: Color(0xFFFFF0D9)),
  'for kids': const CategoryStyle(name: 'For Kids', icon: LucideIcons.baby, backgroundColor: Color(0xFFE0FFF0)),
  'for beginners': const CategoryStyle(name: 'For Beginners', icon: LucideIcons.pencil, backgroundColor: Color(0xFFE9E0FF)),
  'holidays': const CategoryStyle(name: 'Holidays', icon: LucideIcons.gift, backgroundColor: Color(0xFFFFE0E0)),
  'geometry': const CategoryStyle(name: 'Geometry', icon: LucideIcons.shapes, backgroundColor: Color(0xFFE0F7FF)),
  'objects': const CategoryStyle(name: 'Objects', icon: LucideIcons.box, backgroundColor: Color(0xFFF0E0FF)),
  'animals': const CategoryStyle(name: 'Animals', icon: LucideIcons.dog, backgroundColor: Color(0xFFE0FFE4)),
  'cars': const CategoryStyle(name: 'Cars', icon: LucideIcons.car, backgroundColor: Color(0xFFE0EFFF)),
  'nature': const CategoryStyle(name: 'Nature', icon: LucideIcons.leaf, backgroundColor: Color(0xFFE4FFE0)),
  'architecture': const CategoryStyle(name: 'Architecture', icon: LucideIcons.building2, backgroundColor: Color(0xFFF5F0E0)),
};

CategoryStyle? getStyleForCategory(String name) {
  return categoryStyles[name.toLowerCase()];
}

const CategoryStyle fallbackCategoryStyle = CategoryStyle(
  name: 'Category',
  icon: LucideIcons.star,
  backgroundColor: Color(0xFFEDE4FF),
);
