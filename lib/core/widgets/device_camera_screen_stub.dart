import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Stub untuk platform non-web (Android/iOS/Desktop memakai kamera native).
Future<Uint8List?> captureWithWebDeviceCamera(
  BuildContext context, {
  Future<Uint8List?> Function()? onFileFallback,
}) async {
  return null;
}

