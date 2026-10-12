import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/utils/error_handler.dart';

class ImagePickerResult {
  final File? image;
  final Uint8List? bytes;
  final String? error;
  final bool cancelled;

  const ImagePickerResult._({
    this.image,
    this.bytes,
    this.error,
    this.cancelled = false,
  });

  factory ImagePickerResult.ok({File? image, required Uint8List bytes}) =>
      ImagePickerResult._(image: image, bytes: bytes);

  factory ImagePickerResult.fail(String error) =>
      ImagePickerResult._(error: error);

  factory ImagePickerResult.cancelled() =>
      const ImagePickerResult._(cancelled: true);
}

class ImageService {
  final ImagePicker _picker;

  ImageService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  Future<ImagePickerResult> pickFromCamera() async {
    try {
      if (!kIsWeb && !Platform.isMacOS && !Platform.isWindows && !Platform.isLinux) {
        final status = await Permission.camera.request();
        if (status.isPermanentlyDenied) {
          return ImagePickerResult.fail(
              'Izin kamera ditolak permanen. Buka pengaturan untuk mengaktifkan.');
        }
      }

      final xFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 720,
        maxHeight: 720,
        imageQuality: 70,
      );
      if (xFile == null) return ImagePickerResult.cancelled();

      // Di Web, baca bytes langsung
      if (kIsWeb) {
        final bytes = await xFile.readAsBytes();
        return ImagePickerResult.ok(bytes: bytes);
      }

      final originalFile = File(xFile.path);
      final cropped = await _crop(originalFile);
      final finalFile = cropped ?? originalFile;
      final bytes = await finalFile.readAsBytes();

      return ImagePickerResult.ok(image: finalFile, bytes: bytes);
    } on Exception catch (e) {
      return ImagePickerResult.fail(ErrorHandler.handle(e));
    }
  }

  Future<ImagePickerResult> pickFromGallery() async {
    try {
      final xFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 720,
        maxHeight: 720,
        imageQuality: 70,
      );
      if (xFile == null) return ImagePickerResult.cancelled();

      // Di Web, baca bytes langsung
      if (kIsWeb) {
        final bytes = await xFile.readAsBytes();
        return ImagePickerResult.ok(bytes: bytes);
      }

      final originalFile = File(xFile.path);
      final cropped = await _crop(originalFile);
      final finalFile = cropped ?? originalFile;
      final bytes = await finalFile.readAsBytes();

      return ImagePickerResult.ok(image: finalFile, bytes: bytes);
    } on Exception catch (e) {
      return ImagePickerResult.fail(ErrorHandler.handle(e));
    }
  }

  Future<File?> _crop(File image) async {
    if (kIsWeb) return null;
    try {
      final cropped = await ImageCropper().cropImage(
        sourcePath: image.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 85,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Potong / Sesuaikan Foto',
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
            title: 'Potong Foto',
          ),
        ],
      );
      if (cropped == null) return null;
      return File(cropped.path);
    } catch (_) {
      return null;
    }
  }

  /// Kompres gambar jika di mobile
  Future<File> compressImage(File image) async {
    if (kIsWeb) return image;
    try {
      final dir = Directory.systemTemp;
      final target =
          '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final compressed = await FlutterImageCompress.compressAndGetFile(
        image.absolute.path,
        target,
        quality: 70,
        minWidth: 480,
        minHeight: 480,
      );

      if (compressed != null) {
        return File(compressed.path);
      }
      return image;
    } catch (_) {
      return image;
    }
  }

  /// Kompresi byte gambar dan ubah menjadi String Base64 ringan untuk disimpan langsung ke Firestore.
  Future<String> compressAndConvertToBase64({File? image, Uint8List? bytes}) async {
    try {
      Uint8List targetBytes;
      if (bytes != null) {
        targetBytes = bytes;
      } else if (image != null) {
        targetBytes = await image.readAsBytes();
      } else {
        return '';
      }

      // Jika mobile dan FlutterImageCompress tersedia, kompres ukuran byte
      if (!kIsWeb) {
        try {
          final compressedBytes = await FlutterImageCompress.compressWithList(
            targetBytes,
            minWidth: 480,
            minHeight: 480,
            quality: 70,
            format: CompressFormat.jpeg,
          );
          if (compressedBytes.isNotEmpty) {
            targetBytes = compressedBytes;
          }
        } catch (_) {
          // Fallback ke targetBytes awal jika kompresi gagal
        }
      }

      // Ubah ke string base64 dengan data prefix
      final base64String = base64Encode(targetBytes);
      return 'data:image/jpeg;base64,$base64String';
    } catch (_) {
      if (bytes != null) {
        return 'data:image/jpeg;base64,${base64Encode(bytes)}';
      }
      return '';
    }
  }
}
