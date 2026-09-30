import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/category.dart';
import '../../data/models/template.dart';
import '../../data/repositories/template_repository.dart';

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final repo = ref.watch(templateRepositoryProvider);
  return repo.getCategories();
});

final templatesProvider = FutureProvider<List<Template>>((ref) async {
  final repo = ref.watch(templateRepositoryProvider);
  return repo.getTemplates();
});

class SelectedCategoryIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setCategory(String? categoryId) {
    state = categoryId;
  }
}

final selectedCategoryIdProvider =
    NotifierProvider<SelectedCategoryIdNotifier, String?>(() {
  return SelectedCategoryIdNotifier();
});

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => "";

  void setSearch(String query) {
    state = query;
  }
}

final searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(() {
  return SearchQueryNotifier();
});

class TemplateFilterState {
  final String? difficulty; // 'easy', 'medium', 'hard'
  final String? colorType; // 'bw', 'colorful'

  const TemplateFilterState({
    this.difficulty,
    this.colorType,
  });

  bool get isActive => difficulty != null || colorType != null;

  TemplateFilterState copyWith({
    String? difficulty,
    String? colorType,
    bool clearDifficulty = false,
    bool clearColorType = false,
  }) {
    return TemplateFilterState(
      difficulty: clearDifficulty ? null : (difficulty ?? this.difficulty),
      colorType: clearColorType ? null : (colorType ?? this.colorType),
    );
  }
}

class TemplateFilterNotifier extends Notifier<TemplateFilterState> {
  @override
  TemplateFilterState build() => const TemplateFilterState();

  void setFilter({String? difficulty, String? colorType}) {
    state = TemplateFilterState(
      difficulty: difficulty,
      colorType: colorType,
    );
  }

  void reset() {
    state = const TemplateFilterState();
  }
}

final templateFilterProvider =
    NotifierProvider<TemplateFilterNotifier, TemplateFilterState>(() {
  return TemplateFilterNotifier();
});

final categoryTemplatesProvider = FutureProvider.family<List<Template>, String>((ref, categoryId) async {
  final repo = ref.watch(templateRepositoryProvider);
  final filter = ref.watch(templateFilterProvider);
  final templates = await repo.getTemplatesByCategory(categoryId);

  return templates.where((template) {
    if (filter.difficulty != null && template.difficulty != null) {
      if (template.difficulty!.toLowerCase() != filter.difficulty!.toLowerCase()) {
        return false;
      }
    }
    if (filter.colorType != null && template.colorType != null) {
      if (template.colorType!.toLowerCase() != filter.colorType!.toLowerCase()) {
        return false;
      }
    }
    return true;
  }).toList();
});

final filteredTemplatesProvider = Provider<AsyncValue<List<Template>>>((ref) {
  final templatesAsync = ref.watch(templatesProvider);
  final selectedCategoryId = ref.watch(selectedCategoryIdProvider);
  final searchQuery = ref.watch(searchQueryProvider).toLowerCase();
  final filter = ref.watch(templateFilterProvider);

  return templatesAsync.whenData((templates) {
    return templates.where((template) {
      final matchesCategory = selectedCategoryId == null ||
          template.categoryId == selectedCategoryId;
      final matchesSearch =
          template.title.toLowerCase().contains(searchQuery);
      final matchesDifficulty = filter.difficulty == null ||
          (template.difficulty != null &&
              template.difficulty!.toLowerCase() == filter.difficulty!.toLowerCase());
      final matchesColorType = filter.colorType == null ||
          (template.colorType != null &&
              template.colorType!.toLowerCase() == filter.colorType!.toLowerCase());
      return matchesCategory && matchesSearch && matchesDifficulty && matchesColorType;
    }).toList();
  });
});
