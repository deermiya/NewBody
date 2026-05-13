import 'dart:convert';
import 'package:flutter/material.dart';
import '../config.dart';
import '../models/data_models.dart';
import '../services/ai_service.dart';
import '../services/storage_service.dart';
import '../widgets/common.dart';

class ExercisePage extends StatefulWidget {
  final AppData data;
  final void Function(AppData) updateData;
  final List<ExerciseEntry> todayExercise;
  final int todayBurn;

  const ExercisePage({
    super.key,
    required this.data,
    required this.updateData,
    required this.todayExercise,
    required this.todayBurn,
  });

  @override
  State<ExercisePage> createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage> {
  List<String> _equipment = [];
  WeekExercisePlan? _exercisePlan;
  WeekExercisePlan? _previewPlan;
  bool _loading = false;
  final _equipCtl = TextEditingController();
  final Set<String> _completedToday = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _equipCtl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final equip = await StorageService.loadEquipment();
    final plan = await StorageService.loadExercisePlan();
    setState(() {
      _equipment = equip;
      _exercisePlan = plan;
    });
  }

  void _addEquipment(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || _equipment.contains(trimmed)) return;
    setState(() => _equipment.add(trimmed));
    StorageService.saveEquipment(_equipment);
    _equipCtl.clear();
  }

  void _removeEquipment(String name) {
    setState(() => _equipment.remove(name));
    StorageService.saveEquipment(_equipment);
  }

  Future<void> _generatePlan() async {
    if (_equipment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('先添加你的器械'), backgroundColor: C.rose),
      );
      return;
    }
    setState(() {
      _loading = true;
      _previewPlan = null;
    });

    final latestWeight = widget.data.weightLog.isNotEmpty
        ? widget.data.weightLog.last.weight * 2
        : AppConfig.startWeight * 2;

    final result = await AIService.generateExercisePlan(
      equipment: _equipment,
      weightJin: latestWeight,
    );

    if (!mounted) return;

    try {
      // Try to extract JSON from the response
      String jsonStr = result.trim();
      final jsonStart = jsonStr.indexOf('{');
      final jsonEnd = jsonStr.lastIndexOf('}');
      if (jsonStart != -1 && jsonEnd != -1) {
        jsonStr = jsonStr.substring(jsonStart, jsonEnd + 1);
      }
      final parsed = WeekExercisePlan.fromJson(jsonDecode(jsonStr));
      setState(() {
        _previewPlan = parsed;
        _loading = false;
      });
    } catch (_) {
      final fallback = _buildFallbackPlan();
      setState(() {
        _previewPlan = fallback;
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('运动计划已生成'), backgroundColor: C.green),
      );
    }
  }

  WeekExercisePlan _buildFallbackPlan() {
    final strengthA = _fallbackEntries([
      _fallbackEntry('坐姿推举', _pickEquipment(['哑铃', '弹力带']), 3, '10次', 55),
      _fallbackEntry('靠墙俯卧撑', '徒手', 3, '12次', 45),
    ]);
    final strengthB = _fallbackEntries([
      _fallbackEntry('杯式深蹲', _pickEquipment(['哑铃', '壶铃']), 3, '12次', 70),
      _fallbackEntry('臀桥', _pickEquipment(['瑜伽垫']), 3, '15次', 45),
    ]);
    final strengthC = _fallbackEntries([
      _fallbackEntry(
        '弹力带划船',
        _pickEquipment(['弹力带', '拉力器', '哑铃']),
        3,
        '12次',
        55,
      ),
      _fallbackEntry('平板支撑', _pickEquipment(['瑜伽垫']), 3, '30秒', 40),
    ]);
    final strengthD = _fallbackEntries([
      _fallbackEntry('原地踏步', '徒手', 4, '60秒', 60),
      _fallbackEntry('拉伸放松', _pickEquipment(['瑜伽垫', '泡沫轴']), 2, '60秒', 25),
    ]);

    return WeekExercisePlan(
      days: [
        _fallbackDay('周一', '训练日', '上肢', strengthA),
        _restDay('周二'),
        _fallbackDay('周三', '训练日', '下肢', strengthB),
        _restDay('周四'),
        _fallbackDay('周五', '训练日', '背部核心', strengthC),
        _fallbackDay('周六', '训练日', '轻有氧', strengthD),
        _restDay('周日'),
      ],
    );
  }

  List<ExercisePlanEntry> _fallbackEntries(List<ExercisePlanEntry> entries) =>
      entries;

  ExercisePlanEntry _fallbackEntry(
    String name,
    String equipment,
    int sets,
    String reps,
    int cal,
  ) {
    return ExercisePlanEntry(
      name: name,
      equipment: equipment,
      sets: sets,
      reps: reps,
      rest: '60秒',
      cal: cal,
      tip: '慢一点，稳一点',
    );
  }

  ExerciseDayPlan _fallbackDay(
    String day,
    String type,
    String focus,
    List<ExercisePlanEntry> exercises,
  ) {
    return ExerciseDayPlan(
      day: day,
      type: type,
      focus: focus,
      exercises: exercises,
      totalCal: exercises.fold(0, (sum, e) => sum + e.cal),
      note: '按身体状态调整强度',
    );
  }

  ExerciseDayPlan _restDay(String day) {
    return ExerciseDayPlan(
      day: day,
      type: '休息日',
      focus: '恢复',
      exercises: const [],
      totalCal: 0,
      note: '散步或轻度拉伸',
    );
  }

  String _pickEquipment(List<String> preferred) {
    for (final item in preferred) {
      if (_equipment.contains(item)) return item;
    }
    return _equipment.isNotEmpty ? _equipment.first : '徒手';
  }

  void _savePlan() {
    if (_previewPlan == null) return;
    setState(() {
      _exercisePlan = _previewPlan;
      _previewPlan = null;
    });
    StorageService.saveExercisePlan(_exercisePlan!);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('运动计划已保存'), backgroundColor: C.green),
    );
  }

  void _completeExercise(ExercisePlanEntry entry) {
    if (_completedToday.contains(entry.name)) return;
    setState(() => _completedToday.add(entry.name));
    final exEntry = ExerciseEntry(
      name: entry.name,
      cal: entry.cal,
      icon: entry.equipment == '徒手' ? '💪' : '🏋️',
      date: todayStr(),
      time: nowTime(),
    );
    widget.updateData(
      AppData(
        weightLog: widget.data.weightLog,
        foodLog: widget.data.foodLog,
        exerciseLog: [...widget.data.exerciseLog, exEntry],
      ),
    );
  }

  void _addExercise(ExerciseItem ex) {
    final entry = ExerciseEntry(
      name: ex.name,
      cal: ex.cal,
      icon: ex.icon,
      date: todayStr(),
      time: nowTime(),
    );
    widget.updateData(
      AppData(
        weightLog: widget.data.weightLog,
        foodLog: widget.data.foodLog,
        exerciseLog: [...widget.data.exerciseLog, entry],
      ),
    );
  }

  void _removeExercise(int todayIndex) {
    final allWithIndex = <int>[];
    for (int i = 0; i < widget.data.exerciseLog.length; i++) {
      if (widget.data.exerciseLog[i].date == todayStr()) allWithIndex.add(i);
    }
    if (todayIndex >= allWithIndex.length) return;
    final removeAt = allWithIndex[todayIndex];
    final newList = List<ExerciseEntry>.from(widget.data.exerciseLog)
      ..removeAt(removeAt);
    widget.updateData(
      AppData(
        weightLog: widget.data.weightLog,
        foodLog: widget.data.foodLog,
        exerciseLog: newList,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final weekday = weekdayCN();

    return Container(
      color: C.bg,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '运动打卡',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: C.textPrimary,
                ),
              ),
              _buildBurnBadge(),
            ],
          ),
          const SizedBox(height: 24),

          // Equipment Card
          _buildEquipmentCard(),
          const SizedBox(height: 16),

          // Generate Button
          _buildGenerateButton(),

          // Plan Preview
          if (_previewPlan != null) ...[
            const SizedBox(height: 16),
            _buildPlanPreview(),
          ],

          // Today's Plan
          if (_exercisePlan != null) ...[
            const SizedBox(height: 16),
            _buildTodayPlan(weekday),
          ],

          const SizedBox(height: 24),

          // Today's Log
          if (widget.todayExercise.isNotEmpty) ...[
            const Text(
              '今日动态',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: C.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            for (int i = 0; i < widget.todayExercise.length; i++)
              _ExerciseLogRow(
                entry: widget.todayExercise[i],
                onDelete: () => _removeExercise(i),
              ),
            const SizedBox(height: 24),
          ],

          // Exercise Grid
          const Text(
            '选择运动项目',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: C.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.4,
            ),
            itemCount: exerciseDB.length,
            itemBuilder: (ctx, i) {
              final ex = exerciseDB[i];
              return _ExerciseGridItem(ex: ex, onTap: () => _addExercise(ex));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBurnBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: C.cyan.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: C.cyan.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, size: 16, color: C.cyan),
          const SizedBox(width: 6),
          Text(
            '${widget.todayBurn} kcal',
            style: const TextStyle(
              color: C.cyan,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentCard() {
    final availablePresets = presetEquipment
        .where((p) => !_equipment.contains(p['name']))
        .toList();

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🏋️ ', style: TextStyle(fontSize: 16)),
              Text(
                '我的器械',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: C.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Added equipment tags
          if (_equipment.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _equipment.map((name) {
                final preset = presetEquipment.firstWhere(
                  (p) => p['name'] == name,
                  orElse: () => {'name': name, 'icon': '🔧'},
                );
                return _EquipmentTag(
                  name: name,
                  icon: preset['icon']!,
                  onRemove: () => _removeEquipment(name),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],

          // Preset quick add
          if (availablePresets.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availablePresets.map((p) {
                return _PresetTag(
                  name: p['name']!,
                  icon: p['icon']!,
                  onTap: () => _addEquipment(p['name']!),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],

          // Custom input
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: C.bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: C.border),
                  ),
                  child: TextField(
                    controller: _equipCtl,
                    style: const TextStyle(fontSize: 14, color: C.textPrimary),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 14),
                      hintText: '其他器械...',
                      hintStyle: TextStyle(color: C.textDim, fontSize: 14),
                    ),
                    onSubmitted: _addEquipment,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _addEquipment(_equipCtl.text),
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: C.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '添加',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    return GestureDetector(
      onTap: _loading ? null : _generatePlan,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: C.primaryGradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: C.cyan.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_loading) ...[
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                '生成中...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ] else ...[
              const Text('🤖 ', style: TextStyle(fontSize: 16)),
              const Text(
                '根据器械生成运动计划',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlanPreview() {
    return AppCard(
      borderColor: C.green,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📋 计划预览',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: C.green,
            ),
          ),
          const SizedBox(height: 16),
          for (final day in _previewPlan!.days) _buildPreviewDayRow(day),
          const SizedBox(height: 16),
          GradientButton(text: '✅ 保存运动计划', onTap: _savePlan),
        ],
      ),
    );
  }

  Widget _buildPreviewDayRow(ExerciseDayPlan day) {
    final isRest = day.type == '休息日';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isRest ? C.bg : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: C.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              day.day,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: C.textPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isRest
                  ? C.textDim.withValues(alpha: 0.1)
                  : C.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              day.type,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isRest ? C.textDim : C.green,
              ),
            ),
          ),
          if (day.focus != null) ...[
            const SizedBox(width: 8),
            Text(
              day.focus!,
              style: const TextStyle(
                fontSize: 13,
                color: C.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const Spacer(),
          Text(
            '${day.totalCal}kcal',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isRest ? C.textDim : C.cyan,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayPlan(String weekday) {
    final todayPlan = _exercisePlan!.days
        .where((d) => d.day == weekday)
        .firstOrNull;
    if (todayPlan == null) return const SizedBox();

    final isRest = todayPlan.type == '休息日';

    return AppCard(
      borderColor: C.cyan.withValues(alpha: 0.3),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isRest ? Icons.hotel_rounded : Icons.fitness_center_rounded,
                size: 18,
                color: C.cyan,
              ),
              const SizedBox(width: 8),
              Text(
                '今日运动安排 ($weekday)',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: C.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isRest) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  const Text('🛌', style: TextStyle(fontSize: 32)),
                  const SizedBox(height: 8),
                  Text(
                    '今天休息，可做轻度拉伸',
                    style: TextStyle(
                      fontSize: 14,
                      color: C.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (todayPlan.note != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      todayPlan.note!,
                      style: TextStyle(fontSize: 13, color: C.textDim),
                    ),
                  ],
                ],
              ),
            ),
          ] else ...[
            for (final ex in todayPlan.exercises) _buildExerciseItem(ex),
          ],
        ],
      ),
    );
  }

  Widget _buildExerciseItem(ExercisePlanEntry entry) {
    final done = _completedToday.contains(entry.name);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: done ? C.green.withValues(alpha: 0.05) : C.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: done ? C.green.withValues(alpha: 0.3) : C.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: done ? C.green : C.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${entry.equipment} · ${entry.sets}组 × ${entry.reps} · 休息${entry.rest}',
                      style: TextStyle(
                        fontSize: 12,
                        color: C.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '-${entry.cal}kcal',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: C.cyan,
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => _completeExercise(entry),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: done
                            ? C.green.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: done ? C.green : C.textDim),
                      ),
                      child: Text(
                        done ? '✅ 已完成' : '完成',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: done ? C.green : C.textDim,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (entry.tip != null && entry.tip!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '💡 ${entry.tip}',
              style: TextStyle(
                fontSize: 12,
                color: C.textDim,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============ Equipment Tags ============

class _EquipmentTag extends StatelessWidget {
  final String name;
  final String icon;
  final VoidCallback onRemove;
  const _EquipmentTag({
    required this.name,
    required this.icon,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF222222),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            name,
            style: const TextStyle(
              color: C.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded, size: 14, color: C.textDim),
          ),
        ],
      ),
    );
  }
}

class _PresetTag extends StatelessWidget {
  final String name;
  final String icon;
  final VoidCallback onTap;
  const _PresetTag({
    required this.name,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF333333),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              '+ $name',
              style: const TextStyle(
                color: C.textDim,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============ Existing Widgets ============

class _ExerciseGridItem extends StatelessWidget {
  final ExerciseItem ex;
  final VoidCallback onTap;
  const _ExerciseGridItem({required this.ex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: C.border),
          boxShadow: [
            BoxShadow(
              color: C.green.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(ex.icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              ex.name,
              style: const TextStyle(
                color: C.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '-${ex.cal}kcal',
              style: const TextStyle(
                color: C.cyan,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseLogRow extends StatelessWidget {
  final ExerciseEntry entry;
  final VoidCallback onDelete;
  const _ExerciseLogRow({required this.entry, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.border),
        boxShadow: [
          BoxShadow(
            color: C.green.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(entry.icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.name,
                style: const TextStyle(
                  color: C.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                entry.time,
                style: const TextStyle(color: C.textMuted, fontSize: 11),
              ),
            ],
          ),
          const Spacer(),
          Text(
            '-${entry.cal} kcal',
            style: const TextStyle(
              color: C.cyan,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: onDelete,
            child: Icon(
              Icons.close_rounded,
              size: 18,
              color: C.rose.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
