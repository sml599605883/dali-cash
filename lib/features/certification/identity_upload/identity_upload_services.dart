import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

abstract interface class IdentityUploadImagePicker {
  Future<String?> pickFromCamera();

  Future<String?> pickFromAlbum();
}

abstract interface class IdentityUploadImageCompressor {
  Future<String?> compressToLimit(String filePath);
}

class IdentityUploadCameraPermissionException implements Exception {
  const IdentityUploadCameraPermissionException();
}

class DefaultIdentityUploadImagePicker implements IdentityUploadImagePicker {
  DefaultIdentityUploadImagePicker({ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  @override
  Future<String?> pickFromCamera() async {
    return (await _imagePicker.pickImage(source: ImageSource.camera))?.path;
  }

  @override
  Future<String?> pickFromAlbum() async {
    return (await _imagePicker.pickImage(source: ImageSource.gallery))?.path;
  }
}

class DefaultIdentityUploadImageCompressor
    implements IdentityUploadImageCompressor {
  static const _targetBytes = 500 * 1024;

  @override
  Future<String?> compressToLimit(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      return null;
    }

    var quality = 90;
    File compressedFile = file;
    while (quality >= 10) {
      final result = await _compressQuality(compressedFile, quality);
      if (result == null) {
        return null;
      }
      compressedFile = result;
      if (compressedFile.lengthSync() <= _targetBytes) {
        return compressedFile.path;
      }
      quality -= 5;
    }

    final bytes = await compressedFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    var width = frame.image.width;
    var height = frame.image.height;
    while (width > 100 && height > 100) {
      width = (width * 0.95).toInt();
      height = (height * 0.95).toInt();
      final result = await _compressSize(file, width, height);
      if (result == null) {
        return null;
      }
      compressedFile = result;
      if (compressedFile.lengthSync() <= _targetBytes) {
        return compressedFile.path;
      }
    }
    return compressedFile.path;
  }

  Future<File?> _compressQuality(File file, int quality) async {
    final targetPath = await _targetPath();
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: quality,
      format: CompressFormat.jpeg,
      autoCorrectionAngle: false,
      keepExif: false,
    );
    return result == null ? null : File(result.path);
  }

  Future<File?> _compressSize(File file, int width, int height) async {
    final targetPath = await _targetPath();
    final result = await FlutterImageCompress.compressAndGetFile(
      file.path,
      targetPath,
      minWidth: width,
      minHeight: height,
      quality: 95,
      format: CompressFormat.jpeg,
    );
    return result == null ? null : File(result.path);
  }

  Future<String> _targetPath() async {
    final directory = await getTemporaryDirectory();
    return '${directory.path}/identity_upload_${DateTime.now().microsecondsSinceEpoch}.jpg';
  }
}
