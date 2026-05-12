import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/data_models.dart';

class StorageService {
  static const _dataKey = 'newbody-data';
  static const _planKey = 'newbody-plan';
  static const _equipmentKey = 'newbody-equipment';
  static const _exercisePlanKey = 'newbody-exercise-plan';

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
}
