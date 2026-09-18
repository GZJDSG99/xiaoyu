import '../../data/models/custom_expression.dart';
import '../../data/models/expression.dart';

/// 显示设备抽象 —— V1 手机屏，V2 BLE LED 硬件可替换实现
abstract class DisplayDevice {
  Future<void> connect();

  Future<void> disconnect();

  Future<void> show(Expression expression);

  Future<void> showCustom(CustomExpression expression);

  Future<void> clear();

  bool get isConnected;
}
