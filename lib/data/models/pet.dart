import 'pet_enums.dart';

class Pet {
  final String id;
  final String name;
  final String personality;
  final String emoji;
  final List<String> recommendedEmotions;

  /// 首页待机素材
  final String? assetPath;

  /// 选宠卡片素材（可与待机不同）
  final String? cardAssetPath;

  /// 表情动作对应素材，例如再见 → bye 动画
  final Map<PetAction, String> actionAssets;

  /// 双击待机触发的跳跃素材
  final String? jumpAssetPath;

  /// 星空/夜间待机素材
  final String? sleepAssetPath;

  /// 变身过渡动画（播放一次）
  final String? transformAssetPath;

  /// 变身后待机素材
  final String? transformedIdleAssetPath;

  /// 是否可选（未出设计的宠物为 false，展示「待领养」）
  final bool available;

  const Pet({
    required this.id,
    required this.name,
    required this.personality,
    required this.emoji,
    this.recommendedEmotions = const [],
    this.assetPath,
    this.cardAssetPath,
    this.actionAssets = const {},
    this.jumpAssetPath,
    this.sleepAssetPath,
    this.transformAssetPath,
    this.transformedIdleAssetPath,
    this.available = true,
  });

  bool get canTransform =>
      transformAssetPath != null &&
      _isImageAsset(transformAssetPath!) &&
      transformedIdleAssetPath != null &&
      _isImageAsset(transformedIdleAssetPath!);

  /// 解析展示用图片：动作 > 睡眠回退 > 卡片(可选) > 待机
  String? resolveAsset({PetAction? action, bool preferCard = false}) {
    if (action != null) {
      final actionAsset = actionAssets[action];
      if (actionAsset != null && actionAsset.isNotEmpty) {
        return actionAsset;
      }
      // 晚安等睡眠动作：actionAssets 未配置时回退 sleepAssetPath
      if (action == PetAction.sleep &&
          sleepAssetPath != null &&
          _isImageAsset(sleepAssetPath!)) {
        return sleepAssetPath;
      }
    }
    if (preferCard &&
        cardAssetPath != null &&
        _isImageAsset(cardAssetPath!)) {
      return cardAssetPath;
    }
    if (assetPath != null && _isImageAsset(assetPath!)) {
      return assetPath;
    }
    if (cardAssetPath != null && _isImageAsset(cardAssetPath!)) {
      return cardAssetPath;
    }
    return null;
  }

  /// 全部可预热素材
  List<String> get allImageAssets {
    final list = <String>[];
    if (assetPath != null && _isImageAsset(assetPath!)) list.add(assetPath!);
    if (sleepAssetPath != null && _isImageAsset(sleepAssetPath!)) {
      list.add(sleepAssetPath!);
    }
    if (transformAssetPath != null && _isImageAsset(transformAssetPath!)) {
      list.add(transformAssetPath!);
    }
    if (transformedIdleAssetPath != null &&
        _isImageAsset(transformedIdleAssetPath!)) {
      list.add(transformedIdleAssetPath!);
    }
    if (cardAssetPath != null && _isImageAsset(cardAssetPath!)) {
      list.add(cardAssetPath!);
    }
    for (final path in actionAssets.values) {
      if (_isImageAsset(path)) list.add(path);
    }
    if (jumpAssetPath != null && _isImageAsset(jumpAssetPath!)) {
      list.add(jumpAssetPath!);
    }
    return list;
  }

  static bool _isImageAsset(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.gif') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg');
  }

  Pet copyWith({
    String? id,
    String? name,
    String? personality,
    String? emoji,
    List<String>? recommendedEmotions,
    String? assetPath,
    String? cardAssetPath,
    Map<PetAction, String>? actionAssets,
    String? jumpAssetPath,
    String? sleepAssetPath,
    String? transformAssetPath,
    String? transformedIdleAssetPath,
    bool? available,
  }) {
    return Pet(
      id: id ?? this.id,
      name: name ?? this.name,
      personality: personality ?? this.personality,
      emoji: emoji ?? this.emoji,
      recommendedEmotions: recommendedEmotions ?? this.recommendedEmotions,
      assetPath: assetPath ?? this.assetPath,
      cardAssetPath: cardAssetPath ?? this.cardAssetPath,
      actionAssets: actionAssets ?? this.actionAssets,
      jumpAssetPath: jumpAssetPath ?? this.jumpAssetPath,
      sleepAssetPath: sleepAssetPath ?? this.sleepAssetPath,
      transformAssetPath: transformAssetPath ?? this.transformAssetPath,
      transformedIdleAssetPath:
          transformedIdleAssetPath ?? this.transformedIdleAssetPath,
      available: available ?? this.available,
    );
  }

  /// 星空背景下用睡眠待机，否则用默认待机
  Pet withIdleForBackground({required bool starrySky}) {
    if (!starrySky) return this;
    final sleep = sleepAssetPath;
    if (sleep == null || !_isImageAsset(sleep)) return this;
    return copyWith(assetPath: sleep);
  }
}

/// PetAction → PetState 默认映射
PetState petStateForAction(PetAction action) {
  return switch (action) {
    PetAction.thank => PetState.happy,
    PetAction.receive => PetState.greeting,
    PetAction.goodbye => PetState.greeting,
    PetAction.love => PetState.love,
    PetAction.sorry => PetState.sorry,
    PetAction.warning => PetState.excited,
    PetAction.encourage => PetState.excited,
    PetAction.laugh => PetState.laughing,
    PetAction.sleep => PetState.sleepy,
    PetAction.custom => PetState.happy,
  };
}
