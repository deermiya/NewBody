import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import '../models/data_models.dart';

class StorageService {
  static const _dataKey = 'newbody-data';
  static const _planKey = 'newbody-plan';
  static const _equipmentKey = 'newbody-equipment';
  static const _exercisePlanKey = 'newbody-exercise-plan';
  static const _syncKey = 'newbody-sync-key';

  static Future<AppData> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_dataKey);
    if (raw != null) {
      try {
        return AppData.fromJson(jsonDecode(raw));
      } catch (_) {}
    }
    return AppData();
  }

  static Future<void> saveData(AppData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dataKey, jsonEncode(data.toJson()));
  }

  static Future<WeekPlan?> loadPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_planKey);
    if (raw != null) {
      try {
        return WeekPlan.fromJson(jsonDecode(raw));
      } catch (_) {}
    }
    return null;
  }

  static Future<void> savePlan(WeekPlan plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_planKey, jsonEncode(plan.toJson()));
  }

  static Future<List<String>> loadEquipment() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_equipmentKey) ?? [];
  }

  static Future<void> saveEquipment(List<String> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_equipmentKey, list);
  }

  static Future<WeekExercisePlan?> loadExercisePlan() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_exercisePlanKey);
    if (raw != null) {
      try {
        return WeekExercisePlan.fromJson(jsonDecode(raw));
      } catch (_) {}
    }
    return null;
  }

  static Future<void> saveExercisePlan(WeekExercisePlan plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_exercisePlanKey, jsonEncode(plan.toJson()));
  }

  static Future<String?> loadSyncKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_syncKey);
  }

  static Future<void> saveSyncKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_syncKey, key);
  }

  static Future<Map<String, dynamic>> exportSnapshot() async {
    final data = await loadData();
    final plan = await loadPlan();
    final equipment = await loadEquipment();
    final exercisePlan = await loadExercisePlan();

    return {
      'schema_version': 1,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'config': AppConfig.toJson(),
      'data': data.toJson(),
      'plan': plan?.toJson(),
      'equipment': equipment,
      'exercise_plan': exercisePlan?.toJson(),
    };
  }

  static Future<void> importSnapshot(Map<String, dynamic> snapshot) async {
    final prefs = await SharedPreferences.getInstance();

    final config = snapshot['config'];
    if (config is Map<String, dynamic>) {
      AppConfig.applyJson(config);
      await AppConfig.save();
    }

    final data = snapshot['data'];
    if (data is Map<String, dynamic>) {
      await saveData(AppData.fromJson(data));
    }

    final plan = snapshot['plan'];
    if (plan is Map<String, dynamic>) {
      await savePlan(WeekPlan.fromJson(plan));
    } else if (snapshot.containsKey('plan')) {
      await prefs.remove(_planKey);
    }

    final equipment = snapshot['equipment'];
    if (equipment is List) {
      await saveEquipment(equipment.map((e) => e.toString()).toList());
    }

    final exercisePlan = snapshot['exercise_plan'];
    if (exercisePlan is Map<String, dynamic>) {
      await saveExercisePlan(WeekExercisePlan.fromJson(exercisePlan));
    } else if (snapshot.containsKey('exercise_plan')) {
      await prefs.remove(_exercisePlanKey);
    }
  }
}
