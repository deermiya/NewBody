import 'dart:math';
import 'package:flutter/material.dart';
import '../config.dart';
import '../models/data_models.dart';
import '../widgets/common.dart';

class HomePage extends StatelessWidget {
  final AppData data;
  final WeekPlan? plan;
  final int todayCal;
  final int todayBurn;
  final double latestWeight;

  const HomePage({super.key, required this.data, this.plan, required this.todayCal, required this.todayBurn, required this.latestWeight});

  @override
  Widget build(BuildContext context) {
    final remaining = AppConfig.dailyCalorieTarget - todayCal + todayBurn;
    final totalLost = AppConfig.startWeight - latestWeight;
    final totalNeed = AppConfig.startWeight - AppConfig.targetWeight;
    final progress = (totalLost / totalNeed).clamp(0.0, 1.0);
    final daysLeft = DateTime.parse(AppConfig.targetDate).difference(DateTime.now()).inDays.clamp(0, 9999);
    final wd = weekdayCN();
    final todayPlan = plan?.days.where((d) => d.day == wd).firstOrNull;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [C.bg, Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('NewBody', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: C.textPrimary, letterSpacing: -0.5)),
                  Text('目标：${(AppConfig.targetWeight * 2).toStringAsFixed(0)} 斤 · 剩余 $daysLeft 天', style: const TextStyle(color: C.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.glassBorder)),
                child: const Icon(Icons.notifications_none_rounded, color: C.textPrimary, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Central Progress Ring
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer Glow
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: C.green.withOpacity(0.03), blurRadius: 40, spreadRadius: 5),
                    ],
                  ),
                ),
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CustomPaint(
                    painter: _ProgressRingPainter(progress),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${(latestWeight * 2).toStringAsFixed(1)}', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: C.textPrimary, letterSpacing: -2)),
                    const Text('当前斤数', style: TextStyle(fontSize: 12, color: C.textSecondary, fontWeight: FontWeight.w600, letterSpacing: 1)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Quick Stats Grid
          Row(
            children: [
              _StatCard('累计已减', '${(totalLost * 2).toStringAsFixed(1)}', '斤', C.green, Icons.trending_down_rounded),
              const SizedBox(width: 12),
              _StatCard('今日摄入', '$todayCal', 'kcal', C.purple, Icons.restaurant_rounded),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatCard('运动消耗', '$todayBurn', 'kcal', C.cyan, Icons.bolt_rounded),
              const SizedBox(width: 12),
              _StatStatCard('剩余配额', '$remaining', 'kcal', remaining >= 0 ? C.accent : C.rose, Icons.pie_chart_outline_rounded),
            ],
          ),
          const SizedBox(height: 24),

          // Calories Progress
          AppCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('今日预算消耗', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: C.textPrimary)),
                    Text('${(todayCal / AppConfig.dailyCalorieTarget * 100).toStringAsFixed(0)}%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: todayCal > AppConfig.dailyCalorieTarget ? C.rose : C.green)),
                  ],
                ),
                const SizedBox(height: 16),
                Stack(
                  children: [
                    Container(height: 12, decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(6))),
                    FractionallySizedBox(
                      widthFactor: (todayCal / AppConfig.dailyCalorieTarget).clamp(0.0, 1.0),
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          gradient: C.primaryGradient,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('目标：${AppConfig.dailyCalorieTarget} kcal · 还可摄入 $remaining kcal', style: const TextStyle(fontSize: 12, color: C.textMuted, fontWeight: FontWeight.w500)),
              ],
            ),
          ),

          // Today's Plan
          if (todayPlan != null) _buildPlanCard(todayPlan, wd) else _buildNoPlan(),
          const SizedBox(height: 16),

          // 今日内心对话
          _buildSelfDialogueCard(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPlanCard(DayPlan plan, String wd) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 18, color: C.green),
              const SizedBox(width: 10),
              Text('今日 AI 建议 ($wd)', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: C.textPrimary)),
            ],
          ),
          const SizedBox(height: 20),
          _PlanItem('早餐', plan.meals['breakfast']),
          _PlanItem('午餐', plan.meals['lunch']),
          _PlanItem('晚餐', plan.meals['dinner']),
          if (plan.exercise.isNotEmpty) ...[
            const Divider(color: C.border, height: 32),
            const Text('推荐运动', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: C.textSecondary)),
            const SizedBox(height: 12),
            for (final ex in plan.exercise)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: C.cyan, shape: BoxShape.circle)),
                    const SizedBox(width: 12),
                    Expanded(child: Text('${ex.name} (${ex.duration})', style: const TextStyle(fontSize: 14, color: C.textPrimary))),
                    Text('-${ex.cal}kcal', style: const TextStyle(fontSize: 13, color: C.green, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoPlan() {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        children: [
          Icon(Icons.auto_awesome_rounded, size: 32, color: C.green.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('定制周计划', style: TextStyle(color: C.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('还没有生成的 AI 计划，去 AI 助手页面生成吧', textAlign: TextAlign.center, style: TextStyle(color: C.textMuted, fontSize: 13)),
        ],
      ),
    );
  }

  static const _selfDialogues = [
    '你现在想吃东西，是因为身体需要，还是因为情绪需要？',
    '这个 craving 会过去的。你不需要对抗它，只需要观察它。',
    '你上次忍住了吗？那次之后感觉怎么样？',
    '如果现在吃了，10分钟后的你会怎么想？',
    '饥饿感是波浪式的，等一等它就会退去。',
    '你不是在"忍耐"，你是在选择对自己更好的事。',
    '今天的你已经在进步了，只是你没注意到。',
    '情绪会来也会走，但你的选择会留下来。',
    '深呼吸三次。你比你以为的更有掌控力。',
    '身体知道什么是足够的，是大脑在吵着要更多。',
    '你不需要靠食物来安慰自己，你值得更好的照顾。',
    '这个 moment 不定义你。你的整体选择才定义你。',
  ];

  Widget _buildSelfDialogueCard() {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    final dialogue = _selfDialogues[dayOfYear % _selfDialogues.length];
    return AppCard(
      borderColor: C.cyan.withOpacity(0.15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.chat_bubble_outline_rounded, color: C.cyan, size: 18),
              const SizedBox(width: 8),
              const Text('今日内心对话', style: TextStyle(color: C.textPrimary, fontSize: 14, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '"$dialogue"',
            style: const TextStyle(color: C.textSecondary, fontSize: 14, fontWeight: FontWeight.w600, height: 1.6, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}

class _PlanItem extends StatelessWidget {
  final String title;
  final List<MealItem>? items;
  const _PlanItem(this.title, this.items);

  @override
  Widget build(BuildContext context) {
    if (items == null || items!.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: C.textMuted)),
          const SizedBox(height: 6),
          for (final item in items!)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${item.food} ${item.amount}', style: const TextStyle(fontSize: 14, color: C.textPrimary, fontWeight: FontWeight.w500)),
                  Text('${item.cal}kcal', style: const TextStyle(fontSize: 13, color: C.textMuted)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final IconData icon;

  const _StatCard(this.label, this.value, this.unit, this.color, this.icon);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 16),
            Text(label, style: const TextStyle(fontSize: 12, color: C.textMuted, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: C.textPrimary)),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(unit, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8), fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Fixed duplicated name from previous context if any
class _StatStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final IconData icon;
  const _StatStatCard(this.label, this.value, this.unit, this.color, this.icon);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 16),
            Text(label, style: const TextStyle(fontSize: 12, color: C.textMuted, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: C.textPrimary)),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(unit, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8), fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  _ProgressRingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;

    // Track
    final trackPaint = Paint()
      ..color = C.border
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress Arc
    final fgPaint = Paint()
      ..shader = SweepGradient(
        colors: [C.green, C.cyan, C.green],
        stops: const [0.0, 0.5, 1.0],
        transform: const GradientRotation(-pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -pi / 2, 2 * pi * progress, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter old) => old.progress != progress;
}
