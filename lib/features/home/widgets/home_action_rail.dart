import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../data/models/expression.dart';
import '../../expression/widgets/expression_icon.dart';

/// 右侧可收缩快捷侧边栏
class HomeActionRail extends StatelessWidget {
  const HomeActionRail({
    super.key,
    required this.expressions,
    required this.onSelected,
    required this.onMore,
    required this.expanded,
    required this.onToggle,
    this.selectedId,
  });

  final List<Expression> expressions;
  final ValueChanged<Expression> onSelected;
  final VoidCallback onMore;
  final bool expanded;
  final VoidCallback onToggle;
  final String? selectedId;

  static const double collapsedWidth = 48;
  static const double expandedWidth = 92;

  @override
  Widget build(BuildContext context) {
    final items = <_RailItem>[
      ...expressions.map(
        (e) => _RailItem(
          id: e.id,
          emoji: e.emoji,
          label: e.title,
          iconAsset: e.iconAsset,
          onTap: () => onSelected(e),
        ),
      ),
      _RailItem(
        id: 'more',
        emoji: '⋯',
        label: '更多',
        onTap: onMore,
      ),
    ];

    final width = expanded ? expandedWidth : collapsedWidth;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: width,
      margin: const EdgeInsets.fromLTRB(0, 8, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xB3121824),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(-4, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 6),
          IconButton(
            tooltip: expanded ? '收起' : '展开',
            onPressed: onToggle,
            visualDensity: VisualDensity.compact,
            icon: Icon(
              expanded ? Icons.chevron_right : Icons.chevron_left,
              color: AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                scrollbars: false,
              ),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(6, 4, 6, 10),
                itemCount: items.length,
                separatorBuilder: (context, index) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _RailButton(
                    item: item,
                    expanded: expanded,
                    selected: item.id == selectedId,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RailItem {
  const _RailItem({
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

class _RailButton extends StatelessWidget {
  const _RailButton({
    required this.item,
    required this.expanded,
    required this.selected,
  });

  final _RailItem item;
  final bool expanded;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            vertical: expanded ? 8 : 10,
            horizontal: 4,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
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
              _RailIcon(item: item),
              if (expanded) ...[
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
            ],
          ),
        ),
      ),
    );
  }
}

class _RailIcon extends StatelessWidget {
  const _RailIcon({required this.item});

  final _RailItem item;

  @override
  Widget build(BuildContext context) {
    return ExpressionIcon(
      emoji: item.emoji,
      iconAsset: item.iconAsset,
      size: 26,
    );
  }
}
