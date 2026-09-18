import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../data/models/home_background.dart';

/// 本地持久化：SharedPreferences（设置/当前宠物）+ Hive（收藏/最近/自定义）
class LocalStorage {
  LocalStorage(this._prefs, this._box);

  final SharedPreferences _prefs;
  final Box<dynamic> _box;

  static Future<LocalStorage> init() async {
    await Hive.initFlutter();
    final prefs = await SharedPreferences.getInstance();
    final box = await Hive.openBox<dynamic>(HiveBoxes.app);
    return LocalStorage(prefs, box);
  }

  bool get isFirstLaunch => _prefs.getBool(StorageKeys.firstLaunch) ?? true;

  Future<void> setFirstLaunchComplete() async {
    await _prefs.setBool(StorageKeys.firstLaunch, false);
  }

  String? get currentPetId => _prefs.getString(StorageKeys.currentPetId);

  Future<void> setCurrentPetId(String petId) async {
    await _prefs.setString(StorageKeys.currentPetId, petId);
  }

  List<String> get favoriteExpressions {
    final raw = _box.get(StorageKeys.favoriteExpressions);
    if (raw is List) {
      return raw.cast<String>();
    }
    return const [];
  }

  Future<void> setFavoriteExpressions(List<String> ids) async {
    await _box.put(StorageKeys.favoriteExpressions, ids);
  }

  List<String> get recentExpressions {
    final raw = _box.get(StorageKeys.recentExpressions);
    if (raw is List) {
      return raw.cast<String>();
    }
    return const [];
  }

  Future<void> setRecentExpressions(List<String> ids) async {
    await _box.put(StorageKeys.recentExpressions, ids);
  }

  List<Map<String, dynamic>> get customExpressions {
    final raw = _box.get(StorageKeys.customExpressions);
    if (raw is String && raw.isNotEmpty) {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    if (raw is List) {
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return <Map<String, dynamic>>[];
  }

  Future<void> setCustomExpressions(List<Map<String, dynamic>> items) async {
    await _box.put(StorageKeys.customExpressions, jsonEncode(items));
  }

  String get backgroundId =>
      _prefs.getString(StorageKeys.backgroundId) ?? kDefaultBackgroundId;

  Future<void> setBackgroundId(String id) async {
    await _prefs.setString(StorageKeys.backgroundId, id);
  }
}

final localStorageProvider = Provider<LocalStorage>((ref) {
  throw UnimplementedError(
    'localStorageProvider 需在 main 中 override',
  );
});
