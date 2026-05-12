import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class AIService {
  static String buildSystemPrompt(double latestWeightJin) {
    return '''你是NewBody减肥APP的AI助手。用户信息：170cm，当前${latestWeightJin.toStringAsFixed(0)}斤，目标140斤，久坐程序员，不爱运动，每天热量目标1500kcal。

你有两个职责：
1. 日常饮食/运动问答：简洁实用，不说废话，语气轻松可微微幽默，回答控制在150字以内。
2. 生成周计划：当用户说"生成计划"、"制定计划"、"给我安排一周"等类似意思时，你必须只输出JSON，不要有任何其他文字、不要markdown代码块、不要解释。

JSON格式如下：
{"days":[{"day":"周一","meals":{"breakfast":[{"food":"食物名","amount":"量","cal":数字}],"lunch":[...],"dinner":[...],"snack":[...]},"exercise":[{"name":"运动名","duration":"时长","cal":数字}],"total_intake":数字,"total_burn":数字,"note":"可选备注"},{"day":"周二",...},{"day":"周三",...},{"day":"周四",...},{"day":"周五",...},{"day":"周六",...},{"day":"周日",...}]}

要求：每天总摄入1200-1500kcal，中国家常菜为主，运动低门槛（散步、站立），周六可稍放松。必须包含周一到周日共7天。''';
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
}
