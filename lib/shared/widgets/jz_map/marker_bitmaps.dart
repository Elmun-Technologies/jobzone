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
}
