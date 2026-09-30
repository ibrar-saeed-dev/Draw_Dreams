import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'package:gal/gal.dart';

class SaveResult {
  final String localFilePath;
  final bool isLocalSaveSuccessful;
  final bool isNativeExportSuccessful;
  final bool permissionGranted;
  final String? nativeExportError;

  SaveResult({
    required this.localFilePath,
    required this.isLocalSaveSuccessful,
    required this.isNativeExportSuccessful,
    required this.permissionGranted,
    this.nativeExportError,
  });
}

class GalleryRepository {
  /// Saves the drawing to local application storage AND exports it to the phone's native photo gallery.
  Future<SaveResult> saveLocalDrawing(String tempPath) async {
    final file = File(tempPath);
    final docsDir = await getApplicationDocumentsDirectory();
    final savedDir = Directory('${docsDir.path}/saved_drawings');
    if (!await savedDir.exists()) {
      await savedDir.create(recursive: true);
    }

    final permanentFile = File('${savedDir.path}/drawing_${DateTime.now().millisecondsSinceEpoch}.png');
    bool localSuccess = false;
    if (await file.exists()) {
      await file.copy(permanentFile.path);
      localSuccess = true;
    }

    bool nativeSuccess = false;
    bool permissionGranted = false;
    String? exportError;

    try {
      // Step 3: Explicitly request and check access
      permissionGranted = await Gal.requestAccess();
      debugPrint("[Gal Debug] Gal.requestAccess() returned: $permissionGranted");

      if (permissionGranted) {
        await Gal.putImage(permanentFile.path);
        nativeSuccess = true;
        debugPrint("[Gal Debug] Gal.putImage succeeded!");
      } else {
        exportError = "Photo gallery permission denied.";
        debugPrint("[Gal Debug] Permission denied by user.");
      }
    } on GalException catch (e) {
      exportError = "GalException [${e.type}]: ${e.type.message}";
      debugPrint("[Gal Debug] GalException thrown: $exportError");
    } catch (e) {
      exportError = "Unexpected error: $e";
      debugPrint("[Gal Debug] Error during export: $e");
    }

    return SaveResult(
      localFilePath: permanentFile.path,
      isLocalSaveSuccessful: localSuccess,
      isNativeExportSuccessful: nativeSuccess,
      permissionGranted: permissionGranted,
      nativeExportError: exportError,
    );
  }

  /// Fetch all saved drawings from local app storage.
  Future<List<String>> getSavedDrawings() async {
    final List<String> list = [];
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final savedDir = Directory('${docsDir.path}/saved_drawings');
      if (await savedDir.exists()) {
        final files = savedDir.listSync();
        for (var f in files) {
          if (f is File && f.path.endsWith('.png')) {
            list.add(f.path);
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching saved drawings: $e");
    }

    return list.reversed.toList();
  }
  /// Delete a saved drawing from local storage.
  Future<bool> deleteDrawing(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (e) {
      debugPrint("Error deleting saved drawing: $e");
    }
    return false;
  }
}

final galleryRepositoryProvider = Provider<GalleryRepository>((ref) {
  return GalleryRepository();
});

final savedDrawingsProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final repo = ref.watch(galleryRepositoryProvider);
  return repo.getSavedDrawings();
});
