import 'dart:convert';

/// 局域网显示端固定端口
const kDisplayRemotePort = 17890;

/// 遥控 ↔ 显示端 JSON 指令
class DisplayRemoteMessage {
  const DisplayRemoteMessage({
    required this.type,
    this.id,
    this.code,
    this.text,
    this.imageBase64,
  });

  final String type;
  final String? id;
  final String? code;
  final String? text;
  final String? imageBase64;

  static const typeAuth = 'auth';
  static const typeAuthOk = 'auth_ok';
  static const typeAuthFail = 'auth_fail';
  static const typeExpression = 'expression';
  static const typeCustom = 'custom';
  static const typeClear = 'clear';
  static const typePing = 'ping';
  static const typePong = 'pong';

  Map<String, dynamic> toJson() => {
        'type': type,
        if (id != null) 'id': id,
        if (code != null) 'code': code,
        if (text != null) 'text': text,
        if (imageBase64 != null) 'imageBase64': imageBase64,
      };

  String encode() => jsonEncode(toJson());

  factory DisplayRemoteMessage.fromJson(Map<String, dynamic> json) {
    return DisplayRemoteMessage(
      type: json['type'] as String? ?? '',
      id: json['id'] as String?,
      code: json['code'] as String?,
      text: json['text'] as String?,
      imageBase64: json['imageBase64'] as String?,
    );
  }

  static DisplayRemoteMessage? tryParse(dynamic raw) {
    try {
      final map = raw is String
          ? jsonDecode(raw) as Map<String, dynamic>
          : Map<String, dynamic>.from(raw as Map);
      return DisplayRemoteMessage.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  factory DisplayRemoteMessage.auth(String code) =>
      DisplayRemoteMessage(type: typeAuth, code: code);

  factory DisplayRemoteMessage.expression(String id) =>
      DisplayRemoteMessage(type: typeExpression, id: id);

  factory DisplayRemoteMessage.custom({
    String text = '',
    String? imageBase64,
  }) =>
      DisplayRemoteMessage(
        type: typeCustom,
        text: text,
        imageBase64: imageBase64,
      );

  factory DisplayRemoteMessage.clearCmd() =>
      const DisplayRemoteMessage(type: typeClear);

  factory DisplayRemoteMessage.pingCmd() =>
      const DisplayRemoteMessage(type: typePing);
}
