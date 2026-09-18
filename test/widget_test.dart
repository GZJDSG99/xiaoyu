import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:xiaoyu/app/theme/app_colors.dart';
import 'package:xiaoyu/core/constants/app_constants.dart';
import 'package:xiaoyu/data/local/local_storage.dart';
import 'package:xiaoyu/data/models/pet.dart';
import 'package:xiaoyu/data/repositories/pet_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({
      StorageKeys.firstLaunch: false,
      StorageKeys.currentPetId: 'cat',
    });
    Hive.init('test_hive');
  });

  test('default pets include 7 companions', () {
    expect(kDefaultPets.length, 7);
    expect(kDefaultPets.first.id, 'cat');
  });

  test('AppColors match design tokens', () {
    expect(AppColors.background, const Color(0xFF07101C));
    expect(AppColors.primary, const Color(0xFF75B9FF));
  });

  test('LocalStorage reads current pet', () async {
    final prefs = await SharedPreferences.getInstance();
    final box = await Hive.openBox<dynamic>('test_app');
    final storage = LocalStorage(prefs, box);
    expect(storage.currentPetId, 'cat');
    expect(storage.isFirstLaunch, false);
    await box.close();
  });

  test('PetRepository resolves current pet', () async {
    final prefs = await SharedPreferences.getInstance();
    final box = await Hive.openBox<dynamic>('test_app_2');
    final storage = LocalStorage(prefs, box);
    final repo = LocalPetRepository(storage);
    final pet = await repo.getCurrent();
    expect(pet, isA<Pet>());
    expect(pet!.name, 'KK');
    await box.close();
  });
}
