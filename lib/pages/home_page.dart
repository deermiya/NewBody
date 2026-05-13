import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../config.dart';
import '../models/data_models.dart';
import '../widgets/common.dart';
import 'import_plan_page.dart';
import 'profile_page.dart';
import 'sync_page.dart';

class HomePage extends StatelessWidget {
  final AppData data;
  final void Function(AppData) updateData;
  final WeekPlan? plan;
  final int todayCal;
  final int todayBurn;
  final double latestWeight;
  final VoidCallback? onConfigChanged;
  final Future<void> Function()? onPlansImported;

  const HomePage({
    super.key,
    required this.data,
    required this.updateData,
    this.plan,
    required this.todayCal,
    required this.todayBurn,
    required this.latestWeight,
    this.onConfigChanged,
    this.onPlansImported,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = AppConfig.dailyCalorieTarget - todayCal + todayBurn;
    final totalLost = AppConfig.startWeight - latestWeight;
    final totalNeed = AppConfig.startWeight - AppConfig.targetWeight;
    final progress = (totalLost / totalNeed).clamp(0.0, 1.0);
    final daysLeft = DateTime.parse(
      AppConfig.targetDate,
    ).difference(DateTime.now()).inDays.clamp(0, 9999);
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
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfilePage(
                    onSaved: () {
                      if (onConfigChanged != null) onConfigChanged!();
                    },
                    onDataRestored: onPlansImported,
                  ),
                ),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'NewBody',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: C.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '目标：${(AppConfig.targetWeight * 2).toStringAsFixed(0)} 斤 · 剩余 $daysLeft 天',
                          style: const TextStyle(
                            color: C.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.edit_outlined,
                          size: 14,
                          color: C.textMuted,
                        ),
                      ],
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push<ImportPlanResult>(
                      context,
                      MaterialPageRoute(builder: (_) => const ImportPlanPage()),
                    );
                    if (result == null || !context.mounted) return;
                    await onPlansImported?.call();
                    if (!context.mounted) return;
                    final parts = [
                      if (result.importedDiet) '饮食计划',
                      if (result.importedExercise) '运动计划',
                    ];
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${parts.join('和')}已导入'),
                        backgroundColor: C.green,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: C.glassBorder),
                    ),
                    child: const Icon(
                      Icons.upload_file_rounded,
                      color: C.textPrimary,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 情绪打卡 + 延迟满足
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SyncPage(onSynced: onPlansImported),
                ),
              );
            },
            child: AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              borderColor: C.cyan.withOpacity(0.18),
              child: const Row(
                children: [
                  Icon(Icons.cloud_sync_rounded, color: C.green, size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '云同步',
                      style: TextStyle(
                        color: C.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: C.textMuted),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          _DelayTimerCard(data: data, updateData: updateData),
          const SizedBox(height: 8),

          // 今日内心对话
          _buildSelfDialogueCard(),
          const SizedBox(height: 24),

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
                      BoxShadow(
                        color: C.green.withOpacity(0.03),
                        blurRadius: 40,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CustomPaint(painter: _ProgressRingPainter(progress)),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      (latestWeight * 2).toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: C.textPrimary,
                        letterSpacing: -2,
                      ),
                    ),
                    const Text(
                      '当前斤数',
                      style: TextStyle(
                        fontSize: 12,
                        color: C.textSecondary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Quick Stats Grid
          Row(
            children: [
              _StatCard(
                '累计已减',
                (totalLost * 2).toStringAsFixed(1),
                '斤',
                C.green,
                Icons.trending_down_rounded,
              ),
              const SizedBox(width: 12),
              _StatCard(
                '今日摄入',
                '$todayCal',
                'kcal',
                C.purple,
                Icons.restaurant_rounded,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatCard(
                '运动消耗',
                '$todayBurn',
                'kcal',
                C.cyan,
                Icons.bolt_rounded,
              ),
              const SizedBox(width: 12),
              _StatStatCard(
                '剩余配额',
                '$remaining',
                'kcal',
                remaining >= 0 ? C.accent : C.rose,
                Icons.pie_chart_outline_rounded,
              ),
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
                    const Text(
                      '今日预算消耗',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: C.textPrimary,
                      ),
                    ),
                    Text(
                      '${(todayCal / AppConfig.dailyCalorieTarget * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: todayCal > AppConfig.dailyCalorieTarget
                            ? C.rose
                            : C.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Stack(
                  children: [
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: C.bg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: (todayCal / AppConfig.dailyCalorieTarget)
                          .clamp(0.0, 1.0),
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
                Text(
                  '目标：${AppConfig.dailyCalorieTarget} kcal · 还可摄入 $remaining kcal',
                  style: const TextStyle(
                    fontSize: 12,
                    color: C.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Today's Plan
          if (todayPlan != null)
            _buildPlanCard(todayPlan, wd)
          else
            _buildNoPlan(),
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
              const Icon(
                Icons.calendar_today_rounded,
                size: 18,
                color: C.green,
              ),
              const SizedBox(width: 10),
              Text(
                '今日 AI 建议 ($wd)',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: C.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _PlanItem('早餐', plan.meals['breakfast']),
          _PlanItem('午餐', plan.meals['lunch']),
          _PlanItem('晚餐', plan.meals['dinner']),
          if (plan.exercise.isNotEmpty) ...[
            const Divider(color: C.border, height: 32),
            const Text(
              '推荐运动',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: C.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            for (final ex in plan.exercise)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: C.cyan,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${ex.name} (${ex.duration})',
                        style: const TextStyle(
                          fontSize: 14,
                          color: C.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '-${ex.cal}kcal',
                      style: const TextStyle(
                        fontSize: 13,
                        color: C.green,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
          Icon(
            Icons.auto_awesome_rounded,
            size: 32,
            color: C.green.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            '定制周计划',
            style: TextStyle(
              color: C.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '还没有生成的 AI 计划，去 AI 助手页面生成吧',
            textAlign: TextAlign.center,
            style: TextStyle(color: C.textMuted, fontSize: 13),
          ),
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
    final dayOfYear = DateTime.now()
        .difference(DateTime(DateTime.now().year, 1, 1))
        .inDays;
    final dialogue = _selfDialogues[dayOfYear % _selfDialogues.length];
    return AppCard(
      borderColor: C.cyan.withOpacity(0.15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.chat_bubble_outline_rounded,
                color: C.cyan,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                '今日内心对话',
                style: TextStyle(
                  color: C.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '"$dialogue"',
            style: const TextStyle(
              color: C.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.6,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _DelayTimerCard extends StatefulWidget {
  final AppData data;
  final void Function(AppData) updateData;
  const _DelayTimerCard({required this.data, required this.updateData});

  @override
  State<_DelayTimerCard> createState() => _DelayTimerCardState();
}

class _DelayTimerCardState extends State<_DelayTimerCard> {
  static const int _delayMinutes = 15;
  Timer? _countdownTimer;
  int _countdownSeconds = 0;

  // 打卡状态
  String? _selectedEmotion;
  bool? _isReallyHungry;
  bool _showSuccess = false;
  Timer? _successTimer;

  static const _emotions = [
    _Emotion('无聊', Icons.sentiment_dissatisfied_rounded, Color(0xFFFFB347)),
    _Emotion('焦虑', Icons.psychology_rounded, Color(0xFFFF6B6B)),
    _Emotion('压力大', Icons.compress_rounded, Color(0xFFE07A5F)),
    _Emotion('开心', Icons.sentiment_very_satisfied_rounded, Color(0xFF52B788)),
    _Emotion('疲惫', Icons.battery_1_bar_rounded, Color(0xFF9B5DE5)),
    _Emotion('习惯性', Icons.replay_rounded, Color(0xFF95A5A6)),
  ];

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _successTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (_countdownTimer != null && _countdownTimer!.isActive) return;
    setState(() => _countdownSeconds = _delayMinutes * 60);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdownSeconds <= 1) {
        timer.cancel();
        setState(() => _countdownSeconds = 0);
      } else {
        setState(() => _countdownSeconds--);
      }
    });
  }

  void _cancelTimer() {
    _countdownTimer?.cancel();
    setState(() => _countdownSeconds = 0);
  }

  // 今日最高频情绪
  String? get _todayTopEmotion {
    final map = <String, int>{};
    for (final e in widget.data.mindLog.where((e) => e.date == todayStr())) {
      map[e.emotion] = (map[e.emotion] ?? 0) + 1;
    }
    if (map.isEmpty) return null;
    return (map.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
        .first
        .key;
  }

  // 替代行为建议
  String get _alternativeSuggestion {
    switch (_todayTopEmotion) {
      case '焦虑':
        return '试试深呼吸：吸气4秒，屏住4秒，呼气6秒。重复3次。或者出门走5分钟。';
      case '无聊':
        return '喝一杯水，或者站起来活动1分钟。无聊的 craving 通常5分钟就过去。';
      case '压力大':
        return '闭眼听一首歌，或者做5分钟冥想。压力不靠吃来解决。';
      case '疲惫':
        return '闭眼休息5分钟，或者做一组拉伸。疲惫时身体需要的是休息，不是食物。';
      case '习惯性':
        return '打破惯性：换个位置坐、喝杯茶、打开窗户。习惯的力量很大，但你可以选择。';
      case '开心':
        return '开心的时候不需要用食物来"庆祝"，这份好心情本身就是奖励。';
      default:
        return '先喝一杯水，等15分钟再决定。很多 craving 只是身体在说"我渴了"。';
    }
  }

  // ============ 打卡逻辑 ============
  void _onEmotionTap(String emotion) {
    setState(() {
      _selectedEmotion = emotion;
      _isReallyHungry = null;
    });
  }

  void _onHungerSelect(bool isReallyHungry) {
    setState(() => _isReallyHungry = isReallyHungry);
  }

  void _onChoiceSelect(String choice) {
    if (_selectedEmotion == null || _isReallyHungry == null) return;
    final entry = MindEntry(
      emotion: _selectedEmotion!,
      isReallyHungry: _isReallyHungry!,
      choice: choice,
      date: todayStr(),
      time: nowTime(),
    );
    final newData = widget.data..mindLog.add(entry);
    widget.updateData(newData);

    setState(() {
      _showSuccess = true;
      _selectedEmotion = null;
      _isReallyHungry = null;
    });

    _successTimer?.cancel();
    _successTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showSuccess = false);
    });
  }

  Widget _buildHungerChoice() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: C.border, height: 1),
        const SizedBox(height: 16),
        const Text(
          '是真饿还是嘴馋？',
          style: TextStyle(
            color: C.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _choiceChip(
                '真饿了 🍽',
                _isReallyHungry == true,
                () => _onHungerSelect(true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _choiceChip(
                '嘴馋而已 😋',
                _isReallyHungry == false,
                () => _onHungerSelect(false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBehaviorChoice() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: C.border, height: 1),
        const SizedBox(height: 16),
        const Text(
          '你选择了什么？',
          style: TextStyle(
            color: C.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _choiceChip('忍住了 💪', false, () => _onChoiceSelect('忍住了')),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _choiceChip(
                '吃了一点 🤏',
                false,
                () => _onChoiceSelect('吃了一点'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _choiceChip('放纵了 😅', false, () => _onChoiceSelect('放纵了')),
            ),
          ],
        ),
      ],
    );
  }

  Widget _choiceChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? C.purple.withOpacity(0.12) : C.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? C.purple : C.border,
            width: selected ? 2 : 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? C.purple : C.textSecondary,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _countdownSeconds > 0;
    final minutes = (_countdownSeconds / 60).floor();
    final seconds = _countdownSeconds % 60;
    final progress = isActive ? _countdownSeconds / (_delayMinutes * 60) : 0.0;

    return AppCard(
      borderColor: isActive
          ? C.purple.withOpacity(0.3)
          : C.purple.withOpacity(0.15),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: C.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.timer_rounded,
                  color: C.purple,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  '延迟满足',
                  style: TextStyle(
                    color: C.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (isActive)
                GestureDetector(
                  onTap: _cancelTimer,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: C.rose.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '取消',
                      style: TextStyle(
                        color: C.rose,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (isActive) ...[
            Row(
              children: [
                SizedBox(
                  width: 78,
                  height: 78,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 78,
                        height: 78,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 7,
                          backgroundColor: C.border,
                          valueColor: const AlwaysStoppedAnimation(C.purple),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Text(
                        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          color: C.purple,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    '再等一下。很多想吃的冲动会像波浪一样自己退下去。',
                    style: TextStyle(
                      color: C.textSecondary,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            // 情绪打卡
            Row(
              children: [
                const Icon(Icons.visibility_rounded, color: C.purple, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    '此刻你的感受是？',
                    style: TextStyle(
                      color: C.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (_showSuccess)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: C.cyan.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '已记录 ✓',
                      style: TextStyle(
                        color: C.cyan,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.2,
              children: _emotions.map((e) {
                final selected = _selectedEmotion == e.label;
                return GestureDetector(
                  onTap: () => _onEmotionTap(e.label),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: selected ? e.color.withOpacity(0.15) : C.bg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? e.color : C.border,
                        width: selected ? 2 : 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          e.icon,
                          size: 18,
                          color: selected ? e.color : C.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          e.label,
                          style: TextStyle(
                            color: selected ? e.color : C.textSecondary,
                            fontSize: 13,
                            fontWeight: selected
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_selectedEmotion != null) ...[
              const SizedBox(height: 20),
              _buildHungerChoice(),
            ],
            if (_selectedEmotion != null && _isReallyHungry != null) ...[
              const SizedBox(height: 16),
              _buildBehaviorChoice(),
            ],
            const SizedBox(height: 16),
            // 替代行为建议
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: C.amber.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: C.amber.withOpacity(0.15)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_rounded, color: C.amber, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _alternativeSuggestion,
                      style: const TextStyle(
                        color: C.textSecondary,
                        fontSize: 13,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: _startTimer,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [C.purple.withOpacity(0.82), C.purple],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: C.purple.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.timer_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      '开始 15 分钟倒计时',
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: C.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          for (final item in items!)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${item.food} ${item.amount}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: C.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${item.cal}kcal',
                    style: const TextStyle(fontSize: 13, color: C.textMuted),
                  ),
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
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: C.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: C.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    unit,
                    style: TextStyle(
                      fontSize: 12,
                      color: color.withOpacity(0.8),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: C.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: C.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    unit,
                    style: TextStyle(
                      fontSize: 12,
                      color: color.withOpacity(0.8),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter old) =>
      old.progress != progress;
}

class _Emotion {
  final String label;
  final IconData icon;
  final Color color;
  const _Emotion(this.label, this.icon, this.color);
}
