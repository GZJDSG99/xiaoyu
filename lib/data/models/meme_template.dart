/// Memegen 模板（来自 https://api.memegen.link/templates/）
class MemeTemplate {
  const MemeTemplate({
    required this.id,
    required this.name,
    required this.lines,
    required this.blankUrl,
    this.exampleTexts = const [],
    this.exampleUrl,
    this.keywords = const [],
  });

  final String id;
  final String name;
  final int lines;
  final String blankUrl;
  final List<String> exampleTexts;
  final String? exampleUrl;
  final List<String> keywords;

  factory MemeTemplate.fromJson(Map<String, dynamic> json) {
    final example = json['example'];
    List<String> texts = const [];
    String? exampleUrl;
    if (example is Map<String, dynamic>) {
      final raw = example['text'];
      if (raw is List) {
        texts = raw.map((e) => e?.toString() ?? '').toList();
      }
      exampleUrl = example['url']?.toString();
    }
    final keywords = json['keywords'];
    return MemeTemplate(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      lines: (json['lines'] as num?)?.toInt() ?? 2,
      blankUrl: json['blank']?.toString() ?? '',
      exampleTexts: texts,
      exampleUrl: exampleUrl,
      keywords: keywords is List
          ? keywords.map((e) => e.toString()).toList()
          : const [],
    );
  }
}
