import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/data_models.dart';
import '../services/ai_service.dart';
import '../widgets/common.dart';

class AIPage extends StatefulWidget {
  final WeekPlan? plan;
  final Future<void> Function(WeekPlan) updatePlan;
  final double latestWeight;
  final int todayCal;
  final int todayBurn;

  const AIPage({super.key, this.plan, required this.updatePlan, required this.latestWeight, required this.todayCal, required this.todayBurn});

  @override
  State<AIPage> createState() => _AIPageState();
}

class _AIPageState extends State<AIPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  static const _messagesKey = 'ai-chat-messages';

  // 内存缓存，首次为 null 表示尚未从磁盘加载
  static List<Map<String, String>>? _cachedMessages;
  static WeekPlan? _pendingPlan;

  bool _loading = false;
  bool _historyLoaded = false;

  static const _initMsg = {'role': 'assistant', 'content': '你好！我是你的 AI 健康教练。我可以帮你制定饮食计划，或解答减肥中的任何困惑。'};

  List<Map<String, String>> get _messages => _cachedMessages!;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    if (_cachedMessages != null) {
      // 内存已有，直接定位底部
      setState(() => _historyLoaded = true);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_messagesKey);
    if (raw != null) {
      try {
        final list = (jsonDecode(raw) as List)
            .map((e) => Map<String, String>.from(e as Map))
            .toList();
        _cachedMessages = list.isNotEmpty ? list : [_initMsg];
      } catch (_) {
        _cachedMessages = [_initMsg];
      }
    } else {
      _cachedMessages = [_initMsg];
    }
    if (!mounted) return;
    setState(() => _historyLoaded = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_messagesKey, jsonEncode(_cachedMessages));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 400), curve: Curves.easeOutQuart);
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || !_historyLoaded) return;
    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _loading = true;
      _pendingPlan = null;
    });
    _controller.clear();
    _scrollToBottom();
    await _saveMessages();

    final reply = await AIService.sendMessage(
      messages: _messages,
      latestWeightJin: widget.latestWeight * 2,
    );

    WeekPlan? parsed;
    try {
      final cleaned = reply.replaceAll(RegExp(r'```json\n?'), '').replaceAll(RegExp(r'```\n?'), '').trim();
      final obj = jsonDecode(cleaned);
      if (obj['days'] != null && (obj['days'] as List).length >= 7) {
        parsed = WeekPlan.fromJson(obj);
      }
    } catch (_) {}

    setState(() {
      _loading = false;
      if (parsed != null) {
        _pendingPlan = parsed;
        _messages.add({'role': 'assistant', 'content': '已为你量身定制了一周计划！点击下方按钮即可保存。'});
      } else {
        _messages.add({'role': 'assistant', 'content': reply});
      }
    });
    _scrollToBottom();
    await _saveMessages();
  }

  Future<void> _savePlan() async {
    if (_pendingPlan == null) return;
    await widget.updatePlan(_pendingPlan!);
    setState(() {
      _pendingPlan = null;
      _messages.add({'role': 'assistant', 'content': '🎉 计划已同步至首页，开启健康的一周吧！'});
    });
    _scrollToBottom();
    _saveMessages();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_historyLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: C.green)),
      );
    }
    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                itemCount: _messages.length + (_loading ? 1 : 0) + (_pendingPlan != null ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < _messages.length) {
                    return _MessageBubble(message: _messages[index]);
                  } else if (_loading && index == _messages.length) {
                    return _buildLoadingIndicator();
                  } else {
                    return _buildPlanPreview();
                  }
                },
              ),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: C.border, width: 0.5)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: C.textSecondary),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: C.bg, shape: BoxShape.circle),
            child: const Icon(Icons.auto_awesome_rounded, size: 20, color: C.green),
          ),
          const SizedBox(width: 14),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AI 健康教练', style: TextStyle(color: C.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
              Text('基于你的体征数据提供建议', style: TextStyle(color: C.textMuted, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: C.border)),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: C.green.withOpacity(0.3)),
        ),
      ),
    );
  }

  Widget _buildPlanPreview() {
    return AppCard(
      borderColor: C.green.withOpacity(0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.checklist_rtl_rounded, color: C.green, size: 20),
              SizedBox(width: 10),
              Text('计划预览 (7天)', style: TextStyle(color: C.textPrimary, fontSize: 15, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 16),
          for (int i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Text(_pendingPlan!.days[i].day, style: const TextStyle(color: C.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _pendingPlan!.days[i].meals['lunch']?.first.food ?? '健康饮食',
                      style: const TextStyle(color: C.textMuted, fontSize: 13),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          const Divider(color: C.border, height: 24),
          GradientButton(text: '应用并保存此计划', icon: Icons.save_alt_rounded, onTap: _savePlan),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: C.border, width: 0.5)),
      ),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _QuickChip(label: '制定计划', icon: Icons.calendar_month, onTap: () => _sendMessage('帮我生成本周减肥饮食和运动计划')),
                _QuickChip(label: '能吃火锅吗？', icon: Icons.restaurant, onTap: () => _sendMessage('减肥能吃火锅吗？')),
                _QuickChip(label: '不想运动', icon: Icons.sentiment_dissatisfied, onTap: () => _sendMessage('我非常懒不想运动，怎么减肥？')),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: C.bg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: C.border),
                  ),
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: C.textPrimary, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: '问问教练...',
                      hintStyle: TextStyle(color: C.textDim),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (v) => _sendMessage(v),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _sendMessage(_controller.text),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(gradient: C.primaryGradient, borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Map<String, String> message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message['role'] == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          gradient: isUser ? C.primaryGradient : null,
          color: isUser ? null : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
          boxShadow: [
            BoxShadow(color: C.green.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
          ],
          border: isUser ? null : Border.all(color: C.border),
        ),
        child: Text(
          message['content']!,
          style: TextStyle(
            color: isUser ? Colors.white : C.textPrimary,
            fontSize: 15,
            height: 1.5,
            fontWeight: isUser ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _QuickChip({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: C.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: C.green),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: C.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
