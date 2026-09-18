import 'package:flutter/painting.dart';

/// 控制图片缓存容量，适配多 GIF 场景（配合降采样解码）
abstract final class ImageCacheConfig {
  static void apply() {
    final cache = PaintingBinding.instance.imageCache;
    // 背景 + 待机 + 动作 + 缩略图，尽量留住已解码 GIF
    cache.maximumSize = 80;
    // 约 200MB，减少“加载过又被挤出缓存”
    cache.maximumSizeBytes = 200 << 20;
  }
}
