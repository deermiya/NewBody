import 'dart:async';
import 'package:flutter/material.dart';
import '../models/data_models.dart';
import '../widgets/common.dart';
import '../pages/ai_page.dart';
import '../config.dart';

class MindPage extends StatefulWidget {
  final AppData data;
  final void Function(AppData) updateData;
  final int Function() getTodayMindCount;

  const MindPage({super.key, required this.data, required this.updateData, required this.getTodayMindCount});

  @override
  State<MindPage> createState() => _MindPageState();
}

class _MindPageState extends State<MindPage> {
  // 打卡状态
  String? _selectedEmotion;
  bool? _isReallyHungry;
  bool _showSuccess = false;
  Timer? _successTimer;

  // 计时器状态
  Timer? _countdownTimer;
  int _countdownSeconds = 0;
  static const int _delayMinutes = 15;

  static const _emotions = [
    _Emotion('无聊', Icons.sentiment_dissatisfied_rounded, Color(0xFFFFB347)),
    _Emotion('焦虑', Icons.psychology_rounded, Color(0xFFFF6B6B)),
    _Emotion('压力大', Icons.compress_rounded, Color(0xFFE07A5F)),
    _Emotion('开心', Icons.sentiment_very_satisfied_rounded, Color(0xFF52B788)),
    _Emotion('疲惫', Icons.battery_1_bar_rounded, Color(0xFF9B5DE5)),
    _Emotion('习惯性', Icons.replay_rounded, Color(0xFF95A5A6)),
  ];

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

  @override
  void dispose() {
    _successTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
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

  // ============ 计时器逻辑 ============
  void _startTimer() {
    if (_countdownTimer != null && _countdownTimer!.isActive) return;
    setState(() => _countdownSeconds = _delayMinutes * 60);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
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

  // ============ 数据分析 ============
  List<MindEntry> get _recent14d {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 14));
    return widget.data.mindLog.where((e) {
      final d = DateTime.tryParse(e.date);
      return d != null && d.isAfter(cutoff);
    }).toList();
  }

