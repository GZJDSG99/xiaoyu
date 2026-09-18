import 'package:flutter/material.dart';

import 'asset_decode_size.dart';

/// 本地资源图（含 GIF）优化加载：分桶降采样 + 缓存命中直出 + 切换无缝
class OptimizedAssetImage extends StatelessWidget {
  const OptimizedAssetImage({
    super.key,
    required this.assetPath,
    this.role = AssetDisplayRole.pet,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.width,
    this.height,
    this.cacheWidth,
    this.cacheHeight,
    this.borderRadius,
    this.placeholderColor = const Color(0xFF101C2B),
    this.showLoading = true,
    this.errorBuilder,
  });

  final String assetPath;
  final AssetDisplayRole role;
  final BoxFit fit;
  final Alignment alignment;
  final double? width;
  final double? height;
  final int? cacheWidth;
  final int? cacheHeight;
  final BorderRadius? borderRadius;
  final Color placeholderColor;
  final bool showLoading;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);

    final resolvedWidth = cacheWidth ??
        (width != null
            ? AssetDecodeSize.pixels(width!, dpr)
            : AssetDecodeSize.forRole(role, screen, dpr));

    final provider = AssetDecodeSize.provider(
      assetPath,
      cacheWidth: resolvedWidth,
      cacheHeight: cacheHeight,
    );

    final alreadyCached =
        PaintingBinding.instance.imageCache.containsKey(provider);

    Widget image = Image(
      image: provider,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      gaplessPlayback: true,
      filterQuality: FilterQuality.low,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        // 已在 ImageCache / 同步解码：直接展示，不再走 loading
        if (alreadyCached || wasSynchronouslyLoaded || frame != null) {
          return child;
        }
        return ColoredBox(
          color: placeholderColor,
          child: showLoading
              ? const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : null,
        );
      },
      errorBuilder: errorBuilder ??
          (context, error, stackTrace) => ColoredBox(color: placeholderColor),
    );

    if (width == null && height == null) {
      image = SizedBox.expand(child: image);
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }
}
