import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../data/local/local_storage.dart';
import '../../../data/models/custom_expression.dart';
import 'display_protocol.dart';

enum DisplaySessionStatus {
  disconnected,
  connecting,
  connected,
  error,
}

class DisplaySessionState {
  const DisplaySessionState({
    this.status = DisplaySessionStatus.disconnected,
    this.host = '',
    this.errorMessage,
  });

  final DisplaySessionStatus status;
  final String host;
  final String? errorMessage;

  bool get isConnected => status == DisplaySessionStatus.connected;

  DisplaySessionState copyWith({
    DisplaySessionStatus? status,
    String? host,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DisplaySessionState(
      status: status ?? this.status,
      host: host ?? this.host,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// 遥控端：连接七寸显示端并发送指令
class DisplaySessionNotifier extends StateNotifier<DisplaySessionState> {
  DisplaySessionNotifier(this._storage) : super(const DisplaySessionState()) {
    final saved = _storage.displayRemoteHost;
    if (saved != null && saved.isNotEmpty) {
      state = state.copyWith(host: saved);
    }
  }

  final LocalStorage _storage;
  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _pingTimer;
  Completer<bool>? _authCompleter;

  bool get isConnected => state.isConnected;

  List<String> _hostCandidates(String host) {
    final h = host.trim();
    if (h == '127.0.0.1') return ['127.0.0.1', 'localhost'];
    if (h == 'localhost') return ['localhost', '127.0.0.1'];
    return [h];
  }

  Future<String?> _probeInfo(String host) async {
    try {
      final uri = Uri(
        scheme: 'http',
        host: host,
        port: kDisplayRemotePort,
        path: '/info',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 2));
      if (res.statusCode != 200) return null;
      final map = jsonDecode(res.body) as Map<String, dynamic>;
      return map['code'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<bool> connect({
    required String host,
    required String code,
  }) async {
    final trimmedHost = host.trim();
    final trimmedCode = code.trim();
    if (trimmedHost.isEmpty || trimmedCode.isEmpty) {
      state = state.copyWith(
        status: DisplaySessionStatus.error,
        errorMessage: '请填写 IP 与配对码',
      );
      return false;
    }

    await disconnect(keepHost: true);
    state = state.copyWith(
      status: DisplaySessionStatus.connecting,
      host: trimmedHost,
      clearError: true,
    );

    final candidates = _hostCandidates(trimmedHost);
    Object? lastError;

    for (final candidate in candidates) {
      // Web/Chrome：先探测 HTTP，避免 WebSocket 一直卡住
      final remoteCode = await _probeInfo(candidate);
      if (remoteCode == null) {
        lastError =
            '无法访问 $candidate:$kDisplayRemotePort。Chrome+MuMu 请填 127.0.0.1，并执行：adb forward tcp:17890 tcp:17890';
        continue;
      }
      if (remoteCode != trimmedCode) {
        state = state.copyWith(
          status: DisplaySessionStatus.error,
          host: candidate,
          errorMessage: '配对码不对。显示端当前是 $remoteCode，请照抄最新配对码',
        );
        return false;
      }

      try {
        final ok = await _connectOnce(
          trimmedHost: candidate,
          trimmedCode: trimmedCode,
        ).timeout(const Duration(seconds: 10));
        if (ok) return true;
        lastError = '配对失败';
      } catch (e) {
        lastError = e;
        await disconnect(keepHost: true);
        if (kDebugMode) {
          debugPrint('DisplaySession.connect try $candidate failed: $e');
        }
      }
    }

    state = state.copyWith(
      status: DisplaySessionStatus.error,
      host: trimmedHost,
      errorMessage: '连接失败：$lastError',
    );
    return false;
  }

  Future<bool> _connectOnce({
    required String trimmedHost,
    required String trimmedCode,
  }) async {
    final uri = Uri(
      scheme: 'ws',
      host: trimmedHost,
      port: kDisplayRemotePort,
      path: '/',
    );
    final channel = WebSocketChannel.connect(uri);
    _channel = channel;
    _authCompleter = Completer<bool>();

    _sub = channel.stream.listen(
      (data) {
        final msg = DisplayRemoteMessage.tryParse(data);
        if (msg == null) return;
        _onMessage(msg);
      },
      onDone: () {
        _onLost('连接已断开');
      },
      onError: (Object e) {
        _onLost('连接错误：$e');
      },
      cancelOnError: true,
    );

    await channel.ready.timeout(
      const Duration(seconds: 6),
      onTimeout: () {
        throw TimeoutException('WebSocket 握手超时');
      },
    );
    channel.sink.add(DisplayRemoteMessage.auth(trimmedCode).encode());

    final ok = await _authCompleter!.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => false,
    );

    if (!ok) {
      await disconnect(keepHost: true);
      return false;
    }

    await _storage.setDisplayRemoteHost(trimmedHost);
    await _storage.setDisplayRemoteCode(trimmedCode);
    state = state.copyWith(
      status: DisplaySessionStatus.connected,
      host: trimmedHost,
      clearError: true,
    );
    _startPing();
    return true;
  }

  Future<void> disconnect({bool keepHost = false}) async {
    _pingTimer?.cancel();
    _pingTimer = null;
    final sub = _sub;
    _sub = null;
    final channel = _channel;
    _channel = null;

    try {
      await sub?.cancel().timeout(const Duration(milliseconds: 500));
    } catch (_) {}

    try {
      await channel?.sink.close().timeout(const Duration(milliseconds: 800));
    } catch (_) {}

    if (!(_authCompleter?.isCompleted ?? true)) {
      _authCompleter?.complete(false);
    }
    _authCompleter = null;
    state = DisplaySessionState(
      status: DisplaySessionStatus.disconnected,
      host: keepHost ? state.host : state.host,
      errorMessage: null,
    );
  }

  Future<void> sendExpression(String id) async {
    _requireConnected();
    _channel!.sink.add(DisplayRemoteMessage.expression(id).encode());
  }

  Future<void> sendCustom(CustomExpression expression) async {
    _requireConnected();
    _channel!.sink.add(
      DisplayRemoteMessage.custom(
        text: expression.text,
        imageBase64: expression.imageBase64,
      ).encode(),
    );
  }

  Future<void> sendClear() async {
    if (!isConnected) return;
    _channel!.sink.add(DisplayRemoteMessage.clearCmd().encode());
  }

  void _requireConnected() {
    if (!isConnected || _channel == null) {
      throw StateError('显示端未连接');
    }
  }

  void _onMessage(DisplayRemoteMessage msg) {
    switch (msg.type) {
      case DisplayRemoteMessage.typeAuthOk:
        if (!(_authCompleter?.isCompleted ?? true)) {
          _authCompleter?.complete(true);
        }
      case DisplayRemoteMessage.typeAuthFail:
        if (!(_authCompleter?.isCompleted ?? true)) {
          _authCompleter?.complete(false);
        }
      case DisplayRemoteMessage.typePong:
        break;
      default:
        break;
    }
  }

  void _onLost(String message) {
    _pingTimer?.cancel();
    _pingTimer = null;
    if (!(_authCompleter?.isCompleted ?? true)) {
      _authCompleter?.complete(false);
    }
    _channel = null;
    if (state.status == DisplaySessionStatus.connecting) {
      return;
    }
    state = state.copyWith(
      status: DisplaySessionStatus.disconnected,
      errorMessage: message,
    );
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      if (!isConnected || _channel == null) return;
      try {
        _channel!.sink.add(DisplayRemoteMessage.pingCmd().encode());
      } catch (_) {
        _onLost('心跳失败');
      }
    });
  }

  @override
  void dispose() {
    unawaited(disconnect());
    super.dispose();
  }
}

final displaySessionProvider =
    StateNotifierProvider<DisplaySessionNotifier, DisplaySessionState>((ref) {
  return DisplaySessionNotifier(ref.watch(localStorageProvider));
});
