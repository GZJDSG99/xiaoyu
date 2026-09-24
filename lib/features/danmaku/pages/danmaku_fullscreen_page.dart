import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/providers.dart';
import '../../../data/models/danmaku_config.dart';
import '../providers/danmaku_play_provider.dart';
import '../widgets/rainbow_flash_text.dart';

/// 全屏弹幕：黑底纯文字，右→左滚动，点击退出
class DanmakuFullscreenPage extends ConsumerStatefulWidget {
  const DanmakuFullscreenPage({super.key, required this.config});

  final DanmakuConfig config;

  @override
  ConsumerState<DanmakuFullscreenPage> createState() =>
      _DanmakuFullscreenPageState();
}

class _DanmakuFullscreenPageState extends ConsumerState<DanmakuFullscreenPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(screenServiceProvider).enterFullscreen();
    });
  }

  Future<void> _exit() async {
    await ref.read(screenServiceProvider).exitFullscreen();
    ref.read(pendingDanmakuConfigProvider.notifier).state = null;
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/danmaku');
    }
  }

  @override
  Widget build(BuildContext context) {
    final lines = widget.config.lines;
    return Scaffold(
      backgroundColor: Colors.black,
      body: ColoredBox(
        color: Colors.black,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _exit,
          child: lines.isEmpty
              ? const Center(
                  child: Text(
                    '点一下退出',
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    return _DanmakuStage(
                      config: widget.config,
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _DanmakuStage extends StatefulWidget {
  const _DanmakuStage({
    required this.config,
    required this.width,
    required this.height,
  });

  final DanmakuConfig config;
  final double width;
  final double height;

  @override
  State<_DanmakuStage> createState() => _DanmakuStageState();
}

class _DanmakuStageState extends State<_DanmakuStage> {
  late final List<_DanmakuItem> _items;

  @override
  void initState() {
    super.initState();
    _items = _buildItems();
  }

  double _measureWidth(String text, double fontSize) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return painter.width;
  }

  /// 最多 3 行；1～2 行时整块垂直居中，同轨道防重叠
  List<_DanmakuItem> _buildItems() {
    final lines = widget.config.lines
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .take(3)
        .toList();
    if (lines.isEmpty) return const [];

    final fontSize = widget.config.fontSize;
    // 一行一条轨道，最多 3 轨
    final trackCount = lines.length.clamp(1, 3);
    final durationMs =
        widget.config.speed.crossDuration.inMilliseconds.toDouble();
    final minGap = math.max(48.0, fontSize * 2.2);

    final trackFreeAtMs = List<double>.filled(trackCount, 0);
    final items = <_DanmakuItem>[];

    for (var i = 0; i < lines.length; i++) {
      final text = lines[i];
      final textWidth = _measureWidth(text, fontSize);
      final travel = widget.width + textWidth + 24;
      final speed = travel / durationMs;
      // 优先各占一行；若同轨再排队（一般不会，因一行一条）
      final track = i % trackCount;

      final delayMs = trackFreeAtMs[track];
      final clearMs = (textWidth + minGap) / speed;
      trackFreeAtMs[track] = delayMs + clearMs;

      items.add(
        _DanmakuItem(
          text: text,
          track: track,
          delay: Duration(milliseconds: delayMs.round()),
          textWidth: textWidth,
        ),
      );
    }

    final waveMs = trackFreeAtMs.reduce(math.max);
    final periodMs = math.max(durationMs + 800, waveMs + durationMs * 0.15);

    return [
      for (final item in items)
        item.copyWith(period: Duration(milliseconds: periodMs.round())),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = widget.config.fontSize;
    final trackHeight = fontSize * 1.85;
    final lineCount = _items.map((e) => e.track).fold<int>(0, (m, t) => math.max(m, t + 1));
    final blockHeight = math.max(1, lineCount) * trackHeight;
    // 1～2 行（或不足铺满）时垂直居中
    final topOffset = math.max(0.0, (widget.height - blockHeight) / 2);

    return Stack(
      children: [
        for (final item in _items)
          _FlyingDanmaku(
            text: item.text,
            color: widget.config.color,
            rainbowFlash: widget.config.isRainbowFlash,
            fontSize: fontSize,
            top: topOffset + item.track * trackHeight,
            screenWidth: widget.width,
            textWidth: item.textWidth,
            duration: widget.config.speed.crossDuration,
            delay: item.delay,
            period: item.period,
          ),
        const Positioned(
          left: 0,
          right: 0,
          bottom: 12,
          child: Text(
            '轻触屏幕退出',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _DanmakuItem {
  const _DanmakuItem({
    required this.text,
    required this.track,
    required this.delay,
    required this.textWidth,
    this.period = const Duration(seconds: 12),
  });

  final String text;
  final int track;
  final Duration delay;
  final double textWidth;
  final Duration period;

  _DanmakuItem copyWith({Duration? period}) {
    return _DanmakuItem(
      text: text,
      track: track,
      delay: delay,
      textWidth: textWidth,
      period: period ?? this.period,
    );
  }
}

class _FlyingDanmaku extends StatefulWidget {
  const _FlyingDanmaku({
    required this.text,
    required this.color,
    required this.rainbowFlash,
    required this.fontSize,
    required this.top,
    required this.screenWidth,
    required this.textWidth,
    required this.duration,
    required this.delay,
    required this.period,
  });

  final String text;
  final Color color;
  final bool rainbowFlash;
  final double fontSize;
  final double top;
  final double screenWidth;
  final double textWidth;
  final Duration duration;
  final Duration delay;
  final Duration period;

  @override
  State<_FlyingDanmaku> createState() => _FlyingDanmakuState();
}

class _FlyingDanmakuState extends State<_FlyingDanmaku>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    Future<void>.delayed(widget.delay, () {
      if (!mounted) return;
      _runCycle();
    });
  }

  void _runCycle() {
    if (!mounted) return;
    _controller
      ..reset()
      ..forward().whenComplete(() {
        if (!mounted) return;
        final wait = widget.period - widget.duration;
        Future<void>.delayed(
          wait.isNegative ? const Duration(milliseconds: 400) : wait,
          _runCycle,
        );
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final start = widget.screenWidth;
    final end = -widget.textWidth - 24;
    final label = widget.rainbowFlash
        ? RainbowFlashText(
            text: widget.text,
            fontSize: widget.fontSize,
          )
        : Text(
            widget.text,
            maxLines: 1,
            softWrap: false,
            style: TextStyle(
              color: widget.color,
              fontSize: widget.fontSize,
              fontWeight: FontWeight.w700,
              shadows: const [
                Shadow(
                  offset: Offset(1, 1),
                  blurRadius: 2,
                  color: Colors.black54,
                ),
              ],
            ),
          );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.linear.transform(_controller.value);
        final left = start + (end - start) * t;
        return Positioned(
          left: left,
          top: widget.top,
          child: child!,
        );
      },
      child: label,
    );
  }
}