  List<MindEntry> get _todayEntries =>
      widget.data.mindLog.where((e) => e.date == todayStr()).toList();

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
    final sorted = hourMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
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
    final sorted = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(3).map((e) => MapEntry(e.key, e.value / total)).toList();
  }

  // 真饿vs嘴馋
  double get _realHungerRatio {
    if (_recent14d.isEmpty) return 0.5;
    return _recent14d.where((e) => e.isReallyHungry).length / _recent14d.length;
  }

  // 今日最高频情绪
  String? get _todayTopEmotion {
    final map = <String, int>{};
    for (final e in _todayEntries) {
      map[e.emotion] = (map[e.emotion] ?? 0) + 1;
    }
    if (map.isEmpty) return null;
    return (map.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first.key;
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

  // 今日自我对话
  String get _todayDialogue {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    return _selfDialogues[dayOfYear % _selfDialogues.length];
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
          const SizedBox(height: 20),
          _buildCheckInSection(),
          const SizedBox(height: 24),
          _buildInsightsSection(),
          const SizedBox(height: 24),
          _buildTimerSection(),
          const SizedBox(height: 20),
          _buildAlternativeSection(),
          const SizedBox(height: 20),
          _buildSelfDialogueSection(),
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
        const Text('觉察', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: C.textPrimary)),
        if (count > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: C.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: C.purple.withOpacity(0.2)),
            ),
            child: Text('今日 $count 次', style: const TextStyle(color: C.purple, fontSize: 12, fontWeight: FontWeight.w800)),
          ),
      ],
    );
  }

  // ============ A. 快速打卡区 ============
  Widget _buildCheckInSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.visibility_rounded, color: C.purple, size: 20),
              const SizedBox(width: 10),
              const Text('情绪打卡', style: TextStyle(color: C.textPrimary, fontSize: 15, fontWeight: FontWeight.w800)),
              const Spacer(),
              if (_showSuccess)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: C.cyan.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                  child: const Text('已记录 ✓', style: TextStyle(color: C.cyan, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          const Text('此刻你的感受是？', style: TextStyle(color: C.textMuted, fontSize: 13)),
          const SizedBox(height: 16),

          // 情绪按钮网格
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
                      Icon(e.icon, size: 18, color: selected ? e.color : C.textMuted),
                      const SizedBox(width: 6),
                      Text(e.label, style: TextStyle(
                        color: selected ? e.color : C.textSecondary,
                        fontSize: 13,
                        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      )),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          // 选中后展开
          if (_selectedEmotion != null) ...[
            const SizedBox(height: 20),
            _buildHungerChoice(),
          ],
          if (_selectedEmotion != null && _isReallyHungry != null) ...[
            const SizedBox(height: 16),
            _buildBehaviorChoice(),
          ],
        ],
      ),
    );
  }

  Widget _buildHungerChoice() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: C.border, height: 1),
        const SizedBox(height: 16),
        const Text('是真饿还是嘴馋？', style: TextStyle(color: C.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _choiceChip('真饿了 🍽', _isReallyHungry == true, () => _onHungerSelect(true))),
            const SizedBox(width: 12),
            Expanded(child: _choiceChip('嘴馋而已 😋', _isReallyHungry == false, () => _onHungerSelect(false))),
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
        const Text('你选择了什么？', style: TextStyle(color: C.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _choiceChip('忍住了 💪', false, () => _onChoiceSelect('忍住了'))),
            const SizedBox(width: 8),
            Expanded(child: _choiceChip('吃了一点 🤏', false, () => _onChoiceSelect('吃了一点'))),
            const SizedBox(width: 8),
            Expanded(child: _choiceChip('放纵了 😅', false, () => _onChoiceSelect('放纵了'))),
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
          border: Border.all(color: selected ? C.purple : C.border, width: selected ? 2 : 1.5),
        ),
        child: Center(
          child: Text(label, style: TextStyle(
            color: selected ? C.purple : C.textSecondary,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          )),
        ),
      ),
    );
  }

  // ============ B. 规律洞察区 ============
  Widget _buildInsightsSection() {
    if (_recent14d.length < 7) {
      return AppCard(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(Icons.auto_graph_rounded, color: C.textDim.withOpacity(0.5), size: 40),
            const SizedBox(height: 12),
            Text('记录 ${7 - _recent14d.length} 条以上后解锁洞察', style: const TextStyle(color: C.textMuted, fontSize: 13)),
            const SizedBox(height: 4),
            Text('当前已有 ${_recent14d.length} 条记录', style: const TextStyle(color: C.textDim, fontSize: 12)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('你的规律', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: C.textPrimary)),
        const SizedBox(height: 12),

        // 高频馋嘴时段
        if (_cravingHours.isNotEmpty) ...[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded, color: C.amber, size: 18),
                    const SizedBox(width: 8),
                    const Text('高频馋嘴时段', style: TextStyle(color: C.textPrimary, fontSize: 14, fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: _cravingHours.map((e) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: C.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: C.amber.withOpacity(0.25)),
                    ),
                    child: Text('${e.key}:00  ·  ${e.value}次', style: const TextStyle(color: C.amber, fontSize: 13, fontWeight: FontWeight.w700)),
                  )).toList(),
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
                  const Icon(Icons.bar_chart_rounded, color: C.purple, size: 18),
                  const SizedBox(width: 8),
                  const Text('情绪触发 TOP3', style: TextStyle(color: C.textPrimary, fontSize: 14, fontWeight: FontWeight.w800)),
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
                  const Text('真饿 vs 嘴馋', style: TextStyle(color: C.textPrimary, fontSize: 14, fontWeight: FontWeight.w800)),
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
    final color = _emotions.firstWhere((e) => e.label == emotion, orElse: () => _emotions.last).color;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(emotion, style: const TextStyle(color: C.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
              Text('${(ratio * 100).toStringAsFixed(0)}%', style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800)),
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
                    child: Text('真饿 $realPct%', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                  ),
                ),
                Expanded(
                  flex: ((1 - _realHungerRatio) * 100).round().clamp(1, 99),
                  child: Container(
                    color: C.amber.withOpacity(0.6),
                    alignment: Alignment.center,
                    child: Text('嘴馋 $fakePct%', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
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

  // ============ C. 干预工具区 ============
  Widget _buildTimerSection() {
    final isActive = _countdownSeconds > 0;
    final minutes = (_countdownSeconds / 60).floor();
    final seconds = _countdownSeconds % 60;
    final progress = isActive ? _countdownSeconds / (_delayMinutes * 60) : 0.0;

    return AppCard(
      borderColor: isActive ? C.purple.withOpacity(0.3) : null,
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.timer_rounded, color: C.purple, size: 20),
              const SizedBox(width: 10),
              const Text('延迟满足', style: TextStyle(color: C.textPrimary, fontSize: 15, fontWeight: FontWeight.w800)),
              const Spacer(),
              if (isActive)
                GestureDetector(
                  onTap: _cancelTimer,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: C.rose.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Text('取消', style: TextStyle(color: C.rose, fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (isActive) ...[
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      backgroundColor: C.border,
                      valueColor: const AlwaysStoppedAnimation(C.purple),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: C.purple, fontSize: 28, fontWeight: FontWeight.w900, fontFeatures: [FontFeature.tabularFigures()]),
                      ),
                      const Text('再等等', style: TextStyle(color: C.textMuted, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text('craving 是波浪式的，等一等就会退去', style: TextStyle(color: C.textMuted, fontSize: 12)),
          ] else ...[
            const Text('想吃东西？先等 15 分钟。', style: TextStyle(color: C.textSecondary, fontSize: 14)),
            const SizedBox(height: 4),
            const Text('很多 craving 会在等待中自然消退', style: TextStyle(color: C.textMuted, fontSize: 12)),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _startTimer,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [C.purple.withOpacity(0.8), C.purple]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: C.purple.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.timer_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text('开始 15 分钟倒计时', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAlternativeSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_rounded, color: C.amber, size: 20),
              const SizedBox(width: 10),
              Text(
                _todayTopEmotion != null ? '替代行为 · $_todayTopEmotion' : '替代行为',
                style: const TextStyle(color: C.textPrimary, fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: C.amber.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: C.amber.withOpacity(0.15)),
            ),
            child: Text(_alternativeSuggestion, style: const TextStyle(color: C.textSecondary, fontSize: 13, height: 1.6)),
          ),
        ],
      ),
    );
  }

  Widget _buildSelfDialogueSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.chat_bubble_outline_rounded, color: C.cyan, size: 20),
              const SizedBox(width: 10),
              const Text('今日内心对话', style: TextStyle(color: C.textPrimary, fontSize: 15, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: C.cyan.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: C.cyan.withOpacity(0.15)),
            ),
            child: Text(
              '"$_todayDialogue"',
              style: const TextStyle(color: C.textPrimary, fontSize: 14, fontWeight: FontWeight.w600, height: 1.6, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIEntrySection() {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => AIPage(
            plan: null,
            updatePlan: (_) {},
            latestWeight: AppConfig.startWeight,
            todayCal: 0,
            todayBurn: 0,
          ),
        ));
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
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI 健康教练', style: TextStyle(color: C.textPrimary, fontSize: 15, fontWeight: FontWeight.w800)),
                  SizedBox(height: 2),
                  Text('和 AI 聊聊你的饮食和运动计划', style: TextStyle(color: C.textMuted, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: C.textMuted, size: 24),
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
