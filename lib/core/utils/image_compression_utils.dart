import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Utility for compressing images before upload.
/// Target: ~800KB, quality 85 — good balance of visual quality and storage.
class ImageCompressionUtils {
  ImageCompressionUtils._();

  /// Compress a [File] and return the compressed [File].
  /// Falls back to the original file if compression fails.
  static Future<File> compress(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      final ext = p.extension(file.path).toLowerCase();
      final isHeic = ext == '.heic' || ext == '.heif';
      final targetFormat = isHeic ? CompressFormat.jpeg : CompressFormat.jpeg;
      final outPath = p.join(
        dir.path,
        'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        outPath,
        quality: 85,
        minWidth: 1280,
        minHeight: 720,
        format: targetFormat,
      );

      if (result == null) return file;

      final compressed = File(result.path);
      final originalSize = await file.length();
      final compressedSize = await compressed.length();

      // Only use compressed if it's actually smaller
      return compressedSize < originalSize ? compressed : file;
    } catch (_) {
      return file;
    }
  }
}
