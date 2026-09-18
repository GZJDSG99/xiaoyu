import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';

enum SpeechBubbleTail {
  /// 尾巴朝左（气泡在宠物右侧）
  left,

  /// 尾巴朝下（气泡在宠物上方）
  bottom,

  none,
}

/// 聊天泡泡样式文案
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({
    super.key,
    required this.message,
    this.tail = SpeechBubbleTail.left,
    this.maxWidth = 200,
    this.animateMessage = false,
  });

  final String message;
  final SpeechBubbleTail tail;
  final double maxWidth;
  final bool animateMessage;

  static const _bubbleColor = Color(0xF2FFFFFF);
  static const _textColor = Color(0xFF1A2433);

  @override
  Widget build(BuildContext context) {
    final textStyle = AppTextStyles.body.copyWith(
      color: _textColor,
      fontSize: 15,
      height: 1.35,
      fontWeight: FontWeight.w500,
    );

    final content = animateMessage
        ? AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: Alignment.centerLeft,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              reverseDuration: const Duration(milliseconds: 160),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              layoutBuilder: (currentChild, previousChildren) {
                return Stack(
                  alignment: Alignment.centerLeft,
                  clipBehavior: Clip.none,
                  children: [
                    ...previousChildren,
                    if (currentChild != null) currentChild,
                  ],
                );
              },
              transitionBuilder: (child, animation) {
                final fade = CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOut,
                );
                final slide = Tween<Offset>(
                  begin: const Offset(0, 0.18),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ));
                final scale = Tween<double>(begin: 0.96, end: 1).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutBack,
                  ),
                );
                return FadeTransition(
                  opacity: fade,
                  child: SlideTransition(
                    position: slide,
                    child: ScaleTransition(
                      scale: scale,
                      alignment: Alignment.centerLeft,
                      child: child,
                    ),
                  ),
                );
              },
              child: Text(
                message,
                key: ValueKey(message),
                style: textStyle,
              ),
            ),
          )
        : Text(message, style: textStyle);

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _bubbleColor,
        borderRadius: _radiusForTail(tail),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: content,
    );

    return switch (tail) {
      SpeechBubbleTail.left => Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CustomPaint(
              size: const Size(10, 14),
              painter: const _BubbleTailPainter(
                color: _bubbleColor,
                direction: SpeechBubbleTail.left,
              ),
            ),
            bubble,
          ],
        ),
      SpeechBubbleTail.bottom => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            bubble,
            CustomPaint(
              size: const Size(14, 10),
              painter: const _BubbleTailPainter(
                color: _bubbleColor,
                direction: SpeechBubbleTail.bottom,
              ),
            ),
          ],
        ),
      SpeechBubbleTail.none => bubble,
    };
  }

  static BorderRadius _radiusForTail(SpeechBubbleTail tail) {
    return switch (tail) {
      SpeechBubbleTail.left => const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
      SpeechBubbleTail.bottom => const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(6),
        ),
      SpeechBubbleTail.none => BorderRadius.circular(18),
    };
  }
}

class _BubbleTailPainter extends CustomPainter {
  const _BubbleTailPainter({
    required this.color,
    required this.direction,
  });

  final Color color;
  final SpeechBubbleTail direction;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();

    switch (direction) {
      case SpeechBubbleTail.left:
        path
          ..moveTo(size.width, size.height * 0.2)
          ..lineTo(0, size.height * 0.5)
          ..lineTo(size.width, size.height * 0.8)
          ..close();
      case SpeechBubbleTail.bottom:
        path
          ..moveTo(size.width * 0.2, 0)
          ..lineTo(size.width * 0.5, size.height)
          ..lineTo(size.width * 0.8, 0)
          ..close();
      case SpeechBubbleTail.none:
        return;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.direction != direction;
  }
}

class HomePageDots extends StatelessWidget {
  const HomePageDots({
    super.key,
    this.count = 3,
    this.activeIndex = 0,
  });

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (index) {
        final active = index == activeIndex;
        return Container(
          width: active ? 8 : 6,
          height: active ? 8 : 6,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active
                ? AppColors.text
                : AppColors.textSecondary.withValues(alpha: 0.45),
          ),
        );
      }),
    );
  }
}
