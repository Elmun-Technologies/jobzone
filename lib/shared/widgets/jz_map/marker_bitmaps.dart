import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Renders small marker images (PNG bytes) for the Yandex map, which needs
/// raster icons rather than widgets. Pure `dart:ui` Canvas drawing (no widget
/// tree); results are cached by content so each distinct label/count is drawn
/// once. Used only by the mobile (Yandex) map — the web map uses widgets.
class MarkerBitmaps {
  MarkerBitmaps._();

  static final _cache = <String, Uint8List>{};

  static const _brand = Color(0xFF1F8F4E); // green, matching the reference maps
  static const _blue = Color(0xFF0D80F2);
  static const _white = Color(0xFFFFFFFF);
  static const _dpr = 3.0; // render at 3x for crisp icons on hi-dpi screens

  /// A green circle with the cluster [count] centered in white.
  static Future<Uint8List> clusterBubble(int count) =>
      _cached('cluster:$count', () => _circle('$count', _brand, 22));

  /// A rounded "pill" showing the salary [label] (e.g. "5 mln so'm").
  static Future<Uint8List> salaryPill(String label) =>
      _cached('pill:$label', () => _pill(label));

  /// A blue dot for the user's own location.
  static Future<Uint8List> meDot() =>
      _cached('me', () => _circle('', _blue, 13));

  /// Decodes raw image bytes (e.g. a fetched logo) into a [ui.Image].
  static Future<ui.Image> decodeImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  /// A circular [logo] (white ring) with the salary [label] in a pill below it.
  /// Cached by [cacheKey] so a given company+salary is composited once.
  static Future<Uint8List> markerWithLogo({
    required String cacheKey,
    required ui.Image logo,
    String? label,
  }) => _cached('logo:$cacheKey', () => _withLogo(logo, label));

  static Future<Uint8List> _cached(
    String key,
    Future<Uint8List> Function() build,
  ) async {
    final hit = _cache[key];
    if (hit != null) return hit;
    final bytes = await build();
    _cache[key] = bytes;
    return bytes;
  }

  static Future<Uint8List> _toPng(ui.Picture picture, int w, int h) async {
    final img = await picture.toImage(w, h);
    final bd = await img.toByteData(format: ui.ImageByteFormat.png);
    return bd!.buffer.asUint8List();
  }

  /// Filled circle of [radius] (logical) with optional centered white [text].
  static Future<Uint8List> _circle(String text, Color fill, double radius) {
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
    return _toPng(rec.endRecording(), size, size);
  }

  static Future<Uint8List> _pill(String label) {
    final padH = 11 * _dpr;
    final padV = 6 * _dpr;
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: _white,
          fontSize: 13 * _dpr,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final w = (tp.width + padH * 2).round();
    final h = (tp.height + padV * 2).round();
    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec);
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
      Radius.circular(h / 2),
    );
    canvas.drawRRect(rrect, Paint()..color = _brand);
    tp.paint(canvas, Offset(padH, padV));
    return _toPng(rec.endRecording(), w, h);
  }

  /// Circular [logo] (white ring) with the salary [label] in a pill below it.
  static Future<Uint8List> _withLogo(ui.Image logo, String? label) async {
    final logoD = 44 * _dpr;
    final ring = 2.5 * _dpr;

    TextPainter? tp;
    var pillW = 0.0, pillH = 0.0;
    if (label != null && label.isNotEmpty) {
      tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: _white,
            fontSize: 12 * _dpr,
            fontWeight: FontWeight.w700,
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
        Paint()..color = _brand,
      );
      tp.paint(
        canvas,
        Offset(pillRect.left + 9 * _dpr, pillRect.top + 4 * _dpr),
      );
    }
    return _toPng(rec.endRecording(), w.round(), h.round());
  }
}
