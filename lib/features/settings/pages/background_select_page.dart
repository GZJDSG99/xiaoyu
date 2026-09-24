import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/images/asset_decode_size.dart';
import '../../../core/images/asset_warmup.dart';
import '../../../core/images/optimized_asset_image.dart';
import '../../../data/models/home_background.dart';
import '../../home/providers/background_provider.dart';
import '../../pet/providers/current_pet_provider.dart';

class BackgroundSelectPage extends ConsumerWidget {
  const BackgroundSelectPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(backgroundProvider);
    final pet = ref.watch(currentPetProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('切换背景')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.35,
        ),
        itemCount: kHomeBackgrounds.length,
        itemBuilder: (context, index) {
          final option = kHomeBackgrounds[index];
          final selected = option.id == current.id;
          final locked = !option.isAvailableForPet(pet?.id);
          return _BackgroundCard(
            option: option,
            selected: selected && !locked,
            locked: locked,
            onTap: locked
                ? null
                : () async {
                    await ref
                        .read(backgroundProvider.notifier)
                        .select(option.id);
                    if (option.assetPath != null && context.mounted) {
                      await AssetWarmup.precacheRole(
                        context,
                        option.assetPath!,
                        AssetDisplayRole.background,
                      );
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('已切换为「${option.name}」'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  },
          );
        },
      ),
    );
  }
}

class _BackgroundCard extends StatelessWidget {
  const _BackgroundCard({
    required this.option,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  final HomeBackgroundOption option;
  final bool selected;
  final bool locked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: locked ? 0.55 : 1,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(15),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        option.isAsset
                            ? OptimizedAssetImage(
                                assetPath: option.assetPath!,
                                role: AssetDisplayRole.thumb,
                                fit: BoxFit.cover,
                                showLoading: false,
                                placeholderColor: AppColors.surfaceSecondary,
                                errorBuilder: (context, error, stackTrace) {
                                  return const ColoredBox(
                                    color: AppColors.surfaceSecondary,
                                  );
                                },
                              )
                            : const ColoredBox(
                                color: AppColors.surfaceSecondary,
                                child: Center(
                                  child: Icon(
                                    Icons.directions_car_filled_outlined,
                                    color: AppColors.textSecondary,
                                    size: 36,
                                  ),
                                ),
                              ),
                        if (locked)
                          const ColoredBox(
                            color: Color(0x66000000),
                            child: Center(
                              child: Icon(
                                Icons.lock_outline,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          locked && option.isExclusive
                              ? '${option.name} · 专属'
                              : option.name,
                          style: AppTextStyles.body,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (selected)
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.primary,
                          size: 18,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
