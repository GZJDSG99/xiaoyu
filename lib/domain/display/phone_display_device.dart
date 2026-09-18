import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/custom_expression.dart';
import '../../data/models/expression.dart';
import 'display_device.dart';

/// V1.0：手机全屏显示实现（具体导航由 UI 层配合）
class PhoneDisplayDevice implements DisplayDevice {
  Expression? _current;
  CustomExpression? _currentCustom;
  bool _connected = true;

  @override
  bool get isConnected => _connected;

  @override
  Future<void> connect() async {
    _connected = true;
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
    await clear();
  }

  @override
  Future<void> show(Expression expression) async {
    _currentCustom = null;
    _current = expression;
  }

  @override
  Future<void> showCustom(CustomExpression expression) async {
    _current = null;
    _currentCustom = expression;
  }

  @override
  Future<void> clear() async {
    _current = null;
    _currentCustom = null;
  }

  Expression? get currentExpression => _current;
  CustomExpression? get currentCustom => _currentCustom;
}

/// 预留：未来 BLE LED 硬件
class BluetoothDisplayDevice implements DisplayDevice {
  @override
  bool get isConnected => false;

  @override
  Future<void> connect() async {
    throw UnimplementedError('BLE 将在 V2.0 实现');
  }

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> show(Expression expression) async {
    throw UnimplementedError('BLE 将在 V2.0 实现');
  }

  @override
  Future<void> showCustom(CustomExpression expression) async {
    throw UnimplementedError('BLE 将在 V2.0 实现');
  }

  @override
  Future<void> clear() async {}
}

final displayDeviceProvider = Provider<DisplayDevice>((ref) {
  return PhoneDisplayDevice();
});
