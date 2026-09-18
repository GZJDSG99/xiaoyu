import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../data/repositories/expression_repository.dart';
import '../../../domain/services/expression_playback.dart';
import '../widgets/expression_icon.dart';

class ExpressionCategoryPage extends ConsumerWidget {
  const ExpressionCategoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(expressionRepositoryProvider);
    final categories = repo.getCategories();

    return Scaffold(
      appBar: AppBar(title: const Text('表情')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final expressions = repo.getByCategory(category.id);

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
                if (expressions.isEmpty)
                  Text('暂无表情（框架占位）', style: AppTextStyles.bodySecondary)
                else
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: expressions.map((e) {
                      return Material(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          // 与首页一致：点击直接全屏播放对应宠物 GIF
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
                                    size: 28,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(e.title, style: AppTextStyles.caption),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
