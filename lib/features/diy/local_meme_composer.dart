import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

/// 本地叠字：白字 + 黑描边，经典表情包样式
class LocalMemeComposer {
  LocalMemeComposer._();

  static Future<Uint8List> compose({
    required Uint8List backgroundBytes,
    String top = '',
    String bottom = '',
  }) async {
    final codec = await ui.instantiateImageCodec(backgroundBytes);
    final frame = await codec.getNextFrame();
    final bg = frame.image;
    final w = bg.width.toDouble();
    final h = bg.height.toDouble();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImage(bg, Offset.zero, Paint());

    final fontSize = (w * 0.08).clamp(28.0, 72.0);
    final pad = w * 0.04;
    final maxWidth = w - pad * 2;

    if (top.trim().isNotEmpty) {
      _drawMemeText(
        canvas,
        top.trim(),
        Offset(w / 2, pad),
        fontSize: fontSize,
        maxWidth: maxWidth,
        alignTop: true,
      );
    }
    if (bottom.trim().isNotEmpty) {
      _drawMemeText(
        canvas,
        bottom.trim(),
        Offset(w / 2, h - pad),
        fontSize: fontSize,
        maxWidth: maxWidth,
        alignTop: false,
      );
    }

    final picture = recorder.endRecording();
    final out = await picture.toImage(bg.width, bg.height);
    final data = await out.toByteData(format: ui.ImageByteFormat.png);
    bg.dispose();
    out.dispose();
    if (data == null) {
      throw StateError('导出表情包失败');
    }
    return data.buffer.asUint8List();
  }

  static void _drawMemeText(
    Canvas canvas,
    String text,
    Offset anchor, {
    required double fontSize,
    required double maxWidth,
    required bool alignTop,
  }) {
    final stroke = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = fontSize * 0.12
            ..color = const Color(0xFF000000),
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);

    final fill = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: const Color(0xFFFFFFFF),
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);

    final dy = alignTop ? anchor.dy : anchor.dy - fill.height;
    final offset = Offset(anchor.dx - fill.width / 2, dy);
    stroke.paint(canvas, offset);
    fill.paint(canvas, offset);
  }
}
