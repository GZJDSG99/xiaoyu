import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'display_protocol.dart';

/// 显示端：本机 WebSocket 服务，等待遥控连接
class DisplayHostServer {
  DisplayHostServer({
    required this.onCommand,
    this.onClientChanged,
  });

  final void Function(DisplayRemoteMessage message) onCommand;
  final void Function(bool connected)? onClientChanged;

  HttpServer? _server;
  WebSocket? _socket;
  StreamSubscription? _socketSub;
  String _pairingCode = '';
  bool _authenticated = false;

  String get pairingCode => _pairingCode;
  bool get isRunning => _server != null;
  bool get hasClient => _socket != null && _authenticated;

  static String generatePairingCode() {
    final n = Random.secure().nextInt(1000000);
    return n.toString().padLeft(6, '0');
  }

  static Future<String?> localIPv4() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback) return addr.address;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> start({String? pairingCode}) async {
    await stop();
    _pairingCode = pairingCode ?? generatePairingCode();
    _server = await HttpServer.bind(
      InternetAddress.anyIPv4,
      kDisplayRemotePort,
      shared: true,
    );
    _server!.listen(_handleRequest);
  }

  Future<void> stop() async {
    await _detachSocket();
    await _server?.close(force: true);
    _server = null;
  }

  Future<void> _handleRequest(HttpRequest request) async {
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      final socket = await WebSocketTransformer.upgrade(request);
      await _attachSocket(socket);
      return;
    }

    if (request.method == 'GET' && request.uri.path == '/info') {
      request.response
        ..headers.contentType = ContentType.json
        ..headers.set('Access-Control-Allow-Origin', '*')
        ..headers.set('Access-Control-Allow-Methods', 'GET, OPTIONS')
        ..write(
          '{"app":"xiaoyu","role":"display-host",'
          '"port":$kDisplayRemotePort,"code":"$_pairingCode"}',
        );
      await request.response.close();
      return;
    }

    if (request.method == 'OPTIONS') {
      request.response
        ..statusCode = HttpStatus.noContent
        ..headers.set('Access-Control-Allow-Origin', '*')
        ..headers.set('Access-Control-Allow-Methods', 'GET, OPTIONS')
        ..headers.set('Access-Control-Allow-Headers', '*');
      await request.response.close();
      return;
    }

    request.response.statusCode = HttpStatus.notFound;
    await request.response.close();
  }

  Future<void> _attachSocket(WebSocket socket) async {
    await _detachSocket();
    _socket = socket;
    _authenticated = false;
    onClientChanged?.call(false);

    _socketSub = socket.listen(
      (data) {
        final msg = DisplayRemoteMessage.tryParse(data);
        if (msg == null) return;
        _onMessage(msg);
      },
      onDone: () {
        _socket = null;
        _authenticated = false;
        onClientChanged?.call(false);
      },
      onError: (_) {
        _socket = null;
        _authenticated = false;
        onClientChanged?.call(false);
      },
      cancelOnError: true,
    );
  }

  void _onMessage(DisplayRemoteMessage msg) {
    switch (msg.type) {
      case DisplayRemoteMessage.typeAuth:
        if (msg.code == _pairingCode) {
          _authenticated = true;
          _send(
            const DisplayRemoteMessage(type: DisplayRemoteMessage.typeAuthOk),
          );
          onClientChanged?.call(true);
        } else {
          _send(
            const DisplayRemoteMessage(type: DisplayRemoteMessage.typeAuthFail),
          );
          unawaited(_detachSocket());
        }
      case DisplayRemoteMessage.typePing:
        if (_authenticated) {
          _send(
            const DisplayRemoteMessage(type: DisplayRemoteMessage.typePong),
          );
        }
      case DisplayRemoteMessage.typeExpression:
      case DisplayRemoteMessage.typeCustom:
      case DisplayRemoteMessage.typeClear:
        if (_authenticated) onCommand(msg);
      default:
        break;
    }
  }

  void _send(DisplayRemoteMessage msg) {
    _socket?.add(msg.encode());
  }

  Future<void> _detachSocket() async {
    await _socketSub?.cancel();
    _socketSub = null;
    try {
      await _socket?.close();
    } catch (_) {}
    _socket = null;
    _authenticated = false;
    onClientChanged?.call(false);
  }
}
