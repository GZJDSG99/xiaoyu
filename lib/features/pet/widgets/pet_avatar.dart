import 'package:flutter/material.dart';

import '../../../core/images/asset_decode_size.dart';
import '../../../core/images/optimized_asset_image.dart';
import '../../../data/models/pet.dart';
import '../../../data/models/pet_enums.dart';

/// 统一宠物形象：有素材用 GIF/图，否则回退 emoji
class PetAvatar extends StatelessWidget {
  const PetAvatar({
    super.key,
    required this.pet,
    this.action,
    this.size,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.borderRadius = 12,
    this.useCard = false,
  });

  final Pet? pet;
  final PetAction? action;

  /// 为 null 时铺满父布局
  final double? size;
  final BoxFit fit;
  final Alignment alignment;
  final double borderRadius;

  /// 选宠页使用卡片素材
  final bool useCard;

  @override
  Widget build(BuildContext context) {
    final emojiSize = (size ?? 72) * 0.7;
    final fallback = Text(
      pet?.emoji ?? '🐱',
      style: TextStyle(fontSize: emojiSize),
    );

    final asset = pet?.resolveAsset(action: action, preferCard: useCard);
    if (asset == null) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(child: fallback),
      );
    }

    // 小图标（设置页/列表）不显示 loading，减少闪烁
    final compact = size != null && size! <= 64;

    return OptimizedAssetImage(
      assetPath: asset,
      role: useCard ? AssetDisplayRole.thumb : AssetDisplayRole.pet,
      width: size,
      height: size,
      fit: fit,
      alignment: alignment,
      borderRadius: BorderRadius.circular(borderRadius),
      showLoading: !compact,
      errorBuilder: (context, error, stackTrace) => Center(child: fallback),
    );
  }
}
