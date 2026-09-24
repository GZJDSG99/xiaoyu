import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/local_storage.dart';
import '../../../data/models/pet.dart';
import '../../../data/repositories/pet_repository.dart';

/// 当前选中的宠物（可监听，避免 Shell 保活导致首页不刷新）
class CurrentPetNotifier extends StateNotifier<Pet?> {
  CurrentPetNotifier(this._repo, this._storage)
      : super(_resolve(_repo, _storage));

  final PetRepository _repo;
  final LocalStorage _storage;

  static Pet? _resolve(PetRepository repo, LocalStorage storage) {
    final id = storage.currentPetId ?? 'cat';
    final pet = repo.getById(id);
    if (pet != null && pet.available) return pet;
    return repo.getById('cat');
  }

  void setPet(Pet pet) {
    state = pet;
  }

  void syncFromStorage() {
    state = _resolve(_repo, _storage);
  }
}

final currentPetProvider =
    StateNotifierProvider<CurrentPetNotifier, Pet?>((ref) {
  return CurrentPetNotifier(
    ref.watch(petRepositoryProvider),
    ref.watch(localStorageProvider),
  );
});
