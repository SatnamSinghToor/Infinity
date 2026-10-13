import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:google_mlkit_subject_segmentation/google_mlkit_subject_segmentation.dart';

/// Cuts a product out of its photo's background using Google ML Kit's
/// on-device Subject Segmentation — free, no API key, no upload; the photo
/// never leaves the phone before the seller saves it.
///
/// The result is a PNG with a transparent background, trimmed to the
/// product. Android only (ML Kit's subject segmentation has no iOS/web
/// version), and it needs Google Play services for its model.
class BackgroundRemovalService {
  /// Below this share of visibly-opaque pixels we assume ML Kit found no
  /// subject (an all-transparent result would upload as an empty image).
  static const _minSubjectShare = 0.01;

  /// Extra room left around the product after trimming, as a share of its
  /// longer side.
  static const _trimPadding = 0.04;

  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Removes the background from the image file at [path]. Returns PNG bytes,
  /// or null if it couldn't be done (unsupported device, no subject found,
  /// model unavailable) — callers should then keep the original photo.
  static Future<Uint8List?> removeBackground(String path) async {
    if (!isSupported) return null;

    final segmenter = SubjectSegmenter(
      options: SubjectSegmenterOptions(
        enableForegroundBitmap: true,
        enableForegroundConfidenceMask: false,
        enableMultipleSubjects: SubjectResultOptions(
          enableConfidenceMask: false,
          enableSubjectBitmap: false,
        ),
      ),
    );

    try {
      // The first ever run has to download the segmentation model through
      // Google Play services; ML Kit reports that as an error until it's
      // ready, so wait and retry a few times.
      for (var attempt = 0; attempt < 4; attempt++) {
        try {
          final result =
              await segmenter.processImage(InputImage.fromFilePath(path));
          final png = result.foregroundBitmap;
          if (png == null) return null;
          return await _trimToSubject(png);
        } on PlatformException catch (e) {
          final text = '${e.message} ${e.details}'.toLowerCase();
          final modelPending =
              text.contains('download') || text.contains('waiting');
          if (!modelPending || attempt == 3) {
            debugPrint('Background removal failed: $e');
            return null;
          }
          await Future<void>.delayed(const Duration(seconds: 4));
        }
      }
    } catch (e) {
      debugPrint('Background removal failed: $e');
    } finally {
      unawaited(segmenter.close());
    }
    return null;
  }

  /// Crops [png] to the bounding box of its opaque pixels (plus a little
  /// padding). Returns null when there's effectively no subject.
  static Future<Uint8List?> _trimToSubject(Uint8List png) async {
    final codec = await ui.instantiateImageCodec(png);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    codec.dispose();

    try {
      final width = image.width;
      final height = image.height;
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (data == null || width == 0 || height == 0) return null;

      var minX = width, minY = height, maxX = -1, maxY = -1;
      var opaque = 0;
      for (var y = 0; y < height; y++) {
        final row = y * width * 4;
        for (var x = 0; x < width; x++) {
          if (data.getUint8(row + x * 4 + 3) > 24) {
            opaque++;
            if (x < minX) minX = x;
            if (x > maxX) maxX = x;
            if (y < minY) minY = y;
            if (y > maxY) maxY = y;
          }
        }
      }
      if (opaque < width * height * _minSubjectShare) return null;

      final pad = ((maxX - minX > maxY - minY ? maxX - minX : maxY - minY) *
              _trimPadding)
          .round();
      final left = (minX - pad).clamp(0, width - 1).toInt();
      final top = (minY - pad).clamp(0, height - 1).toInt();
      final right = (maxX + pad + 1).clamp(1, width).toInt();
      final bottom = (maxY + pad + 1).clamp(1, height).toInt();
      final cropWidth = right - left;
      final cropHeight = bottom - top;

      // Already (almost) edge to edge — keep the bytes ML Kit gave us.
      if (cropWidth * cropHeight > width * height * 0.95) return png;

      final recorder = ui.PictureRecorder();
      ui.Canvas(recorder).drawImageRect(
        image,
        ui.Rect.fromLTWH(
          left.toDouble(),
          top.toDouble(),
          cropWidth.toDouble(),
          cropHeight.toDouble(),
        ),
        ui.Rect.fromLTWH(0, 0, cropWidth.toDouble(), cropHeight.toDouble()),
        ui.Paint()..filterQuality = ui.FilterQuality.high,
      );
      final picture = recorder.endRecording();
      final cropped = await picture.toImage(cropWidth, cropHeight);
      picture.dispose();
      final out = await cropped.toByteData(format: ui.ImageByteFormat.png);
      cropped.dispose();
      return out?.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }
}
