import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// 屏幕常亮与系统 UI 控制（全屏显示页使用）
class ScreenService {
  Future<void> keepAwake() async {
    await WakelockPlus.enable();
  }

  Future<void> allowSleep() async {
    await WakelockPlus.disable();
  }

  Future<void> enterFullscreen() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await keepAwake();
  }

  Future<void> exitFullscreen() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    // 保持全局横屏，不恢复竖屏
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await allowSleep();
  }
}
