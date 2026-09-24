import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_text_styles.dart';
import '../../../core/images/asset_warmup.dart';
import '../../../core/images/optimized_asset_image.dart';
import '../../../core/services/providers.dart';
import '../../../data/repositories/expression_repository.dart';
import '../../../data/repositories/pet_repository.dart';
import '../../../domain/display/phone_display_device.dart';
import '../../diy/widgets/diy_sticker_image.dart';
import '../../pet/widgets/pet_avatar.dart';

/// 全屏显示页：常亮 + 沉浸式（点击任意处退出）
class FullscreenDisplayPage extends ConsumerStatefulWidget {
  const FullscreenDisplayPage({
    super.key,
    this.expressionId,
    this.customText,
    this.embedded = false,
    this.onTapAway,
  });

  final String? expressionId;
  final String? customText;

  /// 嵌入显示端时不抢路由 / 不重复进全屏系统态
  final bool embedded;

  /// 嵌入模式下点击空白回调（如清屏回到等待）
  final VoidCallback? onTapAway;

  @override
  ConsumerState<FullscreenDisplayPage> createState() =>
      _FullscreenDisplayPageState();
}

class _FullscreenDisplayPageState extends ConsumerState<FullscreenDisplayPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!widget.embedded) {
        ref.read(screenServiceProvider).enterFullscreen();
      }
      await _warmExpressionAsset();
    });
  }

  @override
  void didUpdateWidget(covariant FullscreenDisplayPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expressionId != widget.expressionId) {
      _warmExpressionAsset();
    }
  }

  Future<void> _warmExpressionAsset() async {
    final id = widget.expressionId;
    if (id == null || !mounted) return;
    final expression = ref.read(expressionRepositoryProvider).getById(id);
    if (expression == null) return;
    final pet = await ref.read(petRepositoryProvider).getCurrent();
    final asset = pet?.resolveAsset(action: expression.petAction);
    if (asset != null && mounted) {
      await AssetWarmup.warmAction(context, asset);
      if (mounted) setState(() {});
    }
  }

  Future<void> _exit() async {
    if (widget.embedded) {
      widget.onTapAway?.call();
      return;
    }
    await ref.read(screenServiceProvider).exitFullscreen();
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final expression = widget.expressionId == null
        ? null
        : ref.watch(expressionRepositoryProvider).getById(widget.expressionId!);
    final display = ref.watch(displayDeviceProvider);
    final custom =
        display is PhoneDisplayDevice ? display.currentCustom : null;
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    return FutureBuilder(
      future: ref.watch(petRepositoryProvider).getCurrent(),
      builder: (context, snapshot) {
        final pet = snapshot.data ??
            ref.read(petRepositoryProvider).getById('cat');
        final hasCustomSticker = custom?.hasImage == true;
        final hasBuiltinSticker = expression?.hasStickerAsset == true;
        final showAsSticker = hasCustomSticker || hasBuiltinSticker;
        final emoji = expression?.emoji ?? '✨';
        final text = widget.customText ??
            custom?.text ??
            (hasBuiltinSticker
                ? ''
                : (expression?.subtitle ?? expression?.title ?? ''));
        final action = expression?.petAction;
        final actionAsset =
            action == null ? null : pet?.resolveAsset(action: action);

        Widget petVisual() {
          if (hasCustomSticker) {
            return DiyStickerImage.fromExpression(custom!);
          }
          if (hasBuiltinSticker) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                expression!.iconAsset!,
                fit: BoxFit.contain,
              ),
            );
          }
          // 有动作 GIF 时用明确路径 + Key，避免仍显示待机图
          if (actionAsset != null) {
            return OptimizedAssetImage(
              key: ValueKey('display_$actionAsset'),
              assetPath: actionAsset,
              fit: BoxFit.contain,
              borderRadius: BorderRadius.circular(24),
              placeholderColor: const Color(0xFF101C2B),
            );
          }
          return PetAvatar(
            pet: pet,
            action: action,
            borderRadius: 24,
            fit: BoxFit.contain,
          );
        }

        Widget stickerOrEmoji({double emojiSize = 40}) {
          if (hasCustomSticker) {
            return DiyStickerImage.fromExpression(custom!);
          }
          return Text(emoji, style: TextStyle(fontSize: emojiSize));
        }

        final message = text.trim().isEmpty
            ? const SizedBox.shrink()
            : Text(
                text,
                style: AppTextStyles.displayMessage,
                textAlign: TextAlign.center,
              );

        return Scaffold(
          backgroundColor: Colors.black,
          body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _exit,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: isLandscape
                    ? Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: petVisual(),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 2,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (!showAsSticker) ...[
                                  stickerOrEmoji(emojiSize: 40),
                                  const SizedBox(height: 12),
                                ],
                                message,
                              ],
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(child: petVisual()),
                          const SizedBox(height: 16),
                          if (!showAsSticker) ...[
                            stickerOrEmoji(emojiSize: 40),
                            const SizedBox(height: 12),
                          ],
                          message,
                          const SizedBox(height: 12),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}
