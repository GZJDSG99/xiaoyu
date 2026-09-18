import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../data/models/expression.dart';

class QuickExpressionRow extends StatelessWidget {
  const QuickExpressionRow({
    super.key,
    required this.expressions,
    required this.onSelected,
    this.onMore,
    this.large = false,
    this.dense = false,
    this.expandToFit = false,
  });

  final List<Expression> expressions;
  final ValueChanged<Expression> onSelected;
  final VoidCallback? onMore;
  final bool large;
  final bool dense;

  /// 横屏时均分宽度，避免横向滚动占高度
  final bool expandToFit;

  @override
  Widget build(BuildContext context) {
    final size = dense ? 56.0 : (large ? 72.0 : 64.0);
    final items = <_QuickItem>[
      ...expressions.map(
        (e) => _QuickItem(
          emoji: e.emoji,
          label: e.title,
          onTap: () => onSelected(e),
        ),
      ),
      if (onMore != null)
        _QuickItem(
          emoji: '⋯',
          label: '更多',
          onTap: onMore!,
        ),
    ];

    if (expandToFit) {
      return SizedBox(
        height: size,
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) SizedBox(width: dense ? 6 : 8),
              Expanded(
                child: _QuickChip(
                  emoji: items[i].emoji,
                  label: items[i].label,
                  size: size,
                  onTap: items[i].onTap,
                  expand: true,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 16,
        vertical: dense ? 4 : 12,
      ),
      child: Row(
        children: [
          for (final item in items)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: dense ? 4 : 6),
              child: _QuickChip(
                emoji: item.emoji,
                label: item.label,
                size: size,
                onTap: item.onTap,
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickItem {
  const _QuickItem({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final VoidCallback onTap;
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.emoji,
    required this.label,
    required this.size,
    required this.onTap,
    this.expand = false,
  });

  final String emoji;
  final String label;
  final double size;
  final VoidCallback onTap;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceSecondary,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: expand ? null : size + 16,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: TextStyle(fontSize: size * 0.32)),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTextStyles.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
