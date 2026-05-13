import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import 'storage_service.dart';

class SyncService {
  static bool get isConfigured => AppConfig.syncBaseUrl.trim().isNotEmpty;

  static Future<void> push(String syncKey) async {
    final snapshot = await StorageService.exportSnapshot();
    final resp = await http
        .post(
          _syncUri(syncKey),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'data': snapshot}),
        )
        .timeout(const Duration(seconds: 30));

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception(_errorMessage(resp.body, '上传失败 (${resp.statusCode})'));
    }
    await StorageService.saveSyncKey(syncKey);
  }

  static Future<void> pull(String syncKey) async {
    final resp = await http
        .get(_syncUri(syncKey))
        .timeout(const Duration(seconds: 30));

    if (resp.statusCode == 404) {
      throw Exception('云端还没有这个同步码的数据');
    }
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception(_errorMessage(resp.body, '下载失败 (${resp.statusCode})'));
    }

    final decoded = jsonDecode(resp.body);
    if (decoded is! Map<String, dynamic> ||
        decoded['data'] is! Map<String, dynamic>) {
      throw Exception('云端数据格式不正确');
    }

    await StorageService.importSnapshot(
      decoded['data'] as Map<String, dynamic>,
    );
    await StorageService.saveSyncKey(syncKey);
  }

  static Uri _syncUri(String syncKey) {
    final base = AppConfig.syncBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    return Uri.parse('$base/sync/${Uri.encodeComponent(syncKey)}');
  }

  static String _errorMessage(String body, String fallback) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['error'] is String) {
        return decoded['error'] as String;
      }
    } catch (_) {}
    return fallback;
  }
}
