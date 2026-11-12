import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:pakeaja/core/theme/app_theme.dart';
import 'package:web/web.dart' as web;

/// Membuka kamera langsung milik perangkat melalui WebRTC pada browser.
Future<Uint8List?> captureWithWebDeviceCamera(
  BuildContext context, {
  Future<Uint8List?> Function()? onFileFallback,
}) {
  return Navigator.of(context).push<Uint8List?>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _WebDeviceCameraScreen(onFileFallback: onFileFallback),
    ),
  );
}

class _WebDeviceCameraScreen extends StatefulWidget {
  final Future<Uint8List?> Function()? onFileFallback;

  const _WebDeviceCameraScreen({this.onFileFallback});

  @override
  State<_WebDeviceCameraScreen> createState() => _WebDeviceCameraScreenState();
}

class _WebDeviceCameraScreenState extends State<_WebDeviceCameraScreen> {
  static int _viewCounter = 0;

  late final String _viewType;
  late final web.HTMLVideoElement _videoElement;

  web.MediaStream? _stream;
  bool _isInitializing = true;
  String? _error;
  Uint8List? _capturedBytes;
  String _facingMode = 'environment';

  @override
  void initState() {
    super.initState();
    _viewCounter++;
    _viewType = 'pakeaja-device-camera-$_viewCounter';

    _videoElement = web.HTMLVideoElement()
      ..autoplay = true
      ..muted = true
      ..setAttribute('playsinline', 'true')
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover';

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) => _videoElement,
    );

    _startCamera();
  }

  Future<void> _startCamera() async {
    setState(() {
      _isInitializing = true;
      _error = null;
    });

    _stopStream();

    try {
      final mediaDevices = web.window.navigator.mediaDevices;
      web.MediaStream stream;
      try {
        final videoConstraints = <String, Object>{
          'facingMode': {'ideal': _facingMode},
          'width': {'ideal': 1280},
          'height': {'ideal': 720},
        }.jsify()!;
        stream = await mediaDevices
            .getUserMedia(web.MediaStreamConstraints(video: videoConstraints))
            .toDart;
      } catch (_) {
        // Fallback jika kamera laptop menolak constraint facingMode
        stream = await mediaDevices
            .getUserMedia(web.MediaStreamConstraints(video: true.toJS))
            .toDart;
      }

      if (!mounted) {
        _stopSpecificStream(stream);
        return;
      }

      _stream = stream;
      _videoElement.srcObject = stream;
      try {
        await _videoElement.play().toDart;
      } catch (_) {
        // Autoplay attribute sudah aktif
      }

      if (mounted) {
        setState(() => _isInitializing = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _error =
              'Tidak dapat mengakses kamera perangkat. Pastikan izin kamera diizinkan pada browser dan kamera tidak sedang dipakai aplikasi lain.';
        });
      }
    }
  }

  void _stopSpecificStream(web.MediaStream? stream) {
    if (stream == null) return;
    final tracks = stream.getTracks().toDart;
    for (final track in tracks) {
      track.stop();
    }
  }

  void _stopStream() {
    _stopSpecificStream(_stream);
    _stream = null;
    _videoElement.srcObject = null;
  }

  Future<void> _captureFrame() async {
    final width = _videoElement.videoWidth;
    final height = _videoElement.videoHeight;
    if (width <= 0 || height <= 0) {
      setState(() {
        _error = 'Kamera belum siap. Tunggu sebentar lalu coba lagi.';
      });
      return;
    }

    const maxDim = 640.0;
    var targetW = width.toDouble();
    var targetH = height.toDouble();
    if (targetW > maxDim || targetH > maxDim) {
      final ratio = targetW > targetH ? maxDim / targetW : maxDim / targetH;
      targetW = (targetW * ratio).roundToDouble();
      targetH = (targetH * ratio).roundToDouble();
    }

    final canvas = web.HTMLCanvasElement()
      ..width = targetW.toInt()
      ..height = targetH.toInt();
    final ctx = canvas.getContext('2d') as web.CanvasRenderingContext2D?;
    if (ctx == null) return;

    ctx.drawImage(_videoElement, 0, 0, targetW, targetH);

    var dataUrl = canvas.toDataURL('image/jpeg', 0.78.toJS);
    var bytes = _decodeDataUrl(dataUrl);
    // Jaga agar aman di bawah batas ukuran dokumen Firestore (~1 MiB)
    if (bytes != null && bytes.length > 500 * 1024) {
      dataUrl = canvas.toDataURL('image/jpeg', 0.55.toJS);
      bytes = _decodeDataUrl(dataUrl);
    }

    if (bytes == null || bytes.isEmpty) {
      setState(() => _error = 'Gagal memproses hasil foto dari kamera.');
      return;
    }

    setState(() {
      _capturedBytes = bytes;
      _error = null;
    });
  }

  Uint8List? _decodeDataUrl(String dataUrl) {
    final commaIdx = dataUrl.indexOf(',');
    if (commaIdx == -1 || commaIdx + 1 >= dataUrl.length) return null;
    return base64Decode(dataUrl.substring(commaIdx + 1));
  }

  void _retake() {
    setState(() => _capturedBytes = null);
  }

  void _switchCamera() {
    setState(() {
      _facingMode = _facingMode == 'environment' ? 'user' : 'environment';
      _capturedBytes = null;
    });
    _startCamera();
  }

  Future<void> _useFallback() async {
    final fallback = widget.onFileFallback;
    if (fallback == null) return;
    _stopStream();
    final bytes = await fallback();
    if (!mounted) return;
    if (bytes != null) {
      Navigator.of(context).pop(bytes);
    } else {
      _startCamera();
    }
  }

  @override
  void dispose() {
    _stopStream();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showingPreview = _capturedBytes != null;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Kamera Pakaian'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            _stopStream();
            Navigator.of(context).pop(null);
          },
        ),
        actions: [
          if (!showingPreview)
            IconButton(
              icon: const Icon(Icons.cameraswitch_outlined),
              tooltip: 'Ganti Kamera',
              onPressed: _isInitializing ? null : _switchCamera,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.black,
                child: showingPreview
                    ? Center(
                        child: Image.memory(
                          _capturedBytes!,
                          fit: BoxFit.contain,
                        ),
                      )
                    : _error != null
                        ? _buildErrorView()
                        : Stack(
                            alignment: Alignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: HtmlElementView(viewType: _viewType),
                              ),
                              if (_isInitializing)
                                const CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                            ],
                          ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              color: Colors.black,
              child: showingPreview
                  ? Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _retake,
                            icon: const Icon(Icons.refresh, color: Colors.white),
                            label: const Text(
                              'Foto Ulang',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white54),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {
                              _stopStream();
                              Navigator.of(context).pop(_capturedBytes);
                            },
                            icon: const Icon(Icons.check),
                            label: const Text('Gunakan Foto'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: (_isInitializing || _error != null)
                              ? null
                              : _captureFrame,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              color: (_isInitializing || _error != null)
                                  ? Colors.white24
                                  : Colors.white.withValues(alpha: 0.25),
                            ),
                            child: Center(
                              child: Container(
                                width: 54,
                                height: 54,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.videocam_off_outlined,
              size: 56,
              color: Colors.white70,
            ),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Kamera tidak tersedia.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _startCamera,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
                if (widget.onFileFallback != null)
                  OutlinedButton.icon(
                    onPressed: _useFallback,
                    icon: const Icon(Icons.photo_library_outlined,
                        color: Colors.white),
                    label: const Text(
                      'Pilih File / Galeri',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white54),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

