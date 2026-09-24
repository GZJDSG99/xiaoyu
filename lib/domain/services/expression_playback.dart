import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/images/asset_warmup.dart';
import '../../data/models/custom_expression.dart';
import '../../data/models/expression.dart';
import '../../data/repositories/pet_repository.dart';
import '../display/remote/display_session.dart';
import 'expression_service.dart';

/// 与首页快捷栏一致：已连接显示端则只推送；否则本机全屏
Future<void> playExpressionFullscreen({
  required BuildContext context,
  required WidgetRef ref,
  required Expression expression,
}) async {
  final session = ref.read(displaySessionProvider);
  if (session.isConnected) {
    await ref.read(expressionServiceProvider).play(expression);
    try {
      await ref.read(displaySessionProvider.notifier).sendExpression(expression.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已发送到显示器'),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('发送失败：$e')),
      );
    }
    return;
  }

  final repo = ref.read(petRepositoryProvider);
  final pet = await repo.getCurrent() ?? repo.getById('cat');
  if (!expression.hasStickerAsset) {
    final actionAsset = pet?.resolveAsset(action: expression.petAction);
    if (context.mounted && actionAsset != null) {
      await AssetWarmup.warmAction(context, actionAsset);
    }
  }
  await ref.read(expressionServiceProvider).play(expression);
  if (!context.mounted) return;
  context.push('/display?id=${expression.id}');
}

Future<void> playCustomFullscreen({
  required BuildContext context,
  required WidgetRef ref,
  required CustomExpression expression,
}) async {
  final session = ref.read(displaySessionProvider);
  await ref.read(expressionServiceProvider).previewCustom(expression);

  if (session.isConnected) {
    try {
      await ref.read(displaySessionProvider.notifier).sendCustom(expression);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已发送到显示器'),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('发送失败：$e')),
      );
    }
    return;
  }

  if (!context.mounted) return;
  final text = expression.text;
  final query = text.isEmpty ? '' : '?text=${Uri.encodeComponent(text)}';
  context.push('/display$query');
}
