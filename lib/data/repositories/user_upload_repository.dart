import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_upload.dart';

class UserUploadRepository {
  static const String _localKey = 'user_uploads_list';

  UserUploadRepository();

  /// Save an upload to local device storage.
  Future<UserUpload> addUpload({
    required String imagePath,
    String? outlinePath,
  }) async {
    final String uploadId = 'upload_${DateTime.now().millisecondsSinceEpoch}';
    final DateTime now = DateTime.now();

    // 1. Copy files to permanent documents directory for persistent local access
    final docsDir = await getApplicationDocumentsDirectory();
    final uploadsDir = Directory('${docsDir.path}/user_uploads');
    if (!await uploadsDir.exists()) {
      await uploadsDir.create(recursive: true);
    }

    File srcFile = imagePath.startsWith('file:')
        ? File.fromUri(Uri.parse(imagePath))
        : File(imagePath);

    final localImgFile = File('${uploadsDir.path}/${uploadId}_img.png');
    String finalImageUrl = srcFile.path;

    if (await srcFile.exists()) {
      try {
        await srcFile.copy(localImgFile.path);
        finalImageUrl = localImgFile.path;
      } catch (e) {
        debugPrint("Error copying local image: $e");
      }
    }

    String? localOutlinePath;
    if (outlinePath != null && outlinePath.isNotEmpty) {
      File outlineSrcFile = outlinePath.startsWith('file:')
          ? File.fromUri(Uri.parse(outlinePath))
          : File(outlinePath);
      if (await outlineSrcFile.exists()) {
        try {
          final outlineFile = File('${uploadsDir.path}/${uploadId}_outline.png');
          await outlineSrcFile.copy(outlineFile.path);
          localOutlinePath = outlineFile.path;
        } catch (e) {
          debugPrint("Error copying outline image: $e");
          localOutlinePath = outlineSrcFile.path;
        }
      }
    }

    final newUpload = UserUpload(
      id: uploadId,
      imageUrl: finalImageUrl,
      outlineUrl: localOutlinePath,
      createdAt: now,
    );

    await _saveLocalCache(newUpload);
    return newUpload;
  }

  /// Get all uploads from local device cache.
  Future<List<UserUpload>> getUploads() async {
    final Map<String, UserUpload> uploadsMap = {};

    final prefs = await SharedPreferences.getInstance();
    final String? rawJson = prefs.getString(_localKey);
    if (rawJson != null && rawJson.isNotEmpty) {
      try {
        final List<dynamic> listJson = jsonDecode(rawJson);
        final List<dynamic> validList = [];
        for (var item in listJson) {
          final upload = UserUpload.fromJson(item as Map<String, dynamic>);
          String imgPath = upload.imageUrl;
          if (imgPath.startsWith('file:')) {
            imgPath = Uri.parse(imgPath).path;
          }
          final bool isNetwork = imgPath.startsWith('http');
          final bool existsOnDisk = isNetwork || File(imgPath).existsSync();

          if (existsOnDisk) {
            uploadsMap[upload.id] = upload;
            validList.add(item);
          } else {
            debugPrint("Cleaned up stale upload cache entry: ${upload.id}");
          }
        }
        if (validList.length != listJson.length) {
          await prefs.setString(_localKey, jsonEncode(validList));
        }
      } catch (e) {
        debugPrint("Error reading local user uploads: $e");
      }
    }

    final result = uploadsMap.values.toList();
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  /// Helper to save upload metadata to local SharedPreferences
  Future<void> _saveLocalCache(UserUpload upload) async {
    final prefs = await SharedPreferences.getInstance();
    final String? rawJson = prefs.getString(_localKey);
    List<dynamic> listJson = [];
    if (rawJson != null && rawJson.isNotEmpty) {
      try {
        listJson = jsonDecode(rawJson);
      } catch (_) {}
    }

    listJson.removeWhere((item) => item['id'] == upload.id);
    listJson.insert(0, upload.toJson());

    await prefs.setString(_localKey, jsonEncode(listJson));
  }

  /// Delete an upload by ID from local device cache.
  Future<void> deleteUpload(String uploadId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? rawJson = prefs.getString(_localKey);
    if (rawJson != null && rawJson.isNotEmpty) {
      try {
        List<dynamic> listJson = jsonDecode(rawJson);
        listJson.removeWhere((item) => item['id'] == uploadId);
        await prefs.setString(_localKey, jsonEncode(listJson));
      } catch (e) {
        debugPrint("Error updating local cache on delete: $e");
      }
    }
  }
}
