import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../data/models/expression.dart';
import '../../expression/widgets/expression_icon.dart';

/// 首页底部玻璃快捷栏（图标资源后续可替换）
class HomeActionDock extends StatelessWidget {
  const HomeActionDock({
    super.key,
    required this.expressions,
    required this.onSelected,
    required this.onMore,
    this.selectedId,
  });

  final List<Expression> expressions;
  final ValueChanged<Expression> onSelected;
  final VoidCallback onMore;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final items = <_DockItem>[
      ...expressions.map(
        (e) => _DockItem(
          id: e.id,
          emoji: e.emoji,
          label: e.title,
          iconAsset: e.iconAsset,
          onTap: () => onSelected(e),
        ),
      ),
      _DockItem(
        id: 'more',
        emoji: '⋯',
        label: '更多',
        onTap: onMore,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xB3121824),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            for (final item in items)
              Expanded(
                child: _DockButton(
                  item: item,
                  selected: item.id == selectedId,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DockItem {
  const _DockItem({
    required this.id,
    required this.emoji,
    required this.label,
    required this.onTap,
    this.iconAsset,
  });

  final String id;
  final String emoji;
  final String label;
  final String? iconAsset;
  final VoidCallback onTap;
}

class _DockButton extends StatelessWidget {
  const _DockButton({
    required this.item,
    required this.selected,
  });

  final _DockItem item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? AppColors.primary : Colors.transparent,
                width: 1.5,
              ),
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : Colors.transparent,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DockIcon(item: item),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: AppTextStyles.caption.copyWith(
                    color: selected ? AppColors.text : AppColors.textSecondary,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DockIcon extends StatelessWidget {
  const _DockIcon({required this.item});

  final _DockItem item;

  @override
  Widget build(BuildContext context) {
    return ExpressionIcon(
      emoji: item.emoji,
      iconAsset: item.iconAsset,
      size: 28,
    );
  }
}
