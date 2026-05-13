import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/data_models.dart';
import '../services/storage_service.dart';

class WeeklyPlanData {
  static const _importedKey = 'newbody-weekly-plan-imported-v1';

  static Future<void> importIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_importedKey) == true) return;

    final dietJson = jsonDecode(_dietPlanJson) as Map<String, dynamic>;
    final exerciseJson = jsonDecode(_exercisePlanJson) as Map<String, dynamic>;

    await StorageService.savePlan(WeekPlan.fromJson(dietJson));
    await StorageService.saveExercisePlan(
      WeekExercisePlan.fromJson(exerciseJson),
    );
    await prefs.setBool(_importedKey, true);
  }

  static const _dietPlanJson = '''
{
  "days": [
    {
      "day": "周一",
      "meals": {
        "breakfast": [
          {"food": "全麦吐司", "amount": "2片", "cal": 160},
          {"food": "煎蛋", "amount": "1个", "cal": 90},
          {"food": "脱脂牛奶", "amount": "250ml", "cal": 100}
        ],
        "lunch": [
          {"food": "糙米饭", "amount": "150g", "cal": 170},
          {"food": "清炒西兰花鸡胸肉", "amount": "一份", "cal": 280},
          {"food": "凉拌黄瓜", "amount": "一份", "cal": 40}
        ],
        "dinner": [
          {"food": "紫薯", "amount": "1个150g", "cal": 130},
          {"food": "番茄蛋花汤", "amount": "一碗", "cal": 80},
          {"food": "清炒菠菜", "amount": "一份", "cal": 60}
        ],
        "snack": [
          {"food": "苹果", "amount": "1个", "cal": 100}
        ]
      },
      "exercise": [],
      "total_intake": 1210,
      "total_burn": 0,
      "note": ""
    },
    {
      "day": "周二",
      "meals": {
        "breakfast": [
          {"food": "燕麦粥", "amount": "40g干燕麦", "cal": 150},
          {"food": "水煮蛋", "amount": "2个", "cal": 140},
          {"food": "豆浆", "amount": "300ml", "cal": 90}
        ],
        "lunch": [
          {"food": "杂粮饭", "amount": "150g", "cal": 170},
          {"food": "番茄炖牛腩", "amount": "瘦牛肉100g", "cal": 280},
          {"food": "蒜蓉生菜", "amount": "一份", "cal": 50}
        ],
        "dinner": [
          {"food": "玉米", "amount": "1根", "cal": 120},
          {"food": "清蒸鱼", "amount": "100g", "cal": 120},
          {"food": "凉拌木耳", "amount": "一份", "cal": 40}
        ],
        "snack": [
          {"food": "无糖酸奶", "amount": "200g", "cal": 120}
        ]
      },
      "exercise": [],
      "total_intake": 1280,
      "total_burn": 0,
      "note": ""
    },
    {
      "day": "周三",
      "meals": {
        "breakfast": [
          {"food": "荞麦面条", "amount": "干60g", "cal": 210},
          {"food": "卤蛋", "amount": "1个", "cal": 80},
          {"food": "小青菜", "amount": "一份", "cal": 30}
        ],
        "lunch": [
          {"food": "糙米饭", "amount": "150g", "cal": 170},
          {"food": "青椒炒鸡胸肉", "amount": "一份", "cal": 280},
          {"food": "豆腐海带汤", "amount": "一碗", "cal": 60}
        ],
        "dinner": [
          {"food": "南瓜", "amount": "200g蒸", "cal": 90},
          {"food": "白灼虾", "amount": "10只", "cal": 100},
          {"food": "清炒油麦菜", "amount": "一份", "cal": 50}
        ],
        "snack": [
          {"food": "香蕉", "amount": "半根", "cal": 50}
        ]
      },
      "exercise": [],
      "total_intake": 1120,
      "total_burn": 0,
      "note": ""
    },
    {
      "day": "周四",
      "meals": {
        "breakfast": [
          {"food": "全麦馒头", "amount": "1个80g", "cal": 180},
          {"food": "鸡蛋", "amount": "1个", "cal": 70},
          {"food": "脱脂牛奶", "amount": "250ml", "cal": 100}
        ],
        "lunch": [
          {"food": "杂粮饭", "amount": "150g", "cal": 170},
          {"food": "宫保鸡丁", "amount": "少油版", "cal": 300},
          {"food": "紫菜蛋花汤", "amount": "一碗", "cal": 50}
        ],
        "dinner": [
          {"food": "红薯", "amount": "1个150g", "cal": 130},
          {"food": "清炒虾仁西兰花", "amount": "一份", "cal": 180},
          {"food": "凉拌豆腐丝", "amount": "一份", "cal": 80}
        ],
        "snack": [
          {"food": "小番茄", "amount": "10颗", "cal": 50}
        ]
      },
      "exercise": [],
      "total_intake": 1310,
      "total_burn": 0,
      "note": ""
    },
    {
      "day": "周五",
      "meals": {
        "breakfast": [
          {"food": "燕麦粥", "amount": "40g", "cal": 150},
          {"food": "煎蛋", "amount": "1个", "cal": 90},
          {"food": "黄瓜", "amount": "半根", "cal": 15}
        ],
        "lunch": [
          {"food": "糙米饭", "amount": "150g", "cal": 170},
          {"food": "红烧豆腐", "amount": "少油", "cal": 180},
          {"food": "清炒芹菜牛肉丝", "amount": "一份", "cal": 250}
        ],
        "dinner": [
          {"food": "玉米", "amount": "1根", "cal": 120},
          {"food": "番茄鸡蛋汤", "amount": "一碗", "cal": 80},
          {"food": "白灼生菜", "amount": "一份", "cal": 30}
        ],
        "snack": [
          {"food": "猕猴桃", "amount": "1个", "cal": 60}
        ]
      },
      "exercise": [],
      "total_intake": 1145,
      "total_burn": 0,
      "note": ""
    },
    {
      "day": "周六",
      "meals": {
        "breakfast": [
          {"food": "杂粮煎饼", "amount": "1个", "cal": 250},
          {"food": "豆浆", "amount": "300ml", "cal": 90}
        ],
        "lunch": [
          {"food": "糙米饭", "amount": "150g", "cal": 170},
          {"food": "糖醋里脊", "amount": "少糖少油", "cal": 320},
          {"food": "蒜蓉娃娃菜", "amount": "一份", "cal": 50}
        ],
        "dinner": [
          {"food": "饺子", "amount": "10个猪肉白菜", "cal": 350},
          {"food": "凉拌黄瓜", "amount": "一份", "cal": 40}
        ],
        "snack": [
          {"food": "无糖酸奶", "amount": "200g", "cal": 120}
        ]
      },
      "exercise": [],
      "total_intake": 1390,
      "total_burn": 0,
      "note": "周六稍放松"
    },
    {
      "day": "周日",
      "meals": {
        "breakfast": [
          {"food": "紫薯燕麦粥", "amount": "一碗", "cal": 180},
          {"food": "水煮蛋", "amount": "2个", "cal": 140}
        ],
        "lunch": [
          {"food": "杂粮饭", "amount": "150g", "cal": 170},
          {"food": "香菇滑鸡", "amount": "去皮鸡腿肉", "cal": 260},
          {"food": "清炒丝瓜", "amount": "一份", "cal": 50}
        ],
        "dinner": [
          {"food": "全麦面条", "amount": "干80g", "cal": 280},
          {"food": "番茄牛肉酱", "amount": "一份", "cal": 120},
          {"food": "水煮青菜", "amount": "一份", "cal": 30}
        ],
        "snack": [
          {"food": "苹果", "amount": "1个", "cal": 100}
        ]
      },
      "exercise": [],
      "total_intake": 1330,
      "total_burn": 0,
      "note": ""
    }
  ]
}''';

  static const _exercisePlanJson = '''
{
  "days": [
    {
      "day": "周一",
      "type": "训练日",
      "focus": "有氧",
      "exercises": [
        {"name": "椭圆机中低阻力匀速", "equipment": "椭圆机", "sets": 1, "reps": "30分钟", "rest": "-", "cal": 250, "tip": "保持匀速，心率130左右"}
      ],
      "total_cal": 250,
      "note": "有氧日，保护膝盖"
    },
    {
      "day": "周二",
      "type": "休息日",
      "focus": "恢复",
      "exercises": [
        {"name": "泡沫滚轴全身放松+拉伸", "equipment": "泡沫滚轴", "sets": 1, "reps": "15分钟", "rest": "-", "cal": 30, "tip": "重点滚压大腿和背部"}
      ],
      "total_cal": 30,
      "note": "主动恢复"
    },
    {
      "day": "周三",
      "type": "训练日",
      "focus": "上肢+下肢",
      "exercises": [
        {"name": "哑铃深蹲", "equipment": "哑铃", "sets": 3, "reps": "12次", "rest": "60秒", "cal": 60, "tip": "膝盖不超过脚尖"},
        {"name": "哑铃推举", "equipment": "哑铃", "sets": 3, "reps": "10次", "rest": "60秒", "cal": 50, "tip": "核心收紧"},
        {"name": "哑铃划船", "equipment": "哑铃", "sets": 3, "reps": "每侧10次", "rest": "60秒", "cal": 50, "tip": "背部发力"},
        {"name": "哑铃弯举", "equipment": "哑铃", "sets": 3, "reps": "12次", "rest": "45秒", "cal": 30, "tip": "不要借力"},
        {"name": "哑铃硬拉", "equipment": "哑铃", "sets": 3, "reps": "12次", "rest": "60秒", "cal": 50, "tip": "腰背挺直"},
        {"name": "平板支撑", "equipment": "徒手", "sets": 3, "reps": "30秒", "rest": "45秒", "cal": 30, "tip": "身体一条直线"}
      ],
      "total_cal": 270,
      "note": "哑铃全身训练"
    },
    {
      "day": "周四",
      "type": "休息日",
      "focus": "活动",
      "exercises": [
        {"name": "散步或站立办公", "equipment": "徒手", "sets": 1, "reps": "30分钟", "rest": "-", "cal": 80, "tip": "久坐程序员要多站多走"}
      ],
      "total_cal": 80,
      "note": "轻度活动日"
    },
    {
      "day": "周五",
      "type": "训练日",
      "focus": "有氧间歇",
      "exercises": [
        {"name": "椭圆机间歇训练", "equipment": "椭圆机", "sets": 1, "reps": "25分钟", "rest": "-", "cal": 280, "tip": "2分钟中速+1分钟快交替"}
      ],
      "total_cal": 280,
      "note": "间歇有氧，燃脂效率高"
    },
    {
      "day": "周六",
      "type": "训练日",
      "focus": "核心",
      "exercises": [
        {"name": "健腹轮跪姿推出", "equipment": "健腹轮", "sets": 3, "reps": "8次", "rest": "60秒", "cal": 40, "tip": "不要塌腰"},
        {"name": "弹力带站姿划船", "equipment": "弹力带", "sets": 3, "reps": "12次", "rest": "45秒", "cal": 30, "tip": "夹紧肩胛骨"},
        {"name": "弹力带侧步走", "equipment": "弹力带", "sets": 3, "reps": "每方向10步", "rest": "45秒", "cal": 30, "tip": "保持半蹲姿态"},
        {"name": "仰卧蹬车", "equipment": "瑜伽垫", "sets": 3, "reps": "每侧12次", "rest": "45秒", "cal": 30, "tip": "慢一点，感受腹肌"},
        {"name": "臀桥", "equipment": "瑜伽垫", "sets": 3, "reps": "15次", "rest": "45秒", "cal": 30, "tip": "顶峰收紧臀部"},
        {"name": "泡沫滚轴放松", "equipment": "泡沫滚轴", "sets": 1, "reps": "10分钟", "rest": "-", "cal": 20, "tip": "训练后放松"}
      ],
      "total_cal": 180,
      "note": "核心训练日"
    },
    {
      "day": "周日",
      "type": "休息日",
      "focus": "恢复",
      "exercises": [
        {"name": "泡沫滚轴放松+拉伸", "equipment": "泡沫滚轴", "sets": 1, "reps": "15分钟", "rest": "-", "cal": 30, "tip": "全身放松，准备新的一周"}
      ],
      "total_cal": 30,
      "note": "充分休息"
    }
  ]
}''';
}
