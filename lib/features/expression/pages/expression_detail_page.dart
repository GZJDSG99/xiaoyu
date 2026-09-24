import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_text_styles.dart';
import '../../../core/images/optimized_asset_image.dart';
import '../../../data/repositories/expression_repository.dart';
import '../../../data/repositories/pet_repository.dart';
import '../../../domain/services/expression_playback.dart';
import '../../pet/widgets/pet_avatar.dart';
import '../widgets/expression_icon.dart';

class ExpressionDetailPage extends ConsumerWidget {
  const ExpressionDetailPage({super.key, required this.expressionId});

  final String expressionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expression =
        ref.watch(expressionRepositoryProvider).getById(expressionId);

    if (expression == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('表情详情')),
        body: const Center(child: Text('表情不存在')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(expression.title)),
      body: FutureBuilder(
        future: ref.watch(petRepositoryProvider).getCurrent(),
        builder: (context, snapshot) {
          final pet = snapshot.data ??
              ref.read(petRepositoryProvider).getById('cat');
          final actionAsset =
              pet?.resolveAsset(action: expression.petAction);

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (expression.hasStickerAsset)
                          SizedBox(
                            height: 200,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.asset(
                                expression.iconAsset!,
                                fit: BoxFit.contain,
                              ),
                            ),
                          )
                        else if (actionAsset != null)
                          SizedBox(
                            height: 160,
                            child: OptimizedAssetImage(
                              key: ValueKey(actionAsset),
                              assetPath: actionAsset,
                              fit: BoxFit.contain,
                              borderRadius: BorderRadius.circular(16),
                            ),
                          )
                        else ...[
                          PetAvatar(
                            pet: pet,
                            action: expression.petAction,
                            size: 120,
                            borderRadius: 16,
                          ),
                          const SizedBox(height: 12),
                          ExpressionIcon(
                            emoji: expression.emoji,
                            iconAsset: expression.iconAsset,
                            size: 48,
                          ),
                        ],
                        const SizedBox(height: 16),
                        Text(expression.title, style: AppTextStyles.headline),
                        if (expression.subtitle != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            expression.subtitle!,
                            style: AppTextStyles.bodySecondary,
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: () => playExpressionFullscreen(
                        context: context,
                        ref: ref,
                        expression: expression,
                      ),
                      child: const Text('全屏显示'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
