import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 展示角色：同一角色使用同一解码分桶，保证 ImageCache 命中
enum AssetDisplayRole {
  /// 首页全屏背景
  background,

  /// 宠物待机 / 全屏动作
  pet,

  /// 选宠卡片、背景缩略图等
  thumb,
}

/// 根据逻辑像素与设备像素比，计算合适的解码尺寸（避免 GIF 原图像素全量解码）
abstract final class AssetDecodeSize {
  static const int minPx = 64;
  static const int maxPx = 1280;

  /// 固定分桶，避免 Layout 微小差异导致缓存键不一致
  static const List<int> buckets = <int>[256, 384, 512, 640, 768, 960, 1280];

  static int pixels(double logical, double devicePixelRatio) {
    final value = (logical * devicePixelRatio).round();
    return bucket(value.clamp(minPx, maxPx));
  }

  static int bucket(int px) {
    for (final b in buckets) {
      if (px <= b) return b;
    }
    return buckets.last;
  }

  /// 取宽高中较大边作为解码边长（适合 contain）
  static int fromBox(Size logicalSize, double devicePixelRatio) {
    final side = math.max(logicalSize.width, logicalSize.height);
    if (!side.isFinite || side <= 0) {
      return pixels(320, devicePixelRatio);
    }
    return pixels(side, devicePixelRatio);
  }

  static int forRole(
    AssetDisplayRole role,
    Size screenSize,
    double devicePixelRatio,
  ) {
    return switch (role) {
      AssetDisplayRole.background => pixels(screenSize.width, devicePixelRatio),
      AssetDisplayRole.pet => fromBox(
          Size(screenSize.shortestSide * 0.85, screenSize.shortestSide * 0.85),
          devicePixelRatio,
        ),
      AssetDisplayRole.thumb => 384,
    };
  }

  static ImageProvider provider(
    String assetPath, {
    int? cacheWidth,
    int? cacheHeight,
  }) {
    return GifProviderCache.instance.obtain(
      assetPath,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );
  }

  static ImageProvider providerForRole(
    String assetPath,
    AssetDisplayRole role,
    BuildContext context,
  ) {
    final size = MediaQuery.sizeOf(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final side = forRole(role, size, dpr);
    return provider(assetPath, cacheWidth: side);
  }
}

/// 复用同一 ImageProvider 实例，稳定命中 ImageCache
class GifProviderCache {
  GifProviderCache._();
  static final GifProviderCache instance = GifProviderCache._();

  final Map<String, ImageProvider> _providers = <String, ImageProvider>{};

  ImageProvider obtain(
    String assetPath, {
    int? cacheWidth,
    int? cacheHeight,
  }) {
    final key = '$assetPath#${cacheWidth ?? 0}x${cacheHeight ?? 0}';
    return _providers.putIfAbsent(key, () {
      final base = AssetImage(assetPath);
      if (cacheWidth == null && cacheHeight == null) return base;
      return ResizeImage(
        base,
        width: cacheWidth,
        height: cacheHeight,
        policy: ResizeImagePolicy.fit,
        allowUpscaling: false,
      );
    });
  }

  bool isCached(
    String assetPath, {
    int? cacheWidth,
    int? cacheHeight,
  }) {
    final provider = obtain(
      assetPath,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );
    return PaintingBinding.instance.imageCache.containsKey(provider);
  }

  bool isCachedForRole(
    String assetPath,
    AssetDisplayRole role,
    BuildContext context,
  ) {
    final size = MediaQuery.sizeOf(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final side = AssetDecodeSize.forRole(role, size, dpr);
    return isCached(assetPath, cacheWidth: side);
  }
}
