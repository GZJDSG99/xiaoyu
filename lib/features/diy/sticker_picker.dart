import 'dart:convert';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

/// DIY 表情包选图结果（统一用 base64，兼容 Web / 桌面 / 移动端）
class StickerPickResult {
  const StickerPickResult({required this.base64, this.fileName});

  final String base64;
  final String? fileName;

  bool get isValid => base64.isNotEmpty;
}

class StickerPicker {
  StickerPicker([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// 从相册选择图片或 GIF
  Future<StickerPickResult?> pickFromGallery() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: null,
      maxHeight: null,
      imageQuality: 92,
    );
    if (file == null) return null;
    return persistPicked(file);
  }

  Future<StickerPickResult> persistPicked(XFile file) async {
    final bytes = await file.readAsBytes();
    final name = file.name.isNotEmpty
        ? file.name
        : 'sticker${_extensionOf(file.name, file.mimeType)}';
    return StickerPickResult(
      base64: base64Encode(bytes),
      fileName: name,
    );
  }

  static String _extensionOf(String name, String? mime) {
    final fromName = p.extension(name).toLowerCase();
    if (fromName.isNotEmpty && fromName.length <= 5) return fromName;
    switch (mime) {
      case 'image/gif':
        return '.gif';
      case 'image/png':
        return '.png';
      case 'image/webp':
        return '.webp';
      case 'image/jpeg':
      case 'image/jpg':
        return '.jpg';
      default:
        return '.png';
    }
  }
}
