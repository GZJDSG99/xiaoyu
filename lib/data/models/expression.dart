import 'pet_enums.dart';

class Expression {
  final String id;
  final String categoryId;
  final String emoji;
  final String title;
  final String? subtitle;
  final PetAction petAction;
  final DisplayAnimation animation;
  final Duration duration;
  final bool favorite;

  /// 快捷栏图标资源（后续替换；为空则用 emoji）
  final String? iconAsset;

  const Expression({
    required this.id,
    required this.categoryId,
    required this.emoji,
    required this.title,
    this.subtitle,
    required this.petAction,
    required this.animation,
    required this.duration,
    this.favorite = false,
    this.iconAsset,
  });

  /// 光栅图表情包（jpg/png/webp 等）：列表缩略图 + 全屏主视觉
  bool get hasStickerAsset {
    final a = iconAsset?.toLowerCase();
    if (a == null || a.isEmpty) return false;
    return a.endsWith('.jpg') ||
        a.endsWith('.jpeg') ||
        a.endsWith('.png') ||
        a.endsWith('.webp') ||
        a.endsWith('.gif');
  }

  Expression copyWith({
    String? id,
    String? categoryId,
    String? emoji,
    String? title,
    String? subtitle,
    PetAction? petAction,
    DisplayAnimation? animation,
    Duration? duration,
    bool? favorite,
    String? iconAsset,
  }) {
    return Expression(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      emoji: emoji ?? this.emoji,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      petAction: petAction ?? this.petAction,
      animation: animation ?? this.animation,
      duration: duration ?? this.duration,
      favorite: favorite ?? this.favorite,
      iconAsset: iconAsset ?? this.iconAsset,
    );
  }
}
