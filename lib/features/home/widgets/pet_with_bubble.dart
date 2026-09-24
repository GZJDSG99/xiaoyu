import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../data/models/pet.dart';
import '../../pet/widgets/pet_avatar.dart';
import '../../../core/images/asset_warmup.dart';
import '../providers/pet_form_provider.dart';
import 'one_shot_asset_gif.dart';
import 'speech_bubble.dart';

/// 点击宠物时轮换的对话文案
const kPetTapMessages = <String>[
  '今天也要开心哦～',
  '摸摸头！',
  '准备好出发了吗？',
  '我在呢～',
  '路况顺利呀',
  '想吃小鱼干…',
  '一起加油！',
  '嘻嘻，被发现了',
  '晚点记得休息哦',
  '有我陪着你～',
];

/// 向左（或返回）连续跳跃次数；次数 = jump.gif 播放遍数
const _kHopCount = 3;

const _kFlipFadeDuration = Duration(milliseconds: 120);
const _kSettleDuration = Duration(milliseconds: 240);
const _kFallbackGifDuration = Duration(milliseconds: 800);
/// 变身收尾交叉淡入，避免黑场拼接感
const _kTransformCrossfade = Duration(milliseconds: 280);
/// 变身过渡动画放大
const _kTransformAnimScale = 1.72;
/// 人形态待机放大
const _kHumanIdleScale = 1.8;

/// 宠物 + 头部右侧聊天泡泡
/// - 单击：换文案
/// - 双击：跳跃往返
/// - 变身：由顶栏触发（[transformTapProvider]），播 change 一次后切 kk 待机；再点还原
class PetWithBubble extends ConsumerStatefulWidget {
  const PetWithBubble({
    super.key,
    required this.pet,
    this.initialMessage,
    this.alignment = Alignment.bottomCenter,
    this.messages = kPetTapMessages,
    this.sleepIdle = false,
  });

  final Pet? pet;
  final String? initialMessage;
  final Alignment alignment;
  final List<String> messages;

  /// 星空/夜间：使用睡眠待机，并隐藏变身按钮
  final bool sleepIdle;

  @override
  ConsumerState<PetWithBubble> createState() => _PetWithBubbleState();
}

