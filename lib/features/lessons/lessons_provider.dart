import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/lesson.dart';
import '../../data/repositories/lesson_repository.dart';

class SelectedDifficultyNotifier extends Notifier<String> {
  @override
  String build() => 'easy';

  void setDifficulty(String difficulty) {
    state = difficulty.toLowerCase();
  }
}

final selectedDifficultyProvider =
    NotifierProvider<SelectedDifficultyNotifier, String>(() {
  return SelectedDifficultyNotifier();
});

final lessonsByDifficultyProvider = FutureProvider.family<List<Lesson>, String>((ref, difficulty) async {
  final repo = ref.watch(lessonRepositoryProvider);
  return repo.getLessonsByDifficulty(difficulty);
});

final allLessonsProvider = FutureProvider<List<Lesson>>((ref) async {
  final repo = ref.watch(lessonRepositoryProvider);
  return repo.getLessons();
});
