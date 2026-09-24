import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/custom_expression.dart';
import 'display_protocol.dart';

/// 显示端当前展示内容
class HostDisplayContent {
  const HostDisplayContent.idle()
      : expressionId = null,
        custom = null;

  const HostDisplayContent.expression(this.expressionId) : custom = null;

  const HostDisplayContent.custom(this.custom) : expressionId = null;

  final String? expressionId;
  final CustomExpression? custom;

  bool get hasContent => expressionId != null || custom != null;
}

class HostDisplayContentNotifier extends StateNotifier<HostDisplayContent> {
  HostDisplayContentNotifier() : super(const HostDisplayContent.idle());

  void applyMessage(DisplayRemoteMessage msg) {
    switch (msg.type) {
      case DisplayRemoteMessage.typeExpression:
        final id = msg.id;
        if (id == null || id.isEmpty) return;
        state = HostDisplayContent.expression(id);
      case DisplayRemoteMessage.typeCustom:
        state = HostDisplayContent.custom(
          CustomExpression(
            id: 'remote_${DateTime.now().millisecondsSinceEpoch}',
            text: msg.text ?? '',
            imageBase64: msg.imageBase64,
          ),
        );
      case DisplayRemoteMessage.typeClear:
        state = const HostDisplayContent.idle();
      default:
        break;
    }
  }

  void clear() => state = const HostDisplayContent.idle();
}

final hostDisplayContentProvider =
    StateNotifierProvider<HostDisplayContentNotifier, HostDisplayContent>(
  (ref) => HostDisplayContentNotifier(),
);