class _PetWithBubbleState extends ConsumerState<PetWithBubble>
    with SingleTickerProviderStateMixin {
  late int _index;
  final _random = math.Random();

  late final AnimationController _hopController;
  late final CurvedAnimation _hopCurve;

  bool _busy = false;
  bool _jumping = false;
  bool _transforming = false;
  bool _facingReturn = false;
  bool _away = false;

  /// 变身过渡层透明度（1=播 change.gif，淡出后露出目标待机）
  double _changeOpacity = 0;
  /// 变身 GIF 首帧已就绪（未就绪前继续露底层，避免黑闪）
  bool _changeReady = false;
  int _changeGen = 0;

  double _settledX = 0;
  double _hopDelta = 0;
  double _poseOpacity = 1;
  int _jumpGen = 0;
  int _poseGen = 0;

  double _hopStepPx = 96;
  double _tripHopStep = 96;

  final Map<String, Duration> _gifDurationCache = {};

  @override
  void initState() {
    super.initState();
    final initial = widget.initialMessage;
    final list = widget.messages;
    if (initial != null && list.contains(initial)) {
      _index = list.indexOf(initial);
    } else {
      _index = 0;
    }

    _hopController = AnimationController(
      vsync: this,
      duration: _kFallbackGifDuration,
    );
    _hopCurve = CurvedAnimation(
      parent: _hopController,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _hopCurve.dispose();
    _hopController.dispose();
    super.dispose();
  }

  String get _message {
    if (widget.pet == null) return '选一只小语一起上路吧';
    final list = widget.messages;
    if (list.isEmpty) return widget.initialMessage ?? '你好呀～';
    return list[_index % list.length];
  }

  bool get _canJump {
    final path = widget.pet?.jumpAssetPath;
    return path != null && path.isNotEmpty;
  }

  bool get _canTransform =>
      widget.pet?.canTransform == true && !widget.sleepIdle;

  Pet? get _basePet {
    final p = widget.pet;
    if (p == null) return null;
    // 夜间睡眠优先于变身形态展示
    if (widget.sleepIdle) {
      return p.withIdleForBackground(starrySky: true);
    }
    final transformed = ref.watch(kkTransformedProvider);
    if (transformed) {
      return p.copyWith(assetPath: p.transformedIdleAssetPath);
    }
    return p;
  }

  double get _formScale {
    if (widget.sleepIdle) return 1.0;
    // 仅人形态放大；变身过程中猫仍 1.0，避免一瞬间被放大
    if (ref.watch(kkTransformedProvider)) return _kHumanIdleScale;
    return 1.0;
  }

  Future<Duration> _ensureGifDurationFor(String path) async {
    final cached = _gifDurationCache[path];
    if (cached != null) return cached;

    try {
      final data = await rootBundle.load(path);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      var totalMs = 0;
      for (var i = 0; i < codec.frameCount; i++) {
        final frame = await codec.getNextFrame();
        final ms = frame.duration.inMilliseconds;
        totalMs += ms > 0 ? ms : 40;
      }
      final duration = totalMs > 0
          ? Duration(milliseconds: totalMs)
          : _kFallbackGifDuration;
      _gifDurationCache[path] = duration;
      return duration;
    } catch (_) {
      return _kFallbackGifDuration;
    }
  }

  void _onPetTap() {
    if (widget.pet == null || _busy) return;
    final list = widget.messages;
    if (list.length <= 1) return;

    setState(() {
      var next = _random.nextInt(list.length);
      if (next == _index) {
        next = (next + 1) % list.length;
      }
      _index = next;
    });
  }

  Future<void> _fadePose(double target) async {
    if (!mounted) return;
    setState(() => _poseOpacity = target);
    await Future<void>.delayed(_kFlipFadeDuration);
  }

  Future<void> _playOneHop({
    required double delta,
    required Duration duration,
    required bool facingReturn,
  }) async {
    setState(() {
      _jumping = true;
      _facingReturn = facingReturn;
      _hopDelta = delta;
      _poseOpacity = 1;
      _jumpGen++;
    });

    _hopController.duration = duration;
    await _hopController.forward(from: 0);
    if (!mounted) return;

    setState(() {
      _settledX += delta;
      _hopDelta = 0;
    });
    _hopController.value = 0;
  }

  Future<void> _onPetDoubleTap() async {
    if (!_canJump || _busy || _transforming) return;
    _busy = true;

    try {
      final jumpPath = widget.pet!.jumpAssetPath!;
      final duration = await _ensureGifDurationFor(jumpPath);
      if (!mounted) return;

      if (!_away) {
        _tripHopStep = _hopStepPx;
        for (var i = 0; i < _kHopCount; i++) {
          await _playOneHop(
            delta: -_tripHopStep,
            duration: duration,
            facingReturn: false,
          );
          if (!mounted) return;
        }
        await _fadePose(0);
        if (!mounted) return;
        setState(() {
          _jumping = false;
          _facingReturn = false;
          _away = true;
        });
        await _fadePose(1);
      } else {
        await _fadePose(0);
        if (!mounted) return;
        setState(() => _facingReturn = true);
        await _fadePose(1);
        if (!mounted) return;

        for (var i = 0; i < _kHopCount; i++) {
          await _playOneHop(
            delta: _tripHopStep,
            duration: duration,
            facingReturn: true,
          );
          if (!mounted) return;
        }

        await _fadePose(0);
        if (!mounted) return;
        setState(() {
          _jumping = false;
          _facingReturn = false;
          _away = false;
          _settledX = 0;
          _hopDelta = 0;
        });
        await _fadePose(1);
      }
    } finally {
      _busy = false;
    }
  }

  Future<void> _onTransformTap() async {
    if (!_canTransform || _busy || _transforming) return;
    final nextTransformed = !ref.read(kkTransformedProvider);

    // 人形态 → 猫：直接还原，不播变身动画
    if (!nextTransformed) {
      _busy = true;
      try {
        await _fadePose(0);
        if (!mounted) return;
        ref.read(kkTransformedProvider.notifier).state = false;
        setState(() => _poseGen++);
        await _fadePose(1);
      } finally {
        _busy = false;
      }
      return;
    }

    // 猫 → 人：先预热变身/人形 GIF，再播 change，避免首帧黑闪
    _busy = true;
    final changePath = widget.pet?.transformAssetPath;
    final kkPath = widget.pet?.transformedIdleAssetPath;
    if (changePath != null) {
      await AssetWarmup.warmAction(context, changePath);
    }
    if (!mounted) {
      _busy = false;
      return;
    }
    if (kkPath != null) {
      await AssetWarmup.warmAction(context, kkPath);
    }
    if (!mounted) {
      _busy = false;
      return;
    }
    setState(() {
      _transforming = true;
      _changeReady = false;
      _changeOpacity = 1;
      _changeGen++;
      _poseOpacity = 1;
    });
  }

  Future<void> _onChangeGifCompleted() async {
    if (!mounted || !_transforming) return;

    // 底层切人形态，顶层停在末帧并淡出
    ref.read(kkTransformedProvider.notifier).state = true;
    setState(() => _changeOpacity = 0);
    await Future<void>.delayed(_kTransformCrossfade);
    if (!mounted) return;

    setState(() {
      _transforming = false;
      _changeOpacity = 0;
      _changeReady = false;
      _poseGen++;
    });
    _busy = false;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(transformTapProvider, (prev, next) {
      if (prev != next) _onTransformTap();
    });

    final basePet = _basePet;
    final formScale = _formScale;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight;
        final petSide = math.min(maxW * 0.72, maxH * 0.95);
        final homeLeft = (maxW - petSide) / 2;
        final maxStep = homeLeft / _kHopCount;
        _hopStepPx = math
            .min(petSide * 0.38, math.min(maxW * 0.24, maxStep))
            .clamp(24.0, double.infinity);

        final jumpPet = widget.pet?.copyWith(
          assetPath: widget.pet!.jumpAssetPath,
        );

        return Align(
          alignment: widget.alignment,
          child: SizedBox(
            width: maxW,
            height: petSide,
            child: AnimatedBuilder(
              animation: _hopCurve,
              builder: (context, child) {
                final dx = _settledX + _hopDelta * _hopCurve.value;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (_away || _jumping)
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: _onPetTap,
                          onDoubleTap: _onPetDoubleTap,
                        ),
                      ),
                    Positioned(
                      left: homeLeft + dx,
                      bottom: 0,
                      width: petSide,
                      height: petSide,
                      child: child!,
                    ),
                  ],
                );
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _onPetTap,
                      onDoubleTap: _onPetDoubleTap,
                      child: AnimatedOpacity(
                        opacity: _poseOpacity,
                        duration: _kFlipFadeDuration,
                        curve: Curves.easeOutCubic,
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.diagonal3Values(
                            _facingReturn ? -1.0 : 1.0,
                            1.0,
                            1.0,
                          ),
                          child: AnimatedScale(
                            scale: formScale,
                            // 切到人形态时瞬间到位（仍在变身淡出中），避免事后放大
                            duration: _transforming
                                ? Duration.zero
                                : const Duration(milliseconds: 420),
                            curve: Curves.easeOutCubic,
                            // 以底部为锚点放大，三种形态脚底对齐
                            alignment: Alignment.bottomCenter,
                            child: Stack(
                              fit: StackFit.expand,
                              alignment: Alignment.bottomCenter,
                              children: [
                                // 变身播 change 时不露猫待机；交叉淡入后才显示目标形态
                                if (!_transforming ||
                                    _changeOpacity < 1 ||
                                    !_changeReady)
                                  PetAvatar(
                                    // 不把 assetPath 写进 key，便于 gapless 衔接
                                    key: ValueKey(
                                      _jumping
                                          ? 'jump_${widget.pet?.id}_$_jumpGen'
                                          : 'base_${widget.pet?.id}',
                                    ),
                                    pet: _jumping ? jumpPet : basePet,
                                    borderRadius: 0,
                                    fit: BoxFit.contain,
                                    alignment: Alignment.bottomCenter,
                                  ),
                                // 顶层：变身 GIF 独立 1.72 倍，不带动底层猫放大
                                if (_transforming &&
                                    widget.pet?.transformAssetPath != null)
                                  IgnorePointer(
                                    child: AnimatedOpacity(
                                      opacity: _changeReady ? _changeOpacity : 0,
                                      duration: _changeReady
                                          ? _kTransformCrossfade
                                          : Duration.zero,
                                      curve: Curves.easeInOutCubic,
                                      child: Transform.scale(
                                        scale: _kTransformAnimScale,
                                        alignment: Alignment.bottomCenter,
                                        child: OneShotAssetGif(
                                          key: ValueKey(
                                            'change_${widget.pet?.id}_$_changeGen',
                                          ),
                                          assetPath:
                                              widget.pet!.transformAssetPath!,
                                          fit: BoxFit.contain,
                                          alignment: Alignment.bottomCenter,
                                          playFraction: 0.9,
                                          onReady: () {
                                            if (!mounted || !_transforming) {
                                              return;
                                            }
                                            setState(() => _changeReady = true);
                                          },
                                          onCompleted: _onChangeGifCompleted,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: petSide * 0.68,
                    top: petSide * -0.02,
                    child: IgnorePointer(
                      child: AnimatedOpacity(
                        opacity: (_jumping || _transforming) ? 0.0 : 1.0,
                        duration: _kSettleDuration,
                        curve: Curves.easeOutCubic,
                        child: SpeechBubble(
                          message: _message,
                          tail: SpeechBubbleTail.left,
                          maxWidth: math.min(200, maxW * 0.42),
                          animateMessage: true,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
