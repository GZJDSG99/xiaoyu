/// 路由路径常量
abstract final class AppRoutes {
  static const home = '/';
  static const expressions = '/expressions';
  static const diy = '/diy';
  static const danmaku = '/danmaku';
  static const mine = '/mine';
  static const petSelect = '/pet-select';
  static const display = '/display';
  static const backgrounds = '/backgrounds';
}

/// 本地存储 key
abstract final class StorageKeys {
  static const currentPetId = 'currentPetId';
  static const favoriteExpressions = 'favoriteExpressions';
  static const recentExpressions = 'recentExpressions';
  static const customExpressions = 'customExpressions';
  static const firstLaunch = 'firstLaunch';
  static const settings = 'settings';
  static const backgroundId = 'backgroundId';
  static const danmakuRecent = 'danmakuRecent';
  static const danmakuFontSize = 'danmakuFontSize';
  static const danmakuColor = 'danmakuColor';
  static const danmakuSpeed = 'danmakuSpeed';
  static const displayRemoteHost = 'displayRemoteHost';
  static const displayRemoteCode = 'displayRemoteCode';
}

/// Hive box 名称
abstract final class HiveBoxes {
  static const app = 'xiaoyu_app';
  static const expressions = 'xiaoyu_expressions';
}
