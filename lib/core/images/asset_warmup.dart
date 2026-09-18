import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'asset_decode_size.dart';

/// 预热关键 GIF：与展示端使用同一分桶尺寸 / 同一 ImageProvider，确保二次直读缓存
abstract final class AssetWarmup {
  static final Set<String> _warmed = <String>{};

  static String _key(String assetPath, int? cacheWidth, int? cacheHeight) =>
      '$assetPath#${cacheWidth ?? 0}x${cacheHeight ?? 0}';

  static Future<void> precache(
    BuildContext context,
    String assetPath, {
    int? cacheWidth,
    int? cacheHeight,
  }) async {
    if (!context.mounted) return;
    final provider = AssetDecodeSize.provider(
      assetPath,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );
    final key = _key(assetPath, cacheWidth, cacheHeight);

    // 已在 Flutter ImageCache 中：标记并跳过
    if (PaintingBinding.instance.imageCache.containsKey(provider)) {
      _warmed.add(key);
      return;
    }
    if (_warmed.contains(key)) return;

    try {
      await precacheImage(provider, context);
      _warmed.add(key);
    } catch (_) {
      // 预热失败不阻断主流程
    }
  }

  static Future<void> precacheRole(
    BuildContext context,
    String assetPath,
    AssetDisplayRole role,
  ) async {
    if (!context.mounted) return;
    final size = MediaQuery.sizeOf(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final side = AssetDecodeSize.forRole(role, size, dpr);
    await precache(context, assetPath, cacheWidth: side);
  }

  /// 首页首屏：背景 + 待机宠物
  static Future<void> warmHome(
    BuildContext context, {
    String? backgroundAsset,
    String? idlePetAsset,
  }) async {
    if (!context.mounted) return;
    await Future.wait([
      if (backgroundAsset != null)
        precacheRole(context, backgroundAsset, AssetDisplayRole.background),
      if (idlePetAsset != null)
        precacheRole(context, idlePetAsset, AssetDisplayRole.pet),
    ]);
  }

  /// 点击表情后、进全屏前预热动作 GIF（与全屏 Pet 同尺寸）
  static Future<void> warmAction(
    BuildContext context,
    String assetPath,
  ) async {
    await precacheRole(context, assetPath, AssetDisplayRole.pet);
  }

  /// 空闲时再预热其余动作素材（不阻塞首屏）
  static void warmActionsInIdle(
    BuildContext context,
    Iterable<String> assetPaths,
  ) {
    SchedulerBinding.instance.scheduleTask(() async {
      if (!context.mounted) return;
      for (final path in assetPaths) {
        if (!context.mounted) return;
        await precacheRole(context, path, AssetDisplayRole.pet);
      }
    }, Priority.idle);
  }
}
