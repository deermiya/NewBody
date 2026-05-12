import 'package:flutter/material.dart';
import '../models/data_models.dart';
import '../widgets/common.dart';

class ExercisePage extends StatelessWidget {
  final AppData data;
  final void Function(AppData) updateData;
  final List<ExerciseEntry> todayExercise;
  final int todayBurn;

  const ExercisePage({super.key, required this.data, required this.updateData, required this.todayExercise, required this.todayBurn});

  void _addExercise(ExerciseItem ex) {
    final entry = ExerciseEntry(name: ex.name, cal: ex.cal, icon: ex.icon, date: todayStr(), time: nowTime());
    updateData(AppData(
      weightLog: data.weightLog,
      foodLog: data.foodLog,
      exerciseLog: [...data.exerciseLog, entry],
    ));
  }

  void _removeExercise(int todayIndex) {
    final allWithIndex = <int>[];
    for (int i = 0; i < data.exerciseLog.length; i++) {
      if (data.exerciseLog[i].date == todayStr()) allWithIndex.add(i);
    }
    if (todayIndex >= allWithIndex.length) return;
    final removeAt = allWithIndex[todayIndex];
    final newList = List<ExerciseEntry>.from(data.exerciseLog)..removeAt(removeAt);
    updateData(AppData(weightLog: data.weightLog, foodLog: data.foodLog, exerciseLog: newList));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: C.bg,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('运动打卡', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: C.textPrimary)),
              _buildBurnBadge(),
            ],
          ),
          const SizedBox(height: 24),

          // Log List
          if (todayExercise.isNotEmpty) ...[
            const Text('今日动态', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: C.textSecondary)),
            const SizedBox(height: 12),
            for (int i = 0; i < todayExercise.length; i++)
              _ExerciseLogRow(entry: todayExercise[i], onDelete: () => _removeExercise(i)),
            const SizedBox(height: 24),
          ],

          // Exercise Grid
          const Text('选择运动项目', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: C.textSecondary)),
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
        color: C.cyan.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: C.cyan.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, size: 16, color: C.cyan),
          const SizedBox(width: 6),
          Text('$todayBurn kcal', style: const TextStyle(color: C.cyan, fontSize: 13, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

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
          boxShadow: [BoxShadow(color: C.green.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(ex.icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(ex.name, style: const TextStyle(color: C.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text('-${ex.cal}kcal', style: const TextStyle(color: C.cyan, fontSize: 12, fontWeight: FontWeight.w600)),
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
        boxShadow: [BoxShadow(color: C.green.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Text(entry.icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.name, style: const TextStyle(color: C.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
              Text(entry.time, style: const TextStyle(color: C.textMuted, fontSize: 11)),
            ],
          ),
          const Spacer(),
          Text('-${entry.cal} kcal', style: const TextStyle(color: C.cyan, fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: onDelete,
            child: Icon(Icons.close_rounded, size: 18, color: C.rose.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }
}
