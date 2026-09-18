import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../data/models/custom_expression.dart';
import '../../../domain/services/expression_service.dart';
import '../sticker_picker.dart';
import '../widgets/diy_sticker_image.dart';

class DiyPage extends ConsumerStatefulWidget {
  const DiyPage({super.key});

  @override
  ConsumerState<DiyPage> createState() => _DiyPageState();
}

class _DiyPageState extends ConsumerState<DiyPage> {
  final _textController = TextEditingController();
  final _picker = StickerPicker();

  String? _imageBase64;
  Uint8List? _previewBytes;
  bool _picking = false;

  bool get _hasSticker =>
      (_imageBase64 != null && _imageBase64!.isNotEmpty) ||
      _previewBytes != null;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickSticker() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final result = await _picker.pickFromGallery();
      if (result == null || !result.isValid || !mounted) return;

      setState(() {
        _imageBase64 = result.base64;
        _previewBytes = base64Decode(result.base64);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('选择图片失败：$e')),
      );
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _preview() async {
    if (!_hasSticker || _imageBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先上传表情包图片或 GIF')),
      );
      return;
    }

    final text = _textController.text.trim();
    final custom = CustomExpression(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      imageBase64: _imageBase64,
    );
    await ref.read(expressionServiceProvider).playCustom(custom);
    if (!mounted) return;
    final query = text.isEmpty ? '' : '?text=${Uri.encodeComponent(text)}';
    context.push('/display$query');
  }

  void _clearSticker() {
    setState(() {
      _imageBase64 = null;
      _previewBytes = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DIY')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('表情包', style: AppTextStyles.title),
          const SizedBox(height: 8),
          Text(
            '支持上传图片或 GIF',
            style: AppTextStyles.bodySecondary,
          ),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: _picking || _hasSticker ? null : _pickSticker,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _hasSticker
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            DiyStickerImage(
                              base64: _imageBase64,
                              bytes: _previewBytes,
                              fit: BoxFit.contain,
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton.filledTonal(
                                onPressed: _clearSticker,
                                icon: const Icon(Icons.close, size: 18),
                                tooltip: '清除',
                              ),
                            ),
                            Positioned(
                              left: 8,
                              bottom: 8,
                              child: TextButton.icon(
                                onPressed: _picking ? null : _pickSticker,
                                icon: const Icon(Icons.swap_horiz, size: 18),
                                label: const Text('更换'),
                              ),
                            ),
                          ],
                        )
                      : Center(
                          child: _picking
                              ? const CircularProgressIndicator()
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate_outlined,
                                      size: 40,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '点击上传表情包',
                                      style: AppTextStyles.bodySecondary,
                                    ),
                                  ],
                                ),
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('自定义文字（可选）', style: AppTextStyles.title),
          const SizedBox(height: 12),
          TextField(
            controller: _textController,
            maxLength: 20,
            style: AppTextStyles.body,
            decoration: InputDecoration(
              hintText: '例如：谢谢你让路啦',
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _preview,
              child: const Text('全屏预览'),
            ),
          ),
        ],
      ),
    );
  }
}
