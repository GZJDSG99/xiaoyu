import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../data/models/custom_expression.dart';
import '../../../data/models/expression.dart';
import '../../../data/repositories/expression_repository.dart';
import '../../../domain/services/expression_playback.dart';
import '../../../domain/services/expression_service.dart';
import '../../diy/widgets/diy_sticker_image.dart';
import '../widgets/expression_icon.dart';

class ExpressionCategoryPage extends ConsumerWidget {
  const ExpressionCategoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(expressionRepositoryProvider);
    ref.watch(customExpressionsTickProvider);
    final categories = repo.getCategories();
    final customs = repo.getCustom();

    return Scaffold(
      appBar: AppBar(title: const Text('表情')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isCustom = category.id == 'custom';

          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${category.icon ?? ''} ${category.name}',
                  style: AppTextStyles.title,
                ),
                const SizedBox(height: 12),
                if (isCustom)
                  _CustomSection(customs: customs)
                else
                  _BuiltinSection(
                    expressions: repo.getByCategory(category.id),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BuiltinSection extends ConsumerWidget {
  const _BuiltinSection({required this.expressions});

  final List<Expression> expressions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (expressions.isEmpty) {
      return Text('暂无表情', style: AppTextStyles.bodySecondary);
    }
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: expressions.map<Widget>((e) {
        return Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => playExpressionFullscreen(
              context: context,
              ref: ref,
              expression: e,
            ),
            child: SizedBox(
              width: 100,
              height: 76,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ExpressionIcon(
                      emoji: e.emoji,
                      iconAsset: e.iconAsset,
                      size: e.hasStickerAsset ? 36 : 28,
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        e.title,
                        style: AppTextStyles.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CustomSection extends ConsumerWidget {
  const _CustomSection({required this.customs});

  final List<CustomExpression> customs;

  Future<void> _play(BuildContext context, WidgetRef ref, CustomExpression e) async {
    await playCustomFullscreen(
      context: context,
      ref: ref,
      expression: e,
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    CustomExpression e,
  ) async {
    final label = e.text.isEmpty ? '这条自定义表情' : '「${e.text}」';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除自定义'),
        content: Text('确定删除$label吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await ref.read(expressionServiceProvider).deleteCustom(e.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已删除'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (customs.isEmpty) {
      return Text(
        '暂无自定义，可在 DIY 中制作后添加',
        style: AppTextStyles.bodySecondary,
      );
    }
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: customs.map((e) {
        final label = e.text.isEmpty ? '自定义' : e.text;
        return Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _play(context, ref, e),
            child: SizedBox(
              width: 100,
              height: 76,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 36,
                            height: 36,
                            child: e.hasImage
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: DiyStickerImage.fromExpression(
                                      e,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Text(
                                    e.emoji,
                                    style: const TextStyle(fontSize: 28),
                                  ),
                          ),
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              label,
                              style: AppTextStyles.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        tooltip: '删除',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        iconSize: 16,
                        color: AppColors.textSecondary,
                        onPressed: () => _confirmDelete(context, ref, e),
                        icon: const Icon(Icons.close),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
