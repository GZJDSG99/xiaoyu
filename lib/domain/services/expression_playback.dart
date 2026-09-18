import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/images/asset_warmup.dart';
import '../../data/models/expression.dart';
import '../../data/repositories/pet_repository.dart';
import 'expression_service.dart';

/// 与首页快捷栏一致：预热动作 GIF → 播放 → 全屏展示
Future<void> playExpressionFullscreen({
  required BuildContext context,
  required WidgetRef ref,
  required Expression expression,
}) async {
  final repo = ref.read(petRepositoryProvider);
  final pet = await repo.getCurrent() ?? repo.getById('cat');
  final actionAsset = pet?.resolveAsset(action: expression.petAction);
  if (context.mounted && actionAsset != null) {
    await AssetWarmup.warmAction(context, actionAsset);
  }
  await ref.read(expressionServiceProvider).play(expression);
  if (!context.mounted) return;
  context.push('/display?id=${expression.id}');
}
