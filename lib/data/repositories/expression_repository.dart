import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local/local_storage.dart';
import '../models/category.dart';
import '../models/custom_expression.dart';
import '../models/expression.dart';
import '../models/pet_enums.dart';

/// V1.0 内置表情（后续可迁到 JSON / 远程）
const kDefaultCategories = <Category>[
  Category(id: 'polite', name: '礼貌沟通', icon: '🙏', sortOrder: 0),
  Category(id: 'driving', name: '行车表达', icon: '🚗', sortOrder: 1),
  Category(id: 'funny', name: '搞怪有趣', icon: '😂', sortOrder: 2),
  Category(id: 'festival', name: '节日', icon: '🎉', sortOrder: 3),
  Category(id: 'social', name: '情侣/朋友', icon: '❤️', sortOrder: 4),
  Category(id: 'custom', name: '自定义', icon: '✨', sortOrder: 5),
];

const kDefaultExpressions = <Expression>[
  Expression(
    id: 'thank_you',
    categoryId: 'polite',
    emoji: '👍',
    title: '谢谢',
    subtitle: '谢谢啦！',
    petAction: PetAction.thank,
    animation: DisplayAnimation.fade,
    duration: Duration(seconds: 5),
    iconAsset: 'assets/icons/good.svg',
  ),
  Expression(
    id: 'sorry',
    categoryId: 'polite',
    emoji: '🙇',
    title: '抱歉',
    petAction: PetAction.sorry,
    animation: DisplayAnimation.fade,
    duration: Duration(seconds: 5),
  ),
  Expression(
    id: 'receive',
    categoryId: 'polite',
    emoji: '👍',
    title: '收到',
    petAction: PetAction.receive,
    animation: DisplayAnimation.scale,
    duration: Duration(seconds: 4),
  ),
  Expression(
    id: 'goodbye',
    categoryId: 'polite',
    emoji: '👋',
    title: '再见',
    petAction: PetAction.goodbye,
    animation: DisplayAnimation.slide,
    duration: Duration(seconds: 4),
    iconAsset: 'assets/icons/byb.svg',
  ),
  Expression(
    id: 'love_you',
    categoryId: 'social',
    emoji: '❤️',
    title: '爱你',
    petAction: PetAction.love,
    animation: DisplayAnimation.scale,
    duration: Duration(seconds: 5),
    iconAsset: 'assets/icons/heart.svg',
  ),
  Expression(
    id: 'driving',
    categoryId: 'driving',
    emoji: '🚗',
    title: '行车',
    subtitle: '注意行车安全',
    petAction: PetAction.warning,
    animation: DisplayAnimation.pulse,
    duration: Duration(seconds: 6),
    iconAsset: 'assets/icons/car.svg',
  ),
  Expression(
    id: 'hug',
    categoryId: 'social',
    emoji: '🤗',
    title: '拥抱',
    subtitle: '给你一个抱抱',
    petAction: PetAction.love,
    animation: DisplayAnimation.scale,
    duration: Duration(seconds: 5),
  ),
  Expression(
    id: 'merge',
    categoryId: 'driving',
    emoji: '➡️',
    title: '我要并线',
    petAction: PetAction.warning,
    animation: DisplayAnimation.pulse,
    duration: Duration(seconds: 6),
  ),
  Expression(
    id: 'newbie',
    categoryId: 'driving',
    emoji: '🐢',
    title: '新手上路',
    petAction: PetAction.custom,
    animation: DisplayAnimation.breath,
    duration: Duration(seconds: 8),
  ),
  Expression(
    id: 'hahaha',
    categoryId: 'funny',
    emoji: '😂',
    title: '哈哈哈',
    petAction: PetAction.laugh,
    animation: DisplayAnimation.bounce,
    duration: Duration(seconds: 4),
    iconAsset: 'assets/icons/happy.svg',
  ),
  Expression(
    id: 'good_night',
    categoryId: 'polite',
    emoji: '🌙',
    title: '晚安',
    subtitle: '晚安，好梦～',
    petAction: PetAction.sleep,
    animation: DisplayAnimation.breath,
    duration: Duration(seconds: 6),
  ),
  Expression(
    id: 'happy_festival',
    categoryId: 'festival',
    emoji: '🎉',
    title: '节日快乐',
    petAction: PetAction.encourage,
    animation: DisplayAnimation.bounce,
    duration: Duration(seconds: 6),
  ),
];

/// 首页快捷栏固定顺序（设计稿）
const kHomeDockExpressionIds = <String>[
  'thank_you',
  'goodbye',
  'love_you',
  'driving',
  'hahaha',
];

abstract class ExpressionRepository {
  List<Category> getCategories();
  List<Expression> getAll();
  List<Expression> getByCategory(String categoryId);
  Expression? getById(String id);
  List<Expression> getRecent();
  List<Expression> getFavorites();
  Future<void> addRecent(String expressionId);
  Future<void> toggleFavorite(String expressionId);
  List<CustomExpression> getCustom();
  Future<void> saveCustom(CustomExpression expression);
}

class LocalExpressionRepository implements ExpressionRepository {
  LocalExpressionRepository(this._storage);

  final LocalStorage _storage;

  @override
  List<Category> getCategories() => kDefaultCategories;

  @override
  List<Expression> getAll() => kDefaultExpressions;

  @override
  List<Expression> getByCategory(String categoryId) {
    return kDefaultExpressions.where((e) => e.categoryId == categoryId).toList();
  }

  @override
  Expression? getById(String id) {
    try {
      return kDefaultExpressions.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  List<Expression> getRecent() {
    final ids = _storage.recentExpressions;
    return ids.map(getById).whereType<Expression>().toList();
  }

  @override
  List<Expression> getFavorites() {
    final ids = _storage.favoriteExpressions;
    return ids.map(getById).whereType<Expression>().toList();
  }

  @override
  Future<void> addRecent(String expressionId) async {
    final list = [..._storage.recentExpressions]
      ..remove(expressionId)
      ..insert(0, expressionId);
    await _storage.setRecentExpressions(list.take(20).toList());
  }

  @override
  Future<void> toggleFavorite(String expressionId) async {
    final list = [..._storage.favoriteExpressions];
    if (list.contains(expressionId)) {
      list.remove(expressionId);
    } else {
      list.add(expressionId);
    }
    await _storage.setFavoriteExpressions(list);
  }

  @override
  List<CustomExpression> getCustom() {
    return _storage.customExpressions
        .map(CustomExpression.fromJson)
        .toList();
  }

  @override
  Future<void> saveCustom(CustomExpression expression) async {
    final items = [
      ..._storage.customExpressions.map((e) => Map<String, dynamic>.from(e)),
    ]..removeWhere((e) => e['id'] == expression.id);
    items.insert(0, expression.toJson());
    await _storage.setCustomExpressions(items);
  }
}

final expressionRepositoryProvider = Provider<ExpressionRepository>((ref) {
  return LocalExpressionRepository(ref.watch(localStorageProvider));
});
