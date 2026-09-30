import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../templates/templates_provider.dart';
import '../../data/models/template.dart';

import '../templates/user_uploads_provider.dart';

class FavouritesNotifier extends Notifier<List<String>> {
  @override
  List<String> build() {
    // Start with a couple of default favorited IDs to make the screen look lively immediately
    return ['t1', 't3'];
  }

  void toggleFavourite(String templateId) {
    if (state.contains(templateId)) {
      state = state.where((id) => id != templateId).toList();
    } else {
      state = [...state, templateId];
    }
  }

  bool isFavourite(String templateId) {
    return state.contains(templateId);
  }
}

final favouritesProvider = NotifierProvider<FavouritesNotifier, List<String>>(() {
  return FavouritesNotifier();
});

final favouritedTemplatesProvider = Provider<AsyncValue<List<Template>>>((ref) {
  final templatesAsync = ref.watch(templatesProvider);
  final userUploadsAsync = ref.watch(userUploadsProvider);
  final favIds = ref.watch(favouritesProvider);

  return templatesAsync.whenData((templates) {
    final List<Template> list = templates.where((t) => favIds.contains(t.id)).toList();

    userUploadsAsync.whenData((uploads) {
      for (var u in uploads) {
        if (favIds.contains(u.id)) {
          list.add(u.toTemplate());
        }
      }
    });

    return list;
  });
});
