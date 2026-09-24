import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 本地 GIF 只播放一遍，停在最后一帧，并回调 [onCompleted]
class OneShotAssetGif extends StatefulWidget {
  const OneShotAssetGif({
    super.key,
    required this.assetPath,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.bottomCenter,
    /// 播放到总时长的该比例即结束（如 0.9 = 播 90%）
    this.playFraction = 1.0,
    this.onReady,
    this.onCompleted,
  });

  final String assetPath;
  final BoxFit fit;
  final Alignment alignment;
  final double playFraction;
  /// 首帧解码完成、可以开始显示时回调
  final VoidCallback? onReady;
  final VoidCallback? onCompleted;

  @override
  State<OneShotAssetGif> createState() => _OneShotAssetGifState();
}

class _OneShotAssetGifState extends State<OneShotAssetGif> {
  final List<ui.Image> _frames = [];
  final List<Duration> _delays = [];
  int _index = 0;
  int _elapsedMs = 0;
  int _cutoffMs = 0;
  Timer? _timer;
  bool _loaded = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant OneShotAssetGif oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath) {
      _resetAndLoad();
    }
  }

  void _resetAndLoad() {
    _timer?.cancel();
    for (final f in _frames) {
      f.dispose();
    }
    _frames.clear();
    _delays.clear();
    _index = 0;
    _elapsedMs = 0;
    _cutoffMs = 0;
    _loaded = false;
    _finished = false;
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await rootBundle.load(widget.assetPath);
      final codec =
          await ui.instantiateImageCodec(data.buffer.asUint8List());
      var totalMs = 0;
      for (var i = 0; i < codec.frameCount; i++) {
        final info = await codec.getNextFrame();
        _frames.add(info.image);
        final ms = info.duration.inMilliseconds;
        final delay = ms > 0 ? ms : 40;
        _delays.add(Duration(milliseconds: delay));
        totalMs += delay;
      }
      final fraction = widget.playFraction.clamp(0.05, 1.0);
      _cutoffMs = (totalMs * fraction).round().clamp(1, totalMs);
      if (!mounted) return;
      setState(() => _loaded = true);
      widget.onReady?.call();
      if (_frames.length <= 1) {
        _finish();
      } else {
        _scheduleNext();
      }
    } catch (_) {
      if (mounted) _finish();
    }
  }

  void _scheduleNext() {
    if (!mounted || _finished || _frames.isEmpty) return;
    _timer?.cancel();
    final delay = _delays[_index.clamp(0, _delays.length - 1)];
    _timer = Timer(delay, () {
      if (!mounted || _finished) return;
      _elapsedMs += delay.inMilliseconds;

      if (_elapsedMs >= _cutoffMs || _index >= _frames.length - 1) {
        _finish();
        return;
      }
      setState(() => _index++);
      _scheduleNext();
    });
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    _timer?.cancel();
    widget.onCompleted?.call();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final f in _frames) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _frames.isEmpty) {
      return const SizedBox.expand();
    }
    return RawImage(
      image: _frames[_index.clamp(0, _frames.length - 1)],
      fit: widget.fit,
      alignment: widget.alignment,
      filterQuality: FilterQuality.low,
    );
  }
}
