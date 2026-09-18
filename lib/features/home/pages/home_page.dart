import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/images/asset_warmup.dart';
import '../../../data/models/expression.dart';
import '../../../data/models/home_background.dart';
import '../../../data/models/pet.dart';
import '../../../data/repositories/pet_repository.dart';
import '../../../domain/services/expression_playback.dart';
import '../../../domain/services/expression_service.dart';
import '../providers/background_provider.dart';
import '../providers/pet_form_provider.dart';
import '../widgets/home_action_dock.dart';
import '../widgets/home_background.dart';
import '../widgets/pet_with_bubble.dart';
import '../widgets/speech_bubble.dart';
import 'landscape_home_page.dart';

/// 首页：竖屏 / 横屏自动切换
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OrientationBuilder(
      builder: (context, orientation) {
        if (orientation == Orientation.landscape) {
          return const LandscapeHomePage();
        }
        return const _PortraitHomePage();
      },
    );
  }
}

class _PortraitHomePage extends ConsumerStatefulWidget {
  const _PortraitHomePage();

  @override
  ConsumerState<_PortraitHomePage> createState() => _PortraitHomePageState();
}

class _PortraitHomePageState extends ConsumerState<_PortraitHomePage> {
  String? _selectedId;
  bool _warmed = false;

  Future<void> _onSelect(Expression expression) async {
    setState(() => _selectedId = expression.id);
    await playExpressionFullscreen(
      context: context,
      ref: ref,
      expression: expression,
    );
  }

  void _warmAssets(Pet? pet) {
    if (_warmed || !mounted) return;
    _warmed = true;
    final background = ref.read(effectiveBackgroundProvider);
    final displayPet = pet?.withIdleForBackground(
      starrySky: background.id == kStarrySkyBackgroundId,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await AssetWarmup.warmHome(
        context,
        backgroundAsset: background.assetPath,
        idlePetAsset: displayPet?.assetPath,
      );
      if (!mounted || pet == null) return;
      if (pet.sleepAssetPath != null) {
        await AssetWarmup.warmAction(context, pet.sleepAssetPath!);
      }
      if (pet.transformAssetPath != null) {
        await AssetWarmup.warmAction(context, pet.transformAssetPath!);
      }
      if (pet.transformedIdleAssetPath != null) {
        await AssetWarmup.warmAction(context, pet.transformedIdleAssetPath!);
      }
      AssetWarmup.warmActionsInIdle(context, pet.actionAssets.values);
    });
  }

  @override
  Widget build(BuildContext context) {
    final petFuture = ref.watch(petRepositoryProvider).getCurrent();
    final dock = ref.watch(expressionServiceProvider).getHomeDockExpressions();
    final background = ref.watch(effectiveBackgroundProvider);
    final starry = background.id == kStarrySkyBackgroundId;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<Pet?>(
        future: petFuture,
        builder: (context, snapshot) {
          final pet = snapshot.data;
          if (snapshot.connectionState == ConnectionState.done) {
            _warmAssets(pet);
          }
          return Stack(
            fit: StackFit.expand,
            children: [
              HomeBackground(assetPath: background.assetPath),
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 12, 0),
                      child: Row(
                        children: [
                          const Spacer(),
                          if (pet?.canTransform == true && !starry) ...[
                            IconButton(
                              tooltip: ref.watch(kkTransformedProvider)
                                  ? '还原'
                                  : '变身',
                              onPressed: () {
                                ref
                                    .read(transformTapProvider.notifier)
                                    .state++;
                              },
                              style: IconButton.styleFrom(
                                backgroundColor:
                                    AppColors.surface.withValues(alpha: 0.55),
                                side: const BorderSide(color: AppColors.border),
                              ),
                              icon: Icon(
                                ref.watch(kkTransformedProvider)
                                    ? Icons.pets_outlined
                                    : Icons.auto_awesome,
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                          IconButton(
                            tooltip: '切换背景',
                            onPressed: () => context.push('/backgrounds'),
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  AppColors.surface.withValues(alpha: 0.55),
                              side: const BorderSide(color: AppColors.border),
                            ),
                            icon: const Icon(Icons.wallpaper_outlined),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            onPressed: () => context.go('/mine'),
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  AppColors.surface.withValues(alpha: 0.55),
                              side: const BorderSide(color: AppColors.border),
                            ),
                            icon: const Icon(Icons.settings_outlined),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Column(
                          children: [
                            const Spacer(flex: 10),
                            Expanded(
                              flex: 6,
                              child: PetWithBubble(
                                pet: pet,
                                sleepIdle: starry,
                                initialMessage: '今天也要开心哦～',
                              ),
                            ),
                            const SizedBox(height: 8),
                            const HomePageDots(),
                            const Spacer(flex: 1),
                          ],
                        ),
                      ),
                    ),
                    HomeActionDock(
                      expressions: dock,
                      selectedId: _selectedId,
                      onSelected: _onSelect,
                      onMore: () => context.go('/expressions'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
