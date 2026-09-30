import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_upload.dart';
import '../../data/repositories/user_upload_repository.dart';

final userUploadRepositoryProvider = Provider<UserUploadRepository>((ref) {
  return UserUploadRepository();
});

class UserUploadsNotifier extends AsyncNotifier<List<UserUpload>> {
  @override
  Future<List<UserUpload>> build() async {
    final repo = ref.watch(userUploadRepositoryProvider);
    return await repo.getUploads();
  }

  Future<UserUpload> addUpload({
    required String imagePath,
    String? outlinePath,
  }) async {
    final repo = ref.read(userUploadRepositoryProvider);
    final upload = await repo.addUpload(imagePath: imagePath, outlinePath: outlinePath);
    ref.invalidateSelf();
    return upload;
  }

  Future<void> deleteUpload(String uploadId) async {
    final repo = ref.read(userUploadRepositoryProvider);
    await repo.deleteUpload(uploadId);
    ref.invalidateSelf();
  }
}

final userUploadsProvider = AsyncNotifierProvider<UserUploadsNotifier, List<UserUpload>>(() {
  return UserUploadsNotifier();
});
