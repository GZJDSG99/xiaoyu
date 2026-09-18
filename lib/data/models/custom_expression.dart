import 'dart:convert';
import 'dart:typed_data';

import 'pet_enums.dart';

class CustomExpression {
  final String id;
  final String text;
  final String? imagePath;
  final String? imageBase64;
  final DisplayAnimation animation;
  final int durationSeconds;

  /// 兼容旧数据的占位 emoji（UI 已移除选择）
  final String emoji;

  const CustomExpression({
    required this.id,
    required this.text,
    this.imagePath,
    this.imageBase64,
    this.animation = DisplayAnimation.fade,
    this.durationSeconds = 5,
    this.emoji = '✨',
  });

  bool get hasImage =>
      (imagePath != null && imagePath!.isNotEmpty) ||
      (imageBase64 != null && imageBase64!.isNotEmpty);

  Uint8List? get imageBytes {
    final b64 = imageBase64;
    if (b64 == null || b64.isEmpty) return null;
    try {
      return base64Decode(b64);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'emoji': emoji,
        'text': text,
        'imagePath': imagePath,
        'imageBase64': imageBase64,
        'animation': animation.name,
        'durationSeconds': durationSeconds,
      };

  factory CustomExpression.fromJson(Map<String, dynamic> json) {
    return CustomExpression(
      id: json['id'] as String,
      emoji: json['emoji'] as String? ?? '✨',
      text: json['text'] as String? ?? '',
      imagePath: json['imagePath'] as String?,
      imageBase64: json['imageBase64'] as String?,
      animation: DisplayAnimation.values.firstWhere(
        (e) => e.name == json['animation'],
        orElse: () => DisplayAnimation.fade,
      ),
      durationSeconds: json['durationSeconds'] as int? ?? 5,
    );
  }
}
