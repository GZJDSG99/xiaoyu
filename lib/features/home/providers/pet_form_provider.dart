import 'package:flutter_riverpod/flutter_riverpod.dart';

/// KK 是否处于变身后形态（人形态待机 kk.gif）
final kkTransformedProvider = StateProvider<bool>((ref) => false);

/// 顶栏变身/还原点击信号（递增触发 PetWithBubble 执行）
final transformTapProvider = StateProvider<int>((ref) => 0);
