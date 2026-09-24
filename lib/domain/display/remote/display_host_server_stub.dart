import 'display_protocol.dart';

/// Web / 无 dart:io 环境占位
class DisplayHostServer {
  DisplayHostServer({
    required this.onCommand,
    this.onClientChanged,
  });

  final void Function(DisplayRemoteMessage message) onCommand;
  final void Function(bool connected)? onClientChanged;

  String get pairingCode => '';
  bool get isRunning => false;
  bool get hasClient => false;

  static String generatePairingCode() => '000000';

  static Future<String?> localIPv4() async => null;

  Future<void> start({String? pairingCode}) async {
    throw UnsupportedError('显示端仅支持 Android / iOS / 桌面');
  }

  Future<void> stop() async {}
}
