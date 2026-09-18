import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../data/models/custom_expression.dart';

/// 自定义表情包预览（base64 / 内存字节）
class DiyStickerImage extends StatelessWidget {
  const DiyStickerImage({
    super.key,
    this.base64,
    this.bytes,
    this.fit = BoxFit.contain,
  });

  final String? base64;
  final Uint8List? bytes;
  final BoxFit fit;

  factory DiyStickerImage.fromExpression(
    CustomExpression expression, {
    Key? key,
    BoxFit fit = BoxFit.contain,
  }) {
    return DiyStickerImage(
      key: key,
      base64: expression.imageBase64,
      fit: fit,
    );
  }

  @override
  Widget build(BuildContext context) {
    final memory = bytes ?? _decodeBase64(base64);
    if (memory == null) {
      return const Center(
        child: Icon(
          Icons.broken_image_outlined,
          size: 48,
          color: Colors.white54,
        ),
      );
    }
    return Image.memory(memory, fit: fit, gaplessPlayback: true);
  }

  static Uint8List? _decodeBase64(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return base64Decode(value);
    } catch (_) {
      return null;
    }
  }
}
