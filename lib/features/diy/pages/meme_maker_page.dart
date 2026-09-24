import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../data/models/meme_template.dart';
import '../../../data/services/memegen_api.dart';
import '../local_meme_composer.dart';
import '../sticker_picker.dart';

/// 制作表情包：Memegen 模板 或 自定义背景本地叠字，确认后返回 base64
class MemeMakerPage extends StatefulWidget {
  const MemeMakerPage({super.key});

  @override
  State<MemeMakerPage> createState() => _MemeMakerPageState();
}

class _MemeMakerPageState extends State<MemeMakerPage> {
  final _api = MemegenApi();
  final _picker = StickerPicker();
  final _searchController = TextEditingController();

  List<MemeTemplate> _all = const [];
  List<MemeTemplate> _filtered = const [];
  MemeTemplate? _selected;
  List<TextEditingController> _lineControllers = const [];

  /// 自定义背景模式（本地叠字）
  bool _customMode = false;
  Uint8List? _customBgBytes;
  bool _pickingBg = false;

  bool _loading = true;
  String? _error;
  String? _previewUrl;
  bool _applying = false;
  Timer? _previewDebounce;

  bool get _editing => _selected != null || _customMode;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _previewDebounce?.cancel();
    _searchController.dispose();
    for (final c in _lineControllers) {
      c.dispose();
    }
    _api.close();
    super.dispose();
  }

  Future<void> _loadTemplates() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _api.fetchTemplates();
      if (!mounted) return;
      setState(() {
        _all = list;
        _loading = false;
      });
      _applyFilter();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _applyFilter() {
    final q = _searchController.text.trim().toLowerCase();
    final filtered = q.isEmpty
        ? _all
        : _all.where((t) {
            if (t.name.toLowerCase().contains(q)) return true;
            if (t.id.toLowerCase().contains(q)) return true;
            return t.keywords.any((k) => k.toLowerCase().contains(q));
          }).toList();
    setState(() => _filtered = filtered);
  }

  void _disposeLineControllers() {
    for (final c in _lineControllers) {
      c.dispose();
    }
    _lineControllers = const [];
  }

  List<TextEditingController> _createLineControllers(int count, {List<String>? seeds}) {
    return List.generate(count, (i) {
      final text = (seeds != null && i < seeds.length) ? seeds[i] : '';
      final c = TextEditingController(text: text);
      c.addListener(_schedulePreview);
      return c;
    });
  }

  void _selectTemplate(MemeTemplate template) {
    _disposeLineControllers();
    setState(() {
      _customMode = false;
      _customBgBytes = null;
      _selected = template;
      _lineControllers = _createLineControllers(
        template.lines,
        seeds: template.exampleTexts,
      );
    });
    _schedulePreview();
  }

  Future<void> _startCustomBackground() async {
    if (_pickingBg) return;
    setState(() => _pickingBg = true);
    try {
      final result = await _picker.pickFromGallery();
      if (result == null || !result.isValid || !mounted) return;
      final bytes = base64Decode(result.base64);
      _disposeLineControllers();
      setState(() {
        _selected = null;
        _previewUrl = null;
        _customMode = true;
        _customBgBytes = bytes;
        _lineControllers = _createLineControllers(2);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('选择背景失败：$e')),
      );
    } finally {
      if (mounted) setState(() => _pickingBg = false);
    }
  }

  Future<void> _repickCustomBackground() async {
    await _startCustomBackground();
  }

  void _clearSelection() {
    _disposeLineControllers();
    setState(() {
      _selected = null;
      _customMode = false;
      _customBgBytes = null;
      _previewUrl = null;
      _lineControllers = const [];
    });
  }

  void _schedulePreview() {
    _previewDebounce?.cancel();
    _previewDebounce = Timer(const Duration(milliseconds: 350), _updatePreview);
  }

  void _updatePreview() {
    final template = _selected;
    if (template == null) {
      // 自定义模式用 Stack 实时预览，无需 URL
      if (mounted) setState(() {});
      return;
    }
    final texts = _lineControllers.map((c) => c.text).toList();
    final url = MemegenApi.buildImageUrl(
      templateId: template.id,
      texts: texts,
      lineCount: template.lines,
    );
    if (!mounted) return;
    setState(() => _previewUrl = url);
  }

  Future<void> _apply() async {
    if (_applying) return;
    setState(() => _applying = true);
    try {
      late final List<int> bytes;
      if (_customMode) {
        final bg = _customBgBytes;
        if (bg == null) return;
        final top = _lineControllers.isNotEmpty ? _lineControllers[0].text : '';
        final bottom =
            _lineControllers.length > 1 ? _lineControllers[1].text : '';
        bytes = await LocalMemeComposer.compose(
          backgroundBytes: bg,
          top: top,
          bottom: bottom,
        );
      } else {
        final url = _previewUrl;
        if (url == null) return;
        bytes = await _api.downloadImage(url);
      }
      if (!mounted) return;
      Navigator.of(context).pop(base64Encode(bytes));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('生成失败：$e')),
      );
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          !_editing
              ? '选择模板'
              : (_customMode ? '自定义背景' : '编辑文案'),
        ),
        leading: !_editing
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _clearSelection,
              ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_customMode && _customBgBytes != null) {
      return _buildCustomEditor();
    }
    if (_selected != null) {
      return _buildTemplateEditor(_selected!);
    }
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    // 模板加载失败时仍可自定义背景
    return _buildTemplateGrid(showErrorBanner: _error != null);
  }

  Widget _buildCustomEntryCard() {
    return Material(
      color: AppColors.surfaceSecondary,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: _pickingBg ? null : _startCustomBackground,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.45)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_pickingBg)
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Icon(Icons.add_photo_alternate_outlined,
                    color: AppColors.primary, size: 32),
              const SizedBox(height: 8),
              Text(
                '自定义背景',
                style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                textAlign: TextAlign.center,
              ),
              Text(
                '相册选图叠字',
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateGrid({bool showErrorBanner = false}) {
    return Column(
      children: [
        if (showErrorBanner)
          Material(
            color: AppColors.surfaceSecondary,
            child: ListTile(
              dense: true,
              leading: const Icon(Icons.wifi_off, color: AppColors.warning),
              title: Text(
                '模板列表加载失败，仍可用自定义背景',
                style: AppTextStyles.caption,
              ),
              trailing: TextButton(onPressed: _loadTemplates, child: const Text('重试')),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: _searchController,
            style: AppTextStyles.body,
            cursorColor: AppColors.text,
            decoration: InputDecoration(
              hintText: '搜索模板名称',
              hintStyle: AppTextStyles.bodySecondary,
              prefixIcon:
                  const Icon(Icons.search, color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.85,
            ),
            // +1：自定义背景入口
            itemCount: _filtered.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) return _buildCustomEntryCard();
              final t = _filtered[index - 1];
              return _TemplateCard(
                template: t,
                onTap: () => _selectTemplate(t),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewFrame({required Widget child}) {
    return AspectRatio(
      aspectRatio: 1.2,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: child,
        ),
      ),
    );
  }

  Widget _buildLineFields({List<String>? labels}) {
    return Column(
      children: [
        for (var i = 0; i < _lineControllers.length; i++) ...[
          TextField(
            controller: _lineControllers[i],
            maxLength: 40,
            style: AppTextStyles.body,
            cursorColor: AppColors.text,
            decoration: InputDecoration(
              labelText: labels != null && i < labels.length
                  ? labels[i]
                  : '第 ${i + 1} 行',
              labelStyle: AppTextStyles.bodySecondary,
              hintText: '留空则该行不显示文字',
              hintStyle: AppTextStyles.bodySecondary,
              counterStyle: AppTextStyles.caption,
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildApplyButton({required bool enabled}) {
    return SizedBox(
      height: 52,
      child: FilledButton(
        onPressed: !enabled || _applying ? null : _apply,
        child: _applying
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('使用这张'),
      ),
    );
  }

  Widget _buildCustomEditor() {
    final top = _lineControllers.isNotEmpty ? _lineControllers[0].text : '';
    final bottom =
        _lineControllers.length > 1 ? _lineControllers[1].text : '';
    final bg = _customBgBytes!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildPreviewFrame(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.memory(bg, fit: BoxFit.contain),
              if (top.trim().isNotEmpty)
                Positioned(
                  left: 12,
                  right: 12,
                  top: 12,
                  child: _MemePreviewText(text: top.trim()),
                ),
              if (bottom.trim().isNotEmpty)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: _MemePreviewText(text: bottom.trim()),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: Text('自定义背景', style: AppTextStyles.title)),
            TextButton.icon(
              onPressed: _pickingBg ? null : _repickCustomBackground,
              icon: const Icon(Icons.swap_horiz, size: 18),
              label: const Text('换图'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildLineFields(labels: const ['上方文案', '下方文案']),
        const SizedBox(height: 8),
        _buildApplyButton(enabled: true),
        const SizedBox(height: 8),
        Text(
          '本地叠字生成 · 不经过 memegen',
          style: AppTextStyles.caption,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTemplateEditor(MemeTemplate template) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildPreviewFrame(
          child: _previewUrl == null
              ? const Center(child: Text('输入文案预览'))
              : Image.network(
                  _previewUrl!,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  },
                  errorBuilder: (context, error, stack) {
                    return Center(
                      child: Text(
                        '预览失败，请检查网络或文案',
                        style: AppTextStyles.bodySecondary,
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 8),
        Text(template.name, style: AppTextStyles.title),
        const SizedBox(height: 12),
        _buildLineFields(),
        const SizedBox(height: 8),
        _buildApplyButton(enabled: _previewUrl != null),
        const SizedBox(height: 8),
        Text(
          '由 memegen.link 生成 · 中文使用 Noto Sans 字体',
          style: AppTextStyles.caption,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _MemePreviewText extends StatelessWidget {
  const _MemePreviewText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        height: 1.2,
        shadows: const [
          Shadow(offset: Offset(-1.5, -1.5), color: Colors.black),
          Shadow(offset: Offset(1.5, -1.5), color: Colors.black),
          Shadow(offset: Offset(1.5, 1.5), color: Colors.black),
          Shadow(offset: Offset(-1.5, 1.5), color: Colors.black),
          Shadow(offset: Offset(0, 2), blurRadius: 2, color: Colors.black),
        ],
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({required this.template, required this.onTap});

  final MemeTemplate template;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(11),
                  ),
                  child: template.blankUrl.isEmpty
                      ? const ColoredBox(color: AppColors.surfaceSecondary)
                      : Image.network(
                          template.blankUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) {
                            return const ColoredBox(
                              color: AppColors.surfaceSecondary,
                              child: Icon(Icons.broken_image_outlined),
                            );
                          },
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
                child: Text(
                  template.name,
                  style: AppTextStyles.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
