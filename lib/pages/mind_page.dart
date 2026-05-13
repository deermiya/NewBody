import 'package:flutter/material.dart';
import '../models/data_models.dart';
import '../widgets/common.dart';
import '../pages/ai_page.dart';
import '../config.dart';

class MindPage extends StatefulWidget {
  final AppData data;
  final int Function() getTodayMindCount;

  const MindPage({
    super.key,
    required this.data,
    required this.getTodayMindCount,
  });

  @override
  State<MindPage> createState() => _MindPageState();
}

class _MindPageState extends State<MindPage> {
  static const _emotions = [
    _Emotion('无聊', Icons.sentiment_dissatisfied_rounded, Color(0xFFFFB347)),
    _Emotion('焦虑', Icons.psychology_rounded, Color(0xFFFF6B6B)),
    _Emotion('压力大', Icons.compress_rounded, Color(0xFFE07A5F)),
    _Emotion('开心', Icons.sentiment_very_satisfied_rounded, Color(0xFF52B788)),
    _Emotion('疲惫', Icons.battery_1_bar_rounded, Color(0xFF9B5DE5)),
    _Emotion('习惯性', Icons.replay_rounded, Color(0xFF95A5A6)),
  ];

  // ============ 数据分析 ============
  List<MindEntry> get _recent14d {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 14));
    return widget.data.mindLog.where((e) {
      final d = DateTime.tryParse(e.date);
      return d != null && d.isAfter(cutoff);
    }).toList();
  }

  // 高频馋嘴时段
  List<MapEntry<int, int>> get _cravingHours {
    final cravongs = _recent14d.where((e) => !e.isReallyHungry);
    final hourMap = <int, int>{};
    for (final e in cravongs) {
      final parts = e.time.split(':');
      if (parts.isNotEmpty) {
        final h = int.tryParse(parts[0]) ?? 0;
        hourMap[h] = (hourMap[h] ?? 0) + 1;
      }
    }
    final sorted = hourMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(3).toList();
  }

  // 情绪触发TOP3
  List<MapEntry<String, double>> get _emotionTop3 {
    final map = <String, int>{};
    for (final e in _recent14d) {
      map[e.emotion] = (map[e.emotion] ?? 0) + 1;
    }
    final total = _recent14d.length;
    if (total == 0) return [];
    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(3).map((e) => MapEntry(e.key, e.value / total)).toList();
  }

  // 真饿vs嘴馋
  double get _realHungerRatio {
    if (_recent14d.isEmpty) return 0.5;
    return _recent14d.where((e) => e.isReallyHungry).length / _recent14d.length;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: C.bg,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildAIEntrySection(),
          const SizedBox(height: 24),
          _buildInsightsSection(),
        ],
      ),
    );
  }

  // ============ 头部 ============
  Widget _buildHeader() {
    final count = widget.getTodayMindCount();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          '觉察',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: C.textPrimary,
          ),
        ),
        if (count > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: C.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: C.purple.withOpacity(0.2)),
            ),
            child: Text(
              '今日 $count 次',
              style: const TextStyle(
                color: C.purple,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }

  // ============ 规律洞察区 ============
  Widget _buildInsightsSection() {
    if (_recent14d.length < 7) {
      return AppCard(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(
              Icons.auto_graph_rounded,
              color: C.textDim.withOpacity(0.5),
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              '记录 ${7 - _recent14d.length} 条以上后解锁洞察',
              style: const TextStyle(color: C.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              '当前已有 ${_recent14d.length} 条记录',
              style: const TextStyle(color: C.textDim, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '你的规律',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: C.textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        // 高频馋嘴时段
        if (_cravingHours.isNotEmpty) ...[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      color: C.amber,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '高频馋嘴时段',
                      style: TextStyle(
                        color: C.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: _cravingHours
                      .map(
                        (e) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: C.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: C.amber.withOpacity(0.25),
                            ),
                          ),
                          child: Text(
                            '${e.key}:00  ·  ${e.value}次',
                            style: const TextStyle(
                              color: C.amber,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],

        // 情绪触发TOP3
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.bar_chart_rounded,
                    color: C.purple,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '情绪触发 TOP3',
                    style: TextStyle(
                      color: C.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ..._emotionTop3.map((e) => _emotionBar(e.key, e.value)),
            ],
          ),
        ),

        // 真饿vs嘴馋
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.pie_chart_rounded, color: C.cyan, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    '真饿 vs 嘴馋',
                    style: TextStyle(
                      color: C.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _hungerRatioBar(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _emotionBar(String emotion, double ratio) {
    final color = _emotions
        .firstWhere((e) => e.label == emotion, orElse: () => _emotions.last)
        .color;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                emotion,
                style: const TextStyle(
                  color: C.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(ratio * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: C.border,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _hungerRatioBar() {
    final realPct = (_realHungerRatio * 100).toStringAsFixed(0);
    final fakePct = ((1 - _realHungerRatio) * 100).toStringAsFixed(0);
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 24,
            child: Row(
              children: [
                Expanded(
                  flex: (_realHungerRatio * 100).round().clamp(1, 99),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [C.cyan, C.green]),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '真饿 $realPct%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: ((1 - _realHungerRatio) * 100).round().clamp(1, 99),
                  child: Container(
                    color: C.amber.withOpacity(0.6),
                    alignment: Alignment.center,
                    child: Text(
                      '嘴馋 $fakePct%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _realHungerRatio < 0.3
              ? '大部分时候是嘴馋，不是真饿。这是好消息——说明你的身体其实不需要那些额外的热量。'
              : _realHungerRatio < 0.7
              ? '真饿和嘴馋大约各半。注意区分身体信号和情绪信号。'
              : '你经常在真饿的时候才想吃，饥饿管理做得不错。',
          style: const TextStyle(color: C.textMuted, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildAIEntrySection() {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AIPage(
              plan: null,
              updatePlan: (_) {},
              latestWeight: AppConfig.startWeight,
              todayCal: 0,
              todayBurn: 0,
            ),
          ),
        );
      },
      child: AppCard(
        borderColor: C.green.withOpacity(0.2),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: C.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI 健康教练',
                    style: TextStyle(
                      color: C.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '和 AI 聊聊你的饮食和运动计划',
                    style: TextStyle(color: C.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: C.textMuted,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class _Emotion {
  final String label;
  final IconData icon;
  final Color color;
  const _Emotion(this.label, this.icon, this.color);
}
