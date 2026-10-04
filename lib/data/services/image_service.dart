import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/utils/error_handler.dart';

class ImagePickerResult {
  final File? image;
  final String? error;
  final bool cancelled;

  const ImagePickerResult._({
    this.image,
    this.error,
    this.cancelled = false,
  });

  factory ImagePickerResult.ok(File image) =>
      ImagePickerResult._(image: image);

  factory ImagePickerResult.fail(String error) =>
      ImagePickerResult._(error: error);

  factory ImagePickerResult.cancelled() =>
      const ImagePickerResult._(cancelled: true);
}

class ImageService {
  final ImagePicker _picker;

  ImageService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  Future<ImagePickerResult> pickFromCamera() async {
    // Minta permission kamera
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      return ImagePickerResult.fail(
          'Izin kamera ditolak. Aktifkan di pengaturan.');
    }

    try {
      final xFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1080,
        imageQuality: 90,
      );
      if (xFile == null) return ImagePickerResult.cancelled();

      final cropped = await _crop(File(xFile.path));
      if (cropped == null) return ImagePickerResult.cancelled();

      return ImagePickerResult.ok(cropped);
    } on Exception catch (e) {
      return ImagePickerResult.fail(ErrorHandler.handle(e));
    }
  }

  Future<ImagePickerResult> pickFromGallery() async {
    // Minta permission galeri
    final status = await Permission.photos.request();
    if (!status.isGranted) {
      return ImagePickerResult.fail(
          'Izin galeri ditolak. Aktifkan di pengaturan.');
    }

    try {
      final xFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        imageQuality: 90,
      );
      if (xFile == null) return ImagePickerResult.cancelled();

      final cropped = await _crop(File(xFile.path));
      if (cropped == null) return ImagePickerResult.cancelled();

      return ImagePickerResult.ok(cropped);
    } on Exception catch (e) {
      return ImagePickerResult.fail(ErrorHandler.handle(e));
    }
  }

  Future<File?> _crop(File image) async {
    try {
      final cropped = await ImageCropper().cropImage(
        sourcePath: image.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 90,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Foto',
            toolbarColor: const Color(0xFF6B5B95),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: false,
            aspectRatioPresets: const [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
          IOSUiSettings(
            title: 'Crop Foto',
          ),
        ],
      );
      if (cropped == null) return null;
      return File(cropped.path);
    } on Exception catch (_) {
      return image; // fallback: pakai asli
    }
  }

  /// Kompres gambar, target <= 1MB
  Future<File> compressImage(File image) async {
    try {
      final dir = Directory.systemTemp;
      var quality = 85;
      var minSize = 1080;

      File? result;
      while (result == null && quality > 30) {
        final target =
            '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}_$quality.jpg';
        final compressed = await FlutterImageCompress.compressAndGetFile(
          image.absolute.path,
          target,
          quality: quality,
          minWidth: minSize,
          minHeight: minSize,
        );
        if (compressed != null) {
          final file = File(compressed.path);
          // Kalau masih > 1MB, kompres lagi lebih agresif
          if (await file.length() > 1024 * 1024) {
            quality -= 15;
            minSize = minSize > 700 ? minSize - 100 : minSize;
            result = null; // coba lagi
          } else {
            result = file;
          }
        } else {
          quality -= 15;
        }
      }

      return result ?? image;
    } on Exception catch (_) {
      return image;
    }
  }

  /// Buat thumbnail kecil untuk grid
  Future<File?> createThumbnail(File image) async {
    try {
      final dir = Directory.systemTemp;
      final target =
          '${dir.path}/thumb_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final compressed = await FlutterImageCompress.compressAndGetFile(
        image.absolute.path,
        target,
        quality: 60,
        minWidth: 300,
        minHeight: 300,
      );
      if (compressed == null) return null;
      return File(compressed.path);
    } on Exception catch (_) {
      return null;
    }
  }
}
