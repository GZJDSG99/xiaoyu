/// 首页背景选项（资源后续可继续追加）
class HomeBackgroundOption {
  final String id;
  final String name;
  final String? assetPath;

  /// 非空时仅该宠物可选/展示为专属背景
  final String? exclusivePetId;

  /// assetPath 为空时使用内置渐变占位
  const HomeBackgroundOption({
    required this.id,
    required this.name,
    this.assetPath,
    this.exclusivePetId,
  });

  bool get isAsset => assetPath != null && assetPath!.isNotEmpty;

  bool get isExclusive => exclusivePetId != null;

  bool isAvailableForPet(String? petId) {
    if (exclusivePetId == null) return true;
    return petId != null && petId == exclusivePetId;
  }
}

const kDefaultBackgroundId = 'grassland';
const kStarrySkyBackgroundId = 'starry_sky';
const kCoolBgBackgroundId = 'cool_bg';

/// 夜间：19:00（含）～次日 05:00（不含）
bool isNightHours([DateTime? now]) {
  final t = now ?? DateTime.now();
  return t.hour >= 19 || t.hour < 5;
}

const kHomeBackgrounds = <HomeBackgroundOption>[
  HomeBackgroundOption(
    id: 'moon_garden',
    name: '月光花园',
    assetPath: 'assets/backgrounds/mon-garden.webp',
  ),
  HomeBackgroundOption(
    id: 'grassland',
    name: '草原',
    assetPath: 'assets/backgrounds/grassland.webp',
  ),
  HomeBackgroundOption(
    id: 'oasis',
    name: '绿洲',
    assetPath: 'assets/backgrounds/Oasis.webp',
  ),
  HomeBackgroundOption(
    id: kStarrySkyBackgroundId,
    name: '星空',
    assetPath: 'assets/backgrounds/StarrySky.webp',
  ),
  HomeBackgroundOption(
    id: kCoolBgBackgroundId,
    name: '酷B舞台',
    assetPath: 'assets/backgrounds/cool-bg.webp',
    exclusivePetId: 'bear',
  ),
  HomeBackgroundOption(
    id: 'cabin',
    name: '车载氛围',
  ),
];

HomeBackgroundOption backgroundById(String? id) {
  return kHomeBackgrounds.firstWhere(
    (e) => e.id == id,
    orElse: () => kHomeBackgrounds.firstWhere(
      (e) => e.id == kDefaultBackgroundId,
    ),
  );
}

/// 夜间强制星空；白天用用户选择（专属背景需匹配当前宠物）
HomeBackgroundOption effectiveBackground(
  HomeBackgroundOption selected, [
  DateTime? now,
  String? currentPetId,
]) {
  if (isNightHours(now)) {
    return backgroundById(kStarrySkyBackgroundId);
  }
  if (!selected.isAvailableForPet(currentPetId)) {
    return backgroundById(kDefaultBackgroundId);
  }
  return selected;
}
