import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/local_storage.dart';
import '../../data/models/pet.dart';
import '../../data/models/pet_enums.dart';
import '../../data/repositories/pet_repository.dart';

/// 宠物业务：当前宠物、状态切换
class PetService {
  PetService(this._repository, this._storage);

  final PetRepository _repository;
  final LocalStorage _storage;

  PetState _state = PetState.idle;

  PetState get state => _state;

  List<Pet> getAll() => _repository.getAll();

  Future<Pet?> getCurrent() => _repository.getCurrent();

  Future<void> selectPet(String petId, {bool completeFirstLaunch = false}) async {
    final pet = _repository.getById(petId);
    if (pet == null || !pet.available) {
      throw StateError('该宠物暂不可选：$petId');
    }
    await _repository.setCurrent(petId);
    if (completeFirstLaunch) {
      await _storage.setFirstLaunchComplete();
    }
    _state = PetState.idle;
  }

  void applyAction(PetAction action) {
    _state = petStateForAction(action);
  }

  void resetToIdle() {
    _state = PetState.idle;
  }
}

final petServiceProvider = Provider<PetService>((ref) {
  return PetService(
    ref.watch(petRepositoryProvider),
    ref.watch(localStorageProvider),
  );
});
