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
import '../widgets/home_action_rail.dart';
import '../widgets/home_background.dart';
import '../widgets/pet_with_bubble.dart';
import '../widgets/speech_bubble.dart';

/// 横屏首页 —— 右侧可收缩工具栏 + 宠物偏下
class LandscapeHomePage extends ConsumerStatefulWidget {
  const LandscapeHomePage({super.key});

  @override
  ConsumerState<LandscapeHomePage> createState() => _LandscapeHomePageState();
}

class _LandscapeHomePageState extends ConsumerState<LandscapeHomePage> {
  String? _selectedId;
  bool _warmed = false;
  bool _railExpanded = true;

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
      final actionPaths = pet.actionAssets.values.toList();
      AssetWarmup.warmActionsInIdle(context, actionPaths);
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
                    _TopBar(
                      showTransform: pet?.canTransform == true && !starry,
                      transformed: ref.watch(kkTransformedProvider),
                      onTransform: () {
                        ref.read(transformTapProvider.notifier).state++;
                      },
                      onBackground: () => context.push('/backgrounds'),
                      onSettings: () => context.go('/mine'),
                    ),
                    Expanded(
                      child: Stack(
                        children: [
                          // 主内容只预留收起态宽度，展开侧栏覆盖其上，不推动宠物
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                right: HomeActionRail.collapsedWidth + 6,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(8, 0, 4, 8),
                                child: Column(
                                  children: [
                                    const Spacer(flex: 5),
                                    Expanded(
                                      flex: 6,
                                      child: Column(
                                        children: [
                                          Expanded(
                                            child: PetWithBubble(
                                              pet: pet,
                                              sleepIdle: starry,
                                              initialMessage: '今天也要开心哦～',
                                              alignment: const Alignment(0, 1),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          const HomePageDots(),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: HomeActionRail(
                              expressions: dock,
                              selectedId: _selectedId,
                              expanded: _railExpanded,
                              onToggle: () {
                                setState(
                                  () => _railExpanded = !_railExpanded,
                                );
                              },
                              onSelected: _onSelect,
                              onMore: () => context.go('/expressions'),
                            ),
                          ),
                        ],
                      ),
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

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.showTransform,
    required this.transformed,
    required this.onTransform,
    required this.onBackground,
    required this.onSettings,
  });

  final bool showTransform;
  final bool transformed;
  final VoidCallback onTransform;
  final VoidCallback onBackground;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 12, 0),
      child: Row(
        children: [
          const Spacer(),
          if (showTransform) ...[
            IconButton(
              tooltip: transformed ? '还原' : '变身',
              onPressed: onTransform,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surface.withValues(alpha: 0.55),
                side: const BorderSide(color: AppColors.border),
              ),
              icon: Icon(
                transformed ? Icons.pets_outlined : Icons.auto_awesome,
                size: 20,
              ),
            ),
            const SizedBox(width: 4),
          ],
          IconButton(
            tooltip: '切换背景',
            onPressed: onBackground,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface.withValues(alpha: 0.55),
              side: const BorderSide(color: AppColors.border),
            ),
            icon: const Icon(Icons.wallpaper_outlined, size: 20),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: '设置',
            onPressed: onSettings,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface.withValues(alpha: 0.55),
              side: const BorderSide(color: AppColors.border),
            ),
            icon: const Icon(Icons.settings_outlined, size: 20),
          ),
        ],
      ),
    );
  }
}
