import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class ImageUtils {
  /// Converts a photo file to a black and white outline sketch.
  /// Runs inside a background isolate to keep UI responsive.
  static Future<Uint8List?> convertToOutline(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      return await compute(_processOutline, bytes);
    } catch (e) {
      debugPrint("Error converting image to outline: $e");
      return null;
    }
  }

  static Uint8List? _processOutline(Uint8List bytes) {
    final image = img.decodeImage(bytes);
    if (image == null) return null;

    // 1. Resize image to a maximum dimension of 1024px to ensure fast processing
    img.Image resized = image;
    if (image.width > 1024 || image.height > 1024) {
      resized = img.copyResize(
        image,
        width: image.width > image.height ? 1024 : null,
        height: image.height >= image.width ? 1024 : null,
      );
    }

    // 2. Grayscale
    final grayscale = img.grayscale(resized);

    // 3. Sobel Edge Detection
    final edgeDetected = img.sobel(grayscale);

    // 4. Invert colors so lines are black and background is white
    final inverted = img.invert(edgeDetected);

    // 5. Enhance contrast to make outline lines look sharper and cleaner
    final contrasted = img.contrast(inverted, contrast: 150);

    return Uint8List.fromList(img.encodePng(contrasted));
  }
}
