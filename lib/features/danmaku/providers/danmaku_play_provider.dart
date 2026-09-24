import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/danmaku_config.dart';

/// 全屏弹幕待播放配置（壳外路由读取）
final pendingDanmakuConfigProvider = StateProvider<DanmakuConfig?>((ref) => null);
