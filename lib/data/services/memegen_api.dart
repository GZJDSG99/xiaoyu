import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/meme_template.dart';

/// [Memegen.link](https://memegen.link/) API 客户端
class MemegenApi {
  MemegenApi({http.Client? client}) : _client = client ?? http.Client();

  static const baseUrl = 'https://api.memegen.link';

  /// 默认用 Noto Sans，可显示中文（Impact 等默认字体不含汉字）
  static const defaultFont = 'notosans';

  static const _headers = {
    'User-Agent': 'XiaoyuApp/1.0 (Flutter; memegen client)',
    'Accept': 'application/json, image/*, */*',
  };

  final http.Client _client;

  /// 拉取模板列表（按 id 去重）
  Future<List<MemeTemplate>> fetchTemplates() async {
    final response = await _client
        .get(Uri.parse('$baseUrl/templates/'), headers: _headers)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('加载模板失败（${response.statusCode}）');
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! List) {
      throw StateError('模板数据格式异常');
    }
    final byId = <String, MemeTemplate>{};
    for (final item in decoded) {
      if (item is! Map<String, dynamic>) continue;
      final template = MemeTemplate.fromJson(item);
      if (template.id.isEmpty) continue;
      // 优先保留行数更完整的条目
      final existing = byId[template.id];
      if (existing == null || template.lines > existing.lines) {
        byId[template.id] = template;
      }
    }
    final list = byId.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  /// 按官方规则编码路径文案，再做 URI 百分号编码
  /// 参考：https://memegen.link/ （Text / Special Characters）
  static String encodeText(String text) {
    if (text.trim().isEmpty) return '_';
    var s = text;
    s = s.replaceAll('_', '__');
    s = s.replaceAll('-', '--');
    s = s.replaceAll(' ', '_');
    s = s.replaceAll('?', '~q');
    s = s.replaceAll('&', '~a');
    s = s.replaceAll('%', '~p');
    s = s.replaceAll('#', '~h');
    s = s.replaceAll('/', '~s');
    s = s.replaceAll('\\', '~b');
    s = s.replaceAll('<', '~l');
    s = s.replaceAll('>', '~g');
    s = s.replaceAll('\n', '~n');
    s = s.replaceAll('"', "''");
    return Uri.encodeComponent(s);
  }

  /// 生成预览/下载 URL（默认 webp + Noto Sans，支持中文）
  static String buildImageUrl({
    required String templateId,
    required List<String> texts,
    required int lineCount,
    String extension = 'webp',
    String font = defaultFont,
  }) {
    final count = lineCount.clamp(1, 8);
    final parts = <String>[];
    for (var i = 0; i < count; i++) {
      final raw = i < texts.length ? texts[i] : '';
      parts.add(encodeText(raw));
    }
    final path = '$baseUrl/images/$templateId/${parts.join('/')}';
    return Uri.parse('$path.$extension').replace(
      queryParameters: {'font': font},
    ).toString();
  }

  /// 下载成品图字节
  Future<List<int>> downloadImage(String url) async {
    final response = await _client
        .get(Uri.parse(url), headers: _headers)
        .timeout(const Duration(seconds: 30));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('下载表情包失败（${response.statusCode}）');
    }
    if (response.bodyBytes.isEmpty) {
      throw StateError('下载表情包为空');
    }
    return response.bodyBytes;
  }

  void close() => _client.close();
}
