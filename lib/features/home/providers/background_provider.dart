import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/local_storage.dart';
import '../../../data/models/home_background.dart';
import '../../../data/models/pet.dart';
import '../../pet/providers/current_pet_provider.dart';

/// 用户手动选择的背景（持久化）
class BackgroundNotifier extends StateNotifier<HomeBackgroundOption> {
  BackgroundNotifier(this._storage)
      : super(backgroundById(_storage.backgroundId));

  final LocalStorage _storage;

  Future<void> select(String id) async {
    await _storage.setBackgroundId(id);
    state = backgroundById(id);
  }

  /// 选宠后同步专属背景：有专属则切过去；当前是他人专属则回默认
  Future<void> syncForPet(Pet pet) async {
    final exclusiveId = pet.exclusiveBackgroundId;
    if (exclusiveId != null) {
      await select(exclusiveId);
      return;
    }
    if (state.exclusivePetId != null && state.exclusivePetId != pet.id) {
      await select(kDefaultBackgroundId);
    }
  }
}

final backgroundProvider =
    StateNotifierProvider<BackgroundNotifier, HomeBackgroundOption>((ref) {
  return BackgroundNotifier(ref.watch(localStorageProvider));
});

/// 每分钟刷新，保证跨过 19:00 / 05:00 时切换有效背景
final _clockProvider = StreamProvider<DateTime>((ref) {
  final controller = StreamController<DateTime>();
  controller.add(DateTime.now());
  final timer = Timer.periodic(const Duration(minutes: 1), (_) {
    if (!controller.isClosed) controller.add(DateTime.now());
  });
  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });
  return controller.stream;
});

/// 首页实际展示背景：夜间强制星空，白天用用户选择（校验专属）
final effectiveBackgroundProvider = Provider<HomeBackgroundOption>((ref) {
  final selected = ref.watch(backgroundProvider);
  final pet = ref.watch(currentPetProvider);
  final now =
      ref.watch(_clockProvider).asData?.value ?? DateTime.now();
  return effectiveBackground(selected, now, pet?.id);
});

/// 当前有效背景是否为星空（夜间或手动）
final isStarrySkyActiveProvider = Provider<bool>((ref) {
  return ref.watch(effectiveBackgroundProvider).id == kStarrySkyBackgroundId;
});
