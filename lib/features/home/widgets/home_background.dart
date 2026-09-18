import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/images/asset_decode_size.dart';
import '../../../core/images/optimized_asset_image.dart';

/// 首页全屏背景：有资源用图，否则用车载氛围渐变占位
class HomeBackground extends StatelessWidget {
  const HomeBackground({
    super.key,
    this.assetPath,
  });

  final String? assetPath;

  @override
  Widget build(BuildContext context) {
    if (assetPath == null || assetPath!.isEmpty) {
      return const Positioned.fill(child: _PlaceholderBg());
    }

    return Positioned.fill(
      child: OptimizedAssetImage(
        assetPath: assetPath!,
        role: AssetDisplayRole.background,
        fit: BoxFit.cover,
        showLoading: false,
        placeholderColor: AppColors.background,
        errorBuilder: (context, error, stackTrace) => const _PlaceholderBg(),
      ),
    );
  }
}

class _PlaceholderBg extends StatelessWidget {
  const _PlaceholderBg();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF4A3424),
            Color(0xFF2A1E18),
            Color(0xFF10141C),
            AppColors.background,
          ],
          stops: [0.0, 0.35, 0.7, 1.0],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: const Alignment(0, -0.55),
            child: Container(
              height: 120,
              margin: const EdgeInsets.symmetric(horizontal: 48),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0x66FFB067),
                    const Color(0x22FF8A3D),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.55),
                    Colors.black.withValues(alpha: 0.82),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
