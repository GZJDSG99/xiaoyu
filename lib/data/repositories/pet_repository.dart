import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local/local_storage.dart';
import '../models/home_background.dart';
import '../models/pet.dart';
import '../models/pet_enums.dart';

/// V1.0 默认 7 只宠物（素材后续替换为原创资产）
const kDefaultPets = <Pet>[
  Pet(
    id: 'cat',
    name: 'KK',
    personality: '温柔治愈',
    emoji: '🐱',
    recommendedEmotions: ['谢谢', '抱歉', '开心'],
    assetPath: 'assets/pets/cat/xiaoyu-miao-breath.webp',
    cardAssetPath: 'assets/pets/cat/xiaoyu-miao-card.gif',
    actionAssets: {
      PetAction.goodbye: 'assets/pets/cat/xiaoyu-miao-byb.gif',
      PetAction.love: 'assets/pets/cat/xiaoyu-miao-happy.webp',
      PetAction.thank: 'assets/pets/cat/xiaoyu-miao-thanks.webp',
      PetAction.laugh: 'assets/pets/cat/laugh.webp',
      PetAction.sleep: 'assets/pets/cat/sleep.webp',
    },
    jumpAssetPath: 'assets/pets/cat/jump.webp',
    sleepAssetPath: 'assets/pets/cat/home-sleep.webp',
    transformAssetPath: 'assets/pets/cat/change-kk.webp',
    transformedIdleAssetPath: 'assets/pets/cat/kk.webp',
  ),
  Pet(
    id: 'bear',
    name: '酷B',
    personality: '酷炫自信',
    emoji: '🐻',
    recommendedEmotions: ['收到', '感谢'],
    assetPath: 'assets/pets/bear/coolBear-wink.webp',
    cardAssetPath: 'assets/pets/bear/coolBear-wink.webp',
    exclusiveBackgroundId: kCoolBgBackgroundId,
    available: true,
  ),
  Pet(
    id: 'dog',
    name: '小狗',
    personality: '活泼开朗',
    emoji: '🐶',
    recommendedEmotions: ['打招呼', '再见'],
    assetPath: 'assets/pets/dog/',
    available: false,
  ),
  Pet(
    id: 'rabbit',
    name: '小兔',
    personality: '可爱灵动',
    emoji: '🐰',
    recommendedEmotions: ['开心', '撒娇'],
    assetPath: 'assets/pets/rabbit/',
    available: false,
  ),
  Pet(
    id: 'dinosaur',
    name: '小恐龙',
    personality: '勇敢有趣',
    emoji: '🦖',
    recommendedEmotions: ['加油', '鼓励'],
    assetPath: 'assets/pets/dinosaur/',
    available: false,
  ),
  Pet(
    id: 'penguin',
    name: '小企鹅',
    personality: '呆萌冷静',
    emoji: '🐧',
    recommendedEmotions: ['搞怪', '吐槽'],
    assetPath: 'assets/pets/penguin/',
    available: false,
  ),
  Pet(
    id: 'robot',
    name: '小机器人',
    personality: '科技感',
    emoji: '🤖',
    recommendedEmotions: ['默认', '未来'],
    assetPath: 'assets/pets/robot/',
    available: false,
  ),
];

abstract class PetRepository {
  List<Pet> getAll();
  Pet? getById(String id);
  Future<Pet?> getCurrent();
  Future<void> setCurrent(String petId);
}

class LocalPetRepository implements PetRepository {
  LocalPetRepository(this._storage);

  final LocalStorage _storage;

  @override
  List<Pet> getAll() => kDefaultPets;

  @override
  Pet? getById(String id) {
    try {
      return kDefaultPets.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Pet?> getCurrent() async {
    final id = _storage.currentPetId ?? 'cat';
    return getById(id) ?? getById('cat');
  }

  @override
  Future<void> setCurrent(String petId) async {
    await _storage.setCurrentPetId(petId);
  }
}

final petRepositoryProvider = Provider<PetRepository>((ref) {
  return LocalPetRepository(ref.watch(localStorageProvider));
});
