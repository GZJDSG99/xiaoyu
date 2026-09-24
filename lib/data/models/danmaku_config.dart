import 'package:flutter/material.dart';

/// 弹幕滚动速度
enum DanmakuSpeed {
  slow,
  medium,
  fast;

  String get label => switch (this) {
        DanmakuSpeed.slow => '慢',
        DanmakuSpeed.medium => '中',
        DanmakuSpeed.fast => '快',
      };

  /// 一条弹幕穿过屏幕的时长
  Duration get crossDuration => switch (this) {
        DanmakuSpeed.slow => const Duration(seconds: 14),
        DanmakuSpeed.medium => const Duration(seconds: 9),
        DanmakuSpeed.fast => const Duration(seconds: 5),
      };
}

/// 弹幕展示参数
class DanmakuConfig {
  const DanmakuConfig({
    required this.lines,
    this.fontSize = 36,
    this.colorValue = 0xFFFFFFFF,
    this.speed = DanmakuSpeed.medium,
  });

  final List<String> lines;
  final double fontSize;
  final int colorValue;
  final DanmakuSpeed speed;

  Color get color => Color(colorValue < 0 ? 0xFFFFFFFF : colorValue);

  bool get isRainbowFlash => colorValue == kDanmakuRainbowFlash;

  DanmakuConfig copyWith({
    List<String>? lines,
    double? fontSize,
    int? colorValue,
    DanmakuSpeed? speed,
  }) {
    return DanmakuConfig(
      lines: lines ?? this.lines,
      fontSize: fontSize ?? this.fontSize,
      colorValue: colorValue ?? this.colorValue,
      speed: speed ?? this.speed,
    );
  }
}

/// 可选颜色（ARGB）；七彩炫光用特殊值
const kDanmakuRainbowFlash = -1;

const kDanmakuColorPresets = <int>[
  0xFFFFFFFF, // 白
  0xFFFFEB3B, // 黄
  0xFFFF80AB, // 粉
  0xFF80D8FF, // 青
  0xFF69F0AE, // 绿
  0xFFFFAB40, // 橙
  0xFFEA80FC, // 紫
  kDanmakuRainbowFlash, // 七彩炫光
];
