import 'package:flutter/material.dart';

import 'asset_decode_size.dart';

/// 本地资源图（含 GIF）优化加载：分桶降采样 + 缓存命中直出 + 切换无缝
class OptimizedAssetImage extends StatefulWidget {
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
    this.placeholderColor = const Color(0x00000000),
    this.showLoading = false,
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
  State<OptimizedAssetImage> createState() => _OptimizedAssetImageState();
}

class _OptimizedAssetImageState extends State<OptimizedAssetImage> {
  /// 上一张已成功绘出的画面，切换素材时先顶住，避免黑闪
  Widget? _lastGoodFrame;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);

    final resolvedWidth = widget.cacheWidth ??
        (widget.width != null
            ? AssetDecodeSize.pixels(widget.width!, dpr)
            : AssetDecodeSize.forRole(widget.role, screen, dpr));

    final provider = AssetDecodeSize.provider(
      widget.assetPath,
      cacheWidth: resolvedWidth,
      cacheHeight: widget.cacheHeight,
    );

    final alreadyCached =
        PaintingBinding.instance.imageCache.containsKey(provider);

    Widget image = Image(
      image: provider,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      alignment: widget.alignment,
      gaplessPlayback: true,
      filterQuality: FilterQuality.low,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        final ready =
            alreadyCached || wasSynchronouslyLoaded || frame != null;
        if (ready) {
          _lastGoodFrame = child;
          return child;
        }
        // 新图未就绪：继续显示上一帧，绝不落深色底
        if (_lastGoodFrame != null) {
          return _lastGoodFrame!;
        }
        if (!widget.showLoading) {
          return ColoredBox(color: widget.placeholderColor);
        }
        return ColoredBox(
          color: widget.placeholderColor,
          child: const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
      errorBuilder: widget.errorBuilder ??
          (context, error, stackTrace) {
            if (_lastGoodFrame != null) return _lastGoodFrame!;
            return ColoredBox(color: widget.placeholderColor);
          },
    );

    if (widget.width == null && widget.height == null) {
      image = SizedBox.expand(child: image);
    }

    if (widget.borderRadius != null) {
      return ClipRRect(borderRadius: widget.borderRadius!, child: image);
    }
    return image;
  }
}
