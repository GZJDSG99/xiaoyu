import 'package:flutter/material.dart';

/// 小语 V1.0 深色车载色板（集中定义，勿散落在 Widget 中）
abstract final class AppColors {
  static const Color background = Color(0xFF07101C);
  static const Color surface = Color(0xFF101C2B);
  static const Color surfaceSecondary = Color(0xFF16263A);
  static const Color primary = Color(0xFF75B9FF);
  static const Color text = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF91A2B7);
  static const Color border = Color(0x14FFFFFF); // rgba(255,255,255,0.08)
  static const Color glass = Color(0x1AFFFFFF);
  static const Color success = Color(0xFF5DDE9E);
  static const Color warning = Color(0xFFFFB84D);
}
