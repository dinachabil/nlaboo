import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageCompressionService {
  static const int maxWidth = 1920;
  static const int maxHeight = 1920;
  static const int quality = 85;
  static const int avatarSize = 512;

  static Future<Uint8List?> compressImage(File file) async {
    return await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      minWidth: maxWidth,
      minHeight: maxHeight,
      quality: quality,
    );
  }

  static Future<Uint8List?> compressAvatar(File file) async {
    return await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      minWidth: avatarSize,
      minHeight: avatarSize,
      quality: quality,
    );
  }

  static Future<Uint8List?> compressBytes(
    Uint8List bytes,
    String filename,
  ) async {
    return await FlutterImageCompress.compressWithList(
      bytes,
      minWidth: maxWidth,
      minHeight: maxHeight,
      quality: quality,
    );
  }

  static Future<File?> compressAndSave(File file, String outputPath) async {
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      outputPath,
      quality: quality,
      minWidth: maxWidth,
      minHeight: maxHeight,
    );
    return result != null ? File(result.path) : null;
  }
}
