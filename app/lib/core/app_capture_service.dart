import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class CaptureSnapshot {
  const CaptureSnapshot({
    required this.bytes,
    required this.capturedAt,
    required this.width,
    required this.height,
  });

  final Uint8List bytes;
  final DateTime capturedAt;
  final int width;
  final int height;
}

class AppCaptureService {
  AppCaptureService._();

  static final AppCaptureService instance = AppCaptureService._();

  final GlobalKey boundaryKey = GlobalKey();

  CaptureSnapshot? _latestCapture;

  CaptureSnapshot? get latestCapture => _latestCapture;

  Future<CaptureSnapshot?> captureVisibleApp({
    double pixelRatio = 2,
  }) async {
    final boundaryContext = boundaryKey.currentContext;
    if (boundaryContext == null) {
      return null;
    }

    final boundary =
        boundaryContext.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      return null;
    }

    if (boundary.debugNeedsPaint) {
      await Future<void>.delayed(const Duration(milliseconds: 32));
      return captureVisibleApp(pixelRatio: pixelRatio);
    }

    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (byteData == null) {
      return null;
    }

    final snapshot = CaptureSnapshot(
      bytes: byteData.buffer.asUint8List(),
      capturedAt: DateTime.now(),
      width: image.width,
      height: image.height,
    );
    _latestCapture = snapshot;
    return snapshot;
  }

  void clear() {
    _latestCapture = null;
  }
}
