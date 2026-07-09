import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Renders small marker images for the Yandex map, which needs raster icons
/// rather than widgets. Pure `dart:ui` Canvas drawing (no widget tree); results
/// are cached by content so each distinct label/count is drawn once. Used only
/// by the mobile (Yandex) map — the web map uses widgets.
///
/// Returns [ui.Image]s (what the official SDK's `ImageProvider` callback
/// expects). The SDK disposes the image it is handed after uploading it, so
/// callers must pass `image.clone()` — never the cached instance itself.
class MarkerBitmaps {
  MarkerBitmaps._();

  static final _cache = <String, ui.Image>{};

  // Yolla brand: ink cluster bubbles, volt salary pills (ink text) — adapted
  // to our identity rather than the reference apps' green.
  static const _ink = Color(0xFF0A0A0A);
  static const _volt = Color(0xFFC7FB00);
  static const _blue = Color(0xFF0D80F2); // "me" location — map convention
  static const _white = Color(0xFFFFFFFF);
  static const _dpr = 3.0; // render at 3x for crisp icons on hi-dpi screens

  /// An ink circle with the cluster [count] centered in white.
  static Future<ui.Image> clusterBubble(int count) =>
      _cached('cluster:$count', () => _circle('$count', _ink, 22));

  /// A volt "price tag" pill (ink text) with a downward tail that points at the
  /// exact location — showing the salary [label] (e.g. "5 mln so'm").
  static Future<ui.Image> salaryPill(String label) =>
      _cached('pill:$label', () => _pill(label));

  /// A blue dot for the user's own location.
  static Future<ui.Image> meDot() =>
      _cached('me', () => _circle('', _blue, 13));

  /// Decodes raw image bytes (e.g. a fetched logo) into a [ui.Image].
  static Future<ui.Image> decodeImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  /// A circular [logo] (white ring) with the salary [label] in a pill below it.
  /// Cached by [cacheKey] so a given company+salary is composited once.
  static Future<ui.Image> markerWithLogo({
    required String cacheKey,
    required ui.Image logo,
    String? label,
  }) => _cached('logo:$cacheKey', () => _withLogo(logo, label));

  static Future<ui.Image> _cached(
    String key,
    Future<ui.Image> Function() build,
  ) async {
    final hit = _cache[key];
    if (hit != null) return hit;
    final img = await build();
    _cache[key] = img;
    return img;
  }

  /// Filled circle of [radius] (logical) with optional centered white [text].
  static Future<ui.Image> _circle(String text, Color fill, double radius) {
    final r = radius * _dpr;
    final size = (r * 2 + 4 * _dpr).round();
    final c = Offset(size / 2, size / 2);
    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec);
    canvas.drawCircle(c, r, Paint()..color = fill);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * _dpr
        ..color = _white,
    );
    if (text.isNotEmpty) {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: _white,
            fontSize: 15 * _dpr,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
    }
    return rec.endRecording().toImage(size, size);
  }

  /// Volt "price tag" bubble with ink text and a downward tail. The image is
  /// sized so the tail tip is at bottom-centre — callers tip-anchor it (0.5,1)
  /// so the tag points at the exact map location.
  static Future<ui.Image> _pill(String label) {
    final padH = 12 * _dpr;
    final padV = 7 * _dpr;
    final tail = 7 * _dpr;
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: _ink,
          fontSize: 13 * _dpr,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final w = (tp.width + padH * 2).round();
    final bubbleH = tp.height + padV * 2;
    final h = (bubbleH + tail).round();
    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec);
    final paint = Paint()..color = _volt;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w.toDouble(), bubbleH),
      Radius.circular(10 * _dpr),
    );
    canvas.drawRRect(rrect, paint);
    final cx = w / 2;
    final tailPath = Path()
      ..moveTo(cx - tail, bubbleH)
      ..lineTo(cx + tail, bubbleH)
      ..lineTo(cx, bubbleH + tail)
      ..close();
    canvas.drawPath(tailPath, paint);
    tp.paint(canvas, Offset(padH, padV));
    return rec.endRecording().toImage(w, h);
  }

  /// Circular [logo] (white ring) with the salary [label] in a pill below it.
  static Future<ui.Image> _withLogo(ui.Image logo, String? label) async {
    final logoD = 44 * _dpr;
    final ring = 2.5 * _dpr;

    TextPainter? tp;
    var pillW = 0.0, pillH = 0.0;
    if (label != null && label.isNotEmpty) {
      tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: _ink,
            fontSize: 12 * _dpr,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      pillW = tp.width + 18 * _dpr;
      pillH = tp.height + 8 * _dpr;
    }
    final gap = pillH == 0 ? 0.0 : 3 * _dpr;
    final w = logoD > pillW ? logoD : pillW;
    final h = logoD + gap + pillH;

    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec);
    final logoCenter = Offset(w / 2, logoD / 2);

    canvas.drawCircle(logoCenter, logoD / 2, Paint()..color = _white);
    canvas.save();
    canvas.clipPath(
      Path()..addOval(
        Rect.fromCircle(center: logoCenter, radius: logoD / 2 - ring),
      ),
    );
    // Cover-fit: take the largest centered square of the source image.
    final side = logo.width < logo.height
        ? logo.width.toDouble()
        : logo.height.toDouble();
    final src = Rect.fromCenter(
      center: Offset(logo.width / 2, logo.height / 2),
      width: side,
      height: side,
    );
    final dst = Rect.fromCircle(center: logoCenter, radius: logoD / 2 - ring);
    canvas.drawImageRect(
      logo,
      src,
      dst,
      Paint()..filterQuality = FilterQuality.medium,
    );
    canvas.restore();

    if (tp != null) {
      final pillRect = Rect.fromLTWH(
        (w - pillW) / 2,
        logoD + gap,
        pillW,
        pillH,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(pillRect, Radius.circular(pillH / 2)),
        Paint()..color = _volt,
      );
      tp.paint(
        canvas,
        Offset(pillRect.left + 9 * _dpr, pillRect.top + 4 * _dpr),
      );
    }
    return rec.endRecording().toImage(w.round(), h.round());
  }
}
