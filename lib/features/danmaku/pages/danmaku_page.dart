import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../data/local/local_storage.dart';
import '../../../data/models/danmaku_config.dart';
import '../providers/danmaku_play_provider.dart';
import '../widgets/rainbow_flash_text.dart';

class DanmakuPage extends ConsumerStatefulWidget {
  const DanmakuPage({super.key});

  @override
  ConsumerState<DanmakuPage> createState() => _DanmakuPageState();
}

class _DanmakuPageState extends ConsumerState<DanmakuPage> {
  late final TextEditingController _textController;
  double? _fontSize;
  int _colorValue = 0xFFFFFFFF;
  DanmakuSpeed _speed = DanmakuSpeed.medium;
  List<String> _recent = const [];
  bool _prefsLoaded = false;

  /// 最小字号 = 屏高 1/3；最大略大一点便于调节
  (double min, double max) _fontRange(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    final minFont = h / 3;
    final maxFont = math.max(minFont + 8, h * 0.45);
    return (minFont, maxFont);
  }

  double _effectiveFontSize(BuildContext context) {
    final range = _fontRange(context);
    return (_fontSize ?? range.$1).clamp(range.$1, range.$2);
  }

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _textController.addListener(() => setState(() {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_prefsLoaded) return;
    _prefsLoaded = true;
    final storage = ref.read(localStorageProvider);
    final range = _fontRange(context);
    _fontSize = storage.danmakuFontSize.clamp(range.$1, range.$2);
    _colorValue = storage.danmakuColor;
    _speed = DanmakuSpeed.values.firstWhere(
      (e) => e.name == storage.danmakuSpeed,
      orElse: () => DanmakuSpeed.medium,
    );
    _recent = storage.danmakuRecent.take(3).toList();
    if (_recent.length != storage.danmakuRecent.length) {
      storage.setDanmakuRecent(_recent);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  List<String> _parseLines(String raw) {
    return raw
        .split(RegExp(r'[\n|｜]+'))
        .expand((e) => e.split(RegExp(r'[;；]+')))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .take(3)
        .toList();
  }

  Future<void> _persistPrefs() async {
    final storage = ref.read(localStorageProvider);
    await storage.setDanmakuFontSize(_effectiveFontSize(context));
    await storage.setDanmakuColor(_colorValue);
    await storage.setDanmakuSpeed(_speed.name);
  }

  Future<void> _deleteRecent(String item) async {
    final recent = _recent.where((e) => e != item).toList();
    await ref.read(localStorageProvider).setDanmakuRecent(recent);
    if (!mounted) return;
    setState(() => _recent = recent);
  }

  Future<void> _play() async {
    final lines = _parseLines(_textController.text);
    if (lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先输入弹幕文字')),
      );
      return;
    }

    final joined = lines.join('｜');
    final recent = [
      joined,
      ..._recent.where((e) => e != joined),
    ].take(3).toList();
    await ref.read(localStorageProvider).setDanmakuRecent(recent);
    await _persistPrefs();
    if (!mounted) return;
    setState(() => _recent = recent);

    final config = DanmakuConfig(
      lines: lines,
      fontSize: _effectiveFontSize(context),
      colorValue: _colorValue,
      speed: _speed,
    );
    ref.read(pendingDanmakuConfigProvider.notifier).state = config;
    if (!mounted) return;
    context.push('/danmaku/play');
  }

  @override
  Widget build(BuildContext context) {
    final range = _fontRange(context);
    final fontSize = _effectiveFontSize(context);

    return Scaffold(
      appBar: AppBar(title: const Text('弹幕')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('弹幕内容', style: AppTextStyles.title),
          const SizedBox(height: 8),
          Text(
            '最多 3 行，可用换行或｜分隔',
            style: AppTextStyles.bodySecondary,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _textController,
            minLines: 1,
            maxLines: 3,
            maxLength: 120,
            style: AppTextStyles.body,
            cursorColor: AppColors.text,
            decoration: InputDecoration(
              hintText: '例如：路况顺利｜今天也要开心哦',
              hintStyle: AppTextStyles.bodySecondary,
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
          if (_recent.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('最近使用', style: AppTextStyles.title),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _recent.map((e) {
                return Material(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      _textController.text = e;
                      setState(() {});
                    },
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 220),
                      padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              e,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.text,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: '删除',
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                            iconSize: 16,
                            color: AppColors.textSecondary,
                            onPressed: () => _deleteRecent(e),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 24),
          Text('字号 ${fontSize.round()}', style: AppTextStyles.title),
          Text('最小为屏高 1/3', style: AppTextStyles.caption),
          Slider(
            value: fontSize,
            min: range.$1,
            max: range.$2,
            divisions: 20,
            label: fontSize.round().toString(),
            onChanged: (v) => setState(() => _fontSize = v),
            onChangeEnd: (_) => _persistPrefs(),
          ),
          const SizedBox(height: 8),
          Text('颜色', style: AppTextStyles.title),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: kDanmakuColorPresets.map((c) {
              final selected = c == _colorValue;
              final isRainbow = c == kDanmakuRainbowFlash;
              return GestureDetector(
                onTap: () {
                  setState(() => _colorValue = c);
                  _persistPrefs();
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isRainbow
                        ? const SweepGradient(
                            colors: [
                              Colors.red,
                              Colors.orange,
                              Colors.yellow,
                              Colors.green,
                              Colors.cyan,
                              Colors.blue,
                              Colors.purple,
                              Colors.red,
                            ],
                          )
                        : null,
                    color: isRainbow ? null : Color(c),
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.border,
                      width: selected ? 3 : 1,
                    ),
                  ),
                  child: isRainbow
                      ? const Icon(Icons.auto_awesome, size: 16, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Text('速度', style: AppTextStyles.title),
          const SizedBox(height: 10),
          SegmentedButton<DanmakuSpeed>(
            segments: [
              for (final s in DanmakuSpeed.values)
                ButtonSegment(value: s, label: Text(s.label)),
            ],
            selected: {_speed},
            onSelectionChanged: (set) {
              setState(() => _speed = set.first);
              _persistPrefs();
            },
          ),
          const SizedBox(height: 16),
          Container(
            height: 56,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Builder(
              builder: (context) {
                final previewText = _textController.text.trim().isEmpty
                    ? '预览效果'
                    : _parseLines(_textController.text).first;
                const previewSize = 22.0;
                if (_colorValue == kDanmakuRainbowFlash) {
                  return RainbowFlashText(
                    text: previewText,
                    fontSize: previewSize,
                    overflow: TextOverflow.ellipsis,
                  );
                }
                return Text(
                  previewText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(_colorValue),
                    fontSize: previewSize,
                    fontWeight: FontWeight.w700,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _play,
              child: const Text('全屏播放'),
            ),
          ),
        ],
      ),
    );
  }
}
