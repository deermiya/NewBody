import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import '../widgets/common.dart';

class GreetingService {
  static const _greetingKey = 'newbody-daily-greeting';
  static const _greetingDateKey = 'newbody-daily-greeting-date';

  static Future<String?> loadCachedGreeting() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString(_greetingDateKey);
    if (savedDate == todayStr()) {
      return prefs.getString(_greetingKey);
    }
    return null;
  }

  static Future<void> _saveGreeting(String message) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_greetingKey, message);
    await prefs.setString(_greetingDateKey, todayStr());
  }

  static Future<String> getDailyGreeting({
    required double latestWeightJin,
    required double totalLostJin,
    required int daysSinceStart,
    required int daysLeft,
    required int todayCal,
    required List<String> recentMindEmotions,
  }) async {
    final cached = await loadCachedGreeting();
    if (cached != null) return cached;

    if (AppConfig.anthropicApiKey.isEmpty) {
      return _fallbackGreeting();
    }

    try {
      final message = await _callAPI(
        latestWeightJin: latestWeightJin,
        totalLostJin: totalLostJin,
        daysSinceStart: daysSinceStart,
        daysLeft: daysLeft,
        todayCal: todayCal,
        recentMindEmotions: recentMindEmotions,
      );
      if (message.isNotEmpty &&
          !message.contains('请求失败') &&
          !message.contains('网络错误')) {
        await _saveGreeting(message);
        return message;
      }
      return _fallbackGreeting();
    } catch (_) {
      return _fallbackGreeting();
    }
  }

  static Future<String> _callAPI({
    required double latestWeightJin,
    required double totalLostJin,
    required int daysSinceStart,
    required int daysLeft,
    required int todayCal,
    required List<String> recentMindEmotions,
  }) async {
    final targetJin = (AppConfig.targetWeight * 2).toStringAsFixed(0);
    final emotionStr =
        recentMindEmotions.isEmpty ? '暂无' : recentMindEmotions.join('、');

    final systemPrompt =
        '''你是NewBody减肥APP的每日问候AI。你的任务是给用户一段简短的每日激励/洞察/哲思/心理学提示。

规则：
- 控制在80-120字以内
- 语气温暖但不说教，像一个聪明的朋友
- 可以是以下类型之一（随机选择）：实用小贴士、哲理感悟、心理学洞察、温暖鼓励、数据分析点评
- 结合用户当前状态个性化，但不要每句话都提数据
- 不要用"你好"开头，直接进入主题
- 不要使用emoji
- 输出纯文本，不要markdown格式''';

    final userPrompt =
        '''用户数据：身高${AppConfig.height.toStringAsFixed(0)}cm，当前${latestWeightJin.toStringAsFixed(0)}斤，目标$targetJin斤，已减${totalLostJin.toStringAsFixed(1)}斤，距目标还剩${daysLeft}天，开始减肥第${daysSinceStart}天。今日已摄入${todayCal}kcal（目标${AppConfig.dailyCalorieTarget}kcal）。最近情绪记录：$emotionStr。请生成今天的每日问候。''';

    final baseUrl = AppConfig.anthropicBaseUrl.isEmpty
        ? 'https://api.anthropic.com'
        : AppConfig.anthropicBaseUrl;
    final url = Uri.parse('$baseUrl/v1/messages');

    final resp = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': AppConfig.anthropicApiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': AppConfig.anthropicModel.isEmpty
            ? 'claude-3-5-sonnet-20240620'
            : AppConfig.anthropicModel,
        'max_tokens': 300,
        'system': systemPrompt,
        'messages': [
          {'role': 'user', 'content': userPrompt},
        ],
      }),
    );

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      final content = data['content'] as List;
      return content.map((c) => c['text'] ?? '').join('');
    } else {
      return '请求失败 (${resp.statusCode})，请重试';
    }
  }

  static const _fallbackGreetings = [
    '每一天的坚持，都是对未来自己的投资。今天的选择，会成为明天的底气。',
    '减肥不是惩罚身体，而是学会和身体做朋友。倾听它的信号，尊重它的节奏。',
    '你不需要完美，只需要比昨天好一点点。复利效应会在不经意间给你惊喜。',
    '饥饿感是暂时的，但养成好习惯的成就感是长久的。你正在做的事，值得骄傲。',
    '身体的变化是缓慢的，但每一次克制都在重塑你的神经回路。耐心是最好的减脂药。',
    '不要和别人比速度，每个人的起点和路径都不同。你的对手只有昨天的自己。',
    '情绪来的时候，先停三秒。这三秒里，你拿回了选择权。',
    '减掉的每一斤，都是你和自己达成的一次和解。不是对抗，是理解。',
    '今天的数据只是一个快照，不代表你的全部。趋势比单日波动重要得多。',
    '意志力是有限的资源，所以要把好习惯变成自动化。减少决策，就是保存能量。',
    '你已经走了很远了，只是走的时候没注意。回头看一眼，你会惊讶于自己的进步。',
    '真正的自律不是苦行，是找到一种你能长期维持的舒适节奏。',
    '每一次你选择健康食物，都是在给未来的自己写一封情书。',
    '压力大的时候，身体会渴望高热量食物。这不是意志力差，是生理反应。理解它，就能应对它。',
    '你今天运动了吗？哪怕只是站起来走几步，也比坐着不动强一万倍。',
    '减肥的终极目标不是变瘦，是变强。身体的强，意志的强，心态的强。',
    '记录本身就是力量。当你写下每一餐，你就从无意识进食变成了有意识选择。',
    '别小看"今天坚持住了"这件事。每一天的坚持都在告诉你的大脑：我可以。',
    '睡眠是最好的减脂助手。睡够了，食欲自然稳定，意志力也会更充沛。',
    '你不是在"忍耐"不吃某些东西，你是在"选择"更好的自己。主动权在你手里。',
  ];

  static String _fallbackGreeting() {
    final dayOfYear = DateTime.now()
        .difference(DateTime(DateTime.now().year, 1, 1))
        .inDays;
    return _fallbackGreetings[dayOfYear % _fallbackGreetings.length];
  }
}
