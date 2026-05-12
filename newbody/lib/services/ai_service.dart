import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class AIService {
  static String buildSystemPrompt(double latestWeightJin) {
    final targetJin = (AppConfig.targetWeight * 2).toStringAsFixed(0);
    final minCal = (AppConfig.dailyCalorieTarget * 0.8).toInt();
    final maxCal = AppConfig.dailyCalorieTarget;
    return '''你是NewBody减肥APP的AI助手。用户信息：${AppConfig.height.toStringAsFixed(0)}cm，当前${latestWeightJin.toStringAsFixed(0)}斤，目标$targetJin斤，${AppConfig.occupation}，每天热量目标$maxCal kcal。

你有两个职责：
1. 日常饮食/运动问答：简洁实用，不说废话，语气轻松可微微幽默，回答控制在150字以内。
2. 生成周计划：当用户说"生成计划"、"制定计划"、"给我安排一周"等类似意思时，你必须只输出JSON，不要有任何其他文字、不要markdown代码块、不要解释。

JSON格式如下：
{"days":[{"day":"周一","meals":{"breakfast":[{"food":"食物名","amount":"量","cal":数字}],"lunch":[...],"dinner":[...],"snack":[...]},"exercise":[{"name":"运动名","duration":"时长","cal":数字}],"total_intake":数字,"total_burn":数字,"note":"可选备注"},{"day":"周二",...},{"day":"周三",...},{"day":"周四",...},{"day":"周五",...},{"day":"周六",...},{"day":"周日",...}]}

要求：每天总摄入$minCal-$maxCal kcal，中国家常菜为主，运动低门槛（散步、站立），周六可稍放松。必须包含周一到周日共7天。''';
  }

  static Future<String> sendMessage({
    required List<Map<String, String>> messages,
    required double latestWeightJin,
  }) async {
    if (AppConfig.anthropicApiKey.isEmpty) {
      return '请先在 config.dart 中设置 API Key';
    }

    try {
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
          'max_tokens': 1000,
          'system': buildSystemPrompt(latestWeightJin),
          'messages': messages,
        }),
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final content = data['content'] as List;
        return content.map((c) => c['text'] ?? '').join('');
      } else {
        return '请求失败 (${resp.statusCode})，请重试';
      }
    } catch (e) {
      return '网络错误，请检查网络后重试';
    }
  }

  static Future<String> generateExercisePlan({
    required List<String> equipment,
    required double weightJin,
  }) async {
    if (AppConfig.anthropicApiKey.isEmpty) {
      return '请先在 config.dart 中设置 API Key';
    }

    final prompt = '''根据以下条件，生成一周运动计划：

用户信息：${AppConfig.height.toStringAsFixed(0)}cm，${weightJin.toStringAsFixed(0)}斤，${AppConfig.occupation}，运动基础差，目标减脂。
可用器械：${equipment.join('、')}（另外始终可做徒手动作）

要求：
1. 只输出JSON，不要任何其他文字、不要markdown代码块
2. 每周安排4-5个训练日 + 2-3个休息日（休息日可安排轻度拉伸）
3. 每天2-4个动作，难度循序渐进
4. 充分利用用户已有的器械，同时穿插徒手动作
5. 标注每个动作用到的器械（"徒手"或具体器械名）
6. 适合运动基础差的人，不要高难度动作

JSON格式：
{"days":[{"day":"周一","type":"训练日","focus":"上肢","exercises":[{"name":"动作名","equipment":"哑铃/徒手","sets":3,"reps":"12次","rest":"60秒","cal":数字,"tip":"可选的动作要点提示"}],"total_cal":数字,"note":"可选备注"},{"day":"周二","type":"休息日","exercises":[],"total_cal":0},...]}

必须包含周一到周日共7天。''';

    try {
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
          'max_tokens': 2000,
          'system': '你是一个专业的运动教练AI，只输出JSON。',
          'messages': [{'role': 'user', 'content': prompt}],
        }),
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final content = data['content'] as List;
        return content.map((c) => c['text'] ?? '').join('');
      } else {
        return '请求失败 (${resp.statusCode})，请重试';
      }
    } catch (e) {
      return '网络错误，请检查网络后重试';
    }
  }
}
