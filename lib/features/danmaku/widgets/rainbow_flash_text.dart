import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 七彩炫光文字：色相缓变 + 轻光晕（不用 ShaderMask，兼容 Web）
class RainbowFlashText extends StatefulWidget {
  const RainbowFlashText({
    super.key,
    required this.text,
    required this.fontSize,
    this.maxLines = 1,
    this.softWrap = false,
    this.overflow = TextOverflow.visible,
  });

  final String text;
  final double fontSize;
  final int? maxLines;
  final bool softWrap;
  final TextOverflow overflow;

  @override
  State<RainbowFlashText> createState() => _RainbowFlashTextState();
}

class _RainbowFlashTextState extends State<RainbowFlashText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        final hue = (t * 360) % 360;
        final breath = 0.5 + 0.5 * math.sin(_controller.value * math.pi * 2);
        // 次色相轻微错开，做出“扫过”感但不靠 Shader
        final hue2 = (hue + 40) % 360;

        final color = HSVColor.fromAHSV(1, hue, 0.68, 1).toColor();
        final glow = HSVColor.fromAHSV(1, hue2, 0.55, 1).toColor();

        return Text(
          widget.text,
          maxLines: widget.maxLines,
          softWrap: widget.softWrap,
          overflow: widget.overflow,
          style: TextStyle(
            color: color,
            fontSize: widget.fontSize,
            fontWeight: FontWeight.w700,
            height: 1.1,
            shadows: [
              Shadow(
                color: glow.withValues(alpha: 0.35 + 0.2 * breath),
                blurRadius: 8 + 4 * breath,
              ),
              Shadow(
                color: Colors.white.withValues(alpha: 0.12 + 0.1 * breath),
                blurRadius: 3 + 2 * breath,
              ),
            ],
          ),
        );
      },
    );
  }
}
