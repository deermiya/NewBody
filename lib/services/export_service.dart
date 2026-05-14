import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/data_models.dart';

class ExportService {
  /// 导出全部记录，调起系统分享菜单
  static Future<void> exportAll(AppData data) async {
    final now = DateTime.now();
    final stamp =
        '${now.year}${_pad(now.month)}${_pad(now.day)}_${_pad(now.hour)}${_pad(now.minute)}';

    final dir = await getTemporaryDirectory();

    final files = <XFile>[
      await _writeFile(dir, 'newbody_weight_$stamp.csv', _weightCsv(data)),
      await _writeFile(dir, 'newbody_food_$stamp.csv', _foodCsv(data)),
      await _writeFile(dir, 'newbody_exercise_$stamp.csv', _exerciseCsv(data)),
      await _writeFile(dir, 'newbody_mind_$stamp.csv', _mindCsv(data)),
    ];

    await Share.shareXFiles(
      files,
      text: 'NewBody 健康记录导出 $stamp',
      subject: 'NewBody 记录导出',
    );
  }

  // ─── CSV 生成 ────────────────────────────────────────────────

  static String _weightCsv(AppData data) {
    final buf = StringBuffer();
    buf.writeln('日期,体重(kg),体重(斤)');
    for (final e in data.weightLog) {
      buf.writeln('${e.date},${e.weight},${(e.weight * 2).toStringAsFixed(1)}');
    }
    return buf.toString();
  }

  static String _foodCsv(AppData data) {
    final buf = StringBuffer();
    buf.writeln('日期,时间,食物,热量(kcal)');
    for (final e in data.foodLog) {
      buf.writeln('${e.date},${e.time},${_escape(e.name)},${e.cal}');
    }
    return buf.toString();
  }

  static String _exerciseCsv(AppData data) {
    final buf = StringBuffer();
    buf.writeln('日期,时间,运动,消耗(kcal)');
    for (final e in data.exerciseLog) {
      buf.writeln('${e.date},${e.time},${_escape(e.name)},${e.cal}');
    }
    return buf.toString();
  }

  static String _mindCsv(AppData data) {
    final buf = StringBuffer();
    buf.writeln('日期,时间,情绪,是否真饿,选择');
    for (final e in data.mindLog) {
      buf.writeln(
        '${e.date},${e.time},${_escape(e.emotion)},${e.isReallyHungry ? "真饿" : "嘴馋"},${_escape(e.choice)}',
      );
    }
    return buf.toString();
  }

  // ─── 工具 ────────────────────────────────────────────────────

  static Future<XFile> _writeFile(Directory dir, String name, String content) async {
    // BOM 让 Excel 正确识别 UTF-8
    final bom = '\uFEFF';
    final file = File('${dir.path}/$name');
    await file.writeAsString(bom + content, flush: true);
    return XFile(file.path, mimeType: 'text/csv');
  }

  /// CSV 字段转义：有逗号或引号时加双引号包裹
  static String _escape(String s) {
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');
}
