/// 首页背景选项（资源后续可继续追加）
class HomeBackgroundOption {
  final String id;
  final String name;
  final String? assetPath;

  /// assetPath 为空时使用内置渐变占位
  const HomeBackgroundOption({
    required this.id,
    required this.name,
    this.assetPath,
  });

  bool get isAsset => assetPath != null && assetPath!.isNotEmpty;
}

const kDefaultBackgroundId = 'moon_garden';
const kStarrySkyBackgroundId = 'starry_sky';

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
    id: 'cabin',
    name: '车载氛围',
  ),
];

HomeBackgroundOption backgroundById(String? id) {
  return kHomeBackgrounds.firstWhere(
    (e) => e.id == id,
    orElse: () => kHomeBackgrounds.first,
  );
}

/// 夜间强制星空；白天用用户选择
HomeBackgroundOption effectiveBackground(
  HomeBackgroundOption selected, [
  DateTime? now,
]) {
  if (isNightHours(now)) {
    return backgroundById(kStarrySkyBackgroundId);
  }
  return selected;
}
