import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 表情图标：优先 iconAsset（支持 svg/png），否则 emoji
class ExpressionIcon extends StatelessWidget {
  const ExpressionIcon({
    super.key,
    required this.emoji,
    this.iconAsset,
    this.size = 24,
  });

  final String emoji;
  final String? iconAsset;
  final double size;

  @override
  Widget build(BuildContext context) {
    final asset = iconAsset;
    Widget child;
    if (asset == null || asset.isEmpty) {
      child = Text(
        emoji,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: size * 0.85, height: 1),
      );
    } else {
      final lower = asset.toLowerCase();
      if (lower.endsWith('.svg')) {
        child = SvgPicture.asset(
          asset,
          width: size,
          height: size,
          fit: BoxFit.contain,
          alignment: Alignment.center,
          placeholderBuilder: (_) => Text(
            emoji,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: size * 0.85, height: 1),
          ),
        );
      } else {
        child = Image.asset(
          asset,
          width: size,
          height: size,
          fit: BoxFit.contain,
          alignment: Alignment.center,
          errorBuilder: (context, error, stackTrace) {
            return Text(
              emoji,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: size * 0.85, height: 1),
            );
          },
        );
      }
    }

    return SizedBox(
      width: size,
      height: size,
      child: Center(child: child),
    );
  }
}
