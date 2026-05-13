import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/data_models.dart';
import '../services/storage_service.dart';
import '../widgets/common.dart';

class ImportPlanPage extends StatefulWidget {
  const ImportPlanPage({super.key});

  @override
  State<ImportPlanPage> createState() => _ImportPlanPageState();
}

class _ImportPlanPageState extends State<ImportPlanPage> {
  final _controller = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _importPlan() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _error = '先粘贴一段计划 JSON');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final decoded = jsonDecode(_extractJson(text));
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('JSON 根节点必须是对象');
      }

      var importedDiet = false;
      var importedExercise = false;

      final dietObj = _findPlanObject(decoded, isExercise: false);
      if (dietObj != null) {
        await StorageService.savePlan(WeekPlan.fromJson(dietObj));
        importedDiet = true;
      }

      final exerciseObj = _findPlanObject(decoded, isExercise: true);
      if (exerciseObj != null) {
        await StorageService.saveExercisePlan(
          WeekExercisePlan.fromJson(exerciseObj),
        );
        importedExercise = true;
      }

      if (!importedDiet && !importedExercise) {
        throw const FormatException('没有识别到饮食计划或运动计划');
      }

      if (!mounted) return;
      Navigator.of(
        context,
      ).pop(ImportPlanResult(importedDiet, importedExercise));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = '导入失败：${e.toString().replaceFirst('FormatException: ', '')}';
      });
    }
  }

  String _extractJson(String raw) {
    var text = raw
        .replaceAll(RegExp(r'```json\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'```\s*'), '')
        .trim();
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start == -1 || end <= start) {
      throw const FormatException('没有找到 JSON 对象');
    }
    return text.substring(start, end + 1);
  }

  Map<String, dynamic>? _findPlanObject(
    Map<String, dynamic> obj, {
    required bool isExercise,
  }) {
    if (_matchesPlanType(obj, isExercise: isExercise)) return obj;

    const keys = [
      'diet_plan',
      'dietPlan',
      'meal_plan',
      'mealPlan',
      'food_plan',
      'foodPlan',
      'exercise_plan',
      'exercisePlan',
      'workout_plan',
      'workoutPlan',
      'plan',
    ];
    for (final key in keys) {
      final value = obj[key];
      if (value is Map<String, dynamic> &&
          _matchesPlanType(value, isExercise: isExercise)) {
        return value;
      }
    }
    return null;
  }

  bool _matchesPlanType(Map<String, dynamic> obj, {required bool isExercise}) {
    final days = obj['days'];
    if (days is! List || days.isEmpty) return false;
    final first = days.first;
    if (first is! Map) return false;
    return isExercise
        ? first.containsKey('exercises') || first.containsKey('total_cal')
        : first.containsKey('meals') ||
              first.containsKey('total_intake') ||
              first.containsKey('total_burn');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '粘贴计划 JSON',
                          style: TextStyle(
                            color: C.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '支持饮食周计划、运动周计划，或同时包含两者的 JSON。',
                          style: TextStyle(
                            color: C.textMuted,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _controller,
                          minLines: 12,
                          maxLines: 18,
                          style: const TextStyle(
                            color: C.textPrimary,
                            fontSize: 13,
                            height: 1.4,
                          ),
                          decoration: InputDecoration(
                            hintText: '{"days":[{"day":"周一","meals":...}]}',
                            hintStyle: const TextStyle(color: C.textDim),
                            filled: true,
                            fillColor: C.bg,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: C.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: C.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: C.green),
                            ),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            style: const TextStyle(
                              color: C.rose,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        GestureDetector(
                          onTap: _saving ? null : _importPlan,
                          child: Container(
                            width: double.infinity,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: C.primaryGradient,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.center,
                            child: _saving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.upload_file_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        '导入到 APP',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: C.border, width: 0.5)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: C.bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: C.textSecondary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.data_object_rounded, color: C.green, size: 22),
          const SizedBox(width: 10),
          const Text(
            '导入计划',
            style: TextStyle(
              color: C.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class ImportPlanResult {
  final bool importedDiet;
  final bool importedExercise;

  const ImportPlanResult(this.importedDiet, this.importedExercise);
}
