import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/custom_expression.dart';
import '../../data/models/expression.dart';
import '../../data/repositories/expression_repository.dart';
import '../display/display_device.dart';
import '../display/phone_display_device.dart';

/// 自定义表情列表变更计数（触发表情页刷新）
final customExpressionsTickProvider = StateProvider<int>((ref) => 0);

/// 表情业务：最近使用、收藏、推送到 DisplayDevice
class ExpressionService {
  ExpressionService(
    this._repository,
    this._display, {
    void Function()? onCustomChanged,
  }) : _onCustomChanged = onCustomChanged;

  final ExpressionRepository _repository;
  final DisplayDevice _display;
  final void Function()? _onCustomChanged;

  List<Expression> getQuickExpressions() {
    final recent = _repository.getRecent();
    if (recent.isNotEmpty) return recent.take(6).toList();
    return _repository.getAll().take(6).toList();
  }

  /// 首页底部快捷栏（固定设计稿顺序）
  List<Expression> getHomeDockExpressions() {
    return kHomeDockExpressionIds
        .map(_repository.getById)
        .whereType<Expression>()
        .toList();
  }

  Future<void> play(Expression expression) async {
    await _repository.addRecent(expression.id);
    await _display.show(expression);
  }

  /// 仅全屏预览，不写入自定义列表
  Future<void> previewCustom(CustomExpression expression) {
    return _display.showCustom(expression);
  }

  /// 仅保存到「自定义」分类
  Future<void> saveCustom(CustomExpression expression) async {
    await _repository.saveCustom(expression);
    _onCustomChanged?.call();
  }

  /// 从「自定义」分类删除
  Future<void> deleteCustom(String id) async {
    await _repository.deleteCustom(id);
    _onCustomChanged?.call();
  }

  /// 保存并展示（兼容旧调用）
  Future<void> playCustom(CustomExpression expression) async {
    await saveCustom(expression);
    await _display.showCustom(expression);
  }

  Future<void> toggleFavorite(String expressionId) {
    return _repository.toggleFavorite(expressionId);
  }
}

final expressionServiceProvider = Provider<ExpressionService>((ref) {
  return ExpressionService(
    ref.watch(expressionRepositoryProvider),
    ref.watch(displayDeviceProvider),
    onCustomChanged: () {
      ref.read(customExpressionsTickProvider.notifier).state++;
    },
  );
});
