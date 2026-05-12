// ============ 食物条目 ============
class FoodEntry {
  final String name;
  final int cal;
  final String date;
  final String time;

  FoodEntry({required this.name, required this.cal, required this.date, required this.time});

  Map<String, dynamic> toJson() => {'name': name, 'cal': cal, 'date': date, 'time': time};
  factory FoodEntry.fromJson(Map<String, dynamic> j) =>
      FoodEntry(name: j['name'], cal: j['cal'], date: j['date'], time: j['time']);
}

// ============ 运动条目 ============
class ExerciseEntry {
  final String name;
  final int cal;
  final String icon;
  final String date;
  final String time;

  ExerciseEntry({required this.name, required this.cal, required this.icon, required this.date, required this.time});

  Map<String, dynamic> toJson() => {'name': name, 'cal': cal, 'icon': icon, 'date': date, 'time': time};
  factory ExerciseEntry.fromJson(Map<String, dynamic> j) =>
      ExerciseEntry(name: j['name'], cal: j['cal'], icon: j['icon'] ?? '', date: j['date'], time: j['time']);
}

// ============ 体重记录 ============
class WeightEntry {
  final String date;
  final double weight;

  WeightEntry({required this.date, required this.weight});

  Map<String, dynamic> toJson() => {'date': date, 'weight': weight};
  factory WeightEntry.fromJson(Map<String, dynamic> j) =>
      WeightEntry(date: j['date'], weight: (j['weight'] as num).toDouble());
}

// ============ 情绪打卡 ============
class MindEntry {
  final String emotion;
  final bool isReallyHungry;
  final String choice;
  final String date;
  final String time;

  MindEntry({required this.emotion, required this.isReallyHungry, required this.choice, required this.date, required this.time});

  Map<String, dynamic> toJson() => {
        'emotion': emotion,
        'isReallyHungry': isReallyHungry,
        'choice': choice,
        'date': date,
        'time': time,
      };
  factory MindEntry.fromJson(Map<String, dynamic> j) => MindEntry(
        emotion: j['emotion'] ?? '',
        isReallyHungry: j['isReallyHungry'] ?? false,
        choice: j['choice'] ?? '',
        date: j['date'] ?? '',
        time: j['time'] ?? '',
      );
}

// ============ 全局数据 ============
class AppData {
  List<WeightEntry> weightLog;
  List<FoodEntry> foodLog;
  List<ExerciseEntry> exerciseLog;
  List<MindEntry> mindLog;

  AppData({List<WeightEntry>? weightLog, List<FoodEntry>? foodLog, List<ExerciseEntry>? exerciseLog, List<MindEntry>? mindLog})
      : weightLog = weightLog ?? [],
        foodLog = foodLog ?? [],
        exerciseLog = exerciseLog ?? [],
        mindLog = mindLog ?? [];

  Map<String, dynamic> toJson() => {
        'weightLog': weightLog.map((e) => e.toJson()).toList(),
        'foodLog': foodLog.map((e) => e.toJson()).toList(),
        'exerciseLog': exerciseLog.map((e) => e.toJson()).toList(),
        'mindLog': mindLog.map((e) => e.toJson()).toList(),
      };

  factory AppData.fromJson(Map<String, dynamic> j) => AppData(
        weightLog: (j['weightLog'] as List?)?.map((e) => WeightEntry.fromJson(e)).toList(),
        foodLog: (j['foodLog'] as List?)?.map((e) => FoodEntry.fromJson(e)).toList(),
        exerciseLog: (j['exerciseLog'] as List?)?.map((e) => ExerciseEntry.fromJson(e)).toList(),
        mindLog: (j['mindLog'] as List?)?.map((e) => MindEntry.fromJson(e)).toList(),
      );
}

// ============ AI计划 ============
class MealItem {
  final String food;
  final String amount;
  final int cal;

  MealItem({required this.food, required this.amount, required this.cal});

  factory MealItem.fromJson(Map<String, dynamic> j) =>
      MealItem(food: j['food'] ?? '', amount: j['amount'] ?? '', cal: j['cal'] ?? 0);
  Map<String, dynamic> toJson() => {'food': food, 'amount': amount, 'cal': cal};
}

class ExercisePlanItem {
  final String name;
  final String duration;
  final int cal;

  ExercisePlanItem({required this.name, required this.duration, required this.cal});

  factory ExercisePlanItem.fromJson(Map<String, dynamic> j) =>
      ExercisePlanItem(name: j['name'] ?? '', duration: j['duration'] ?? '', cal: j['cal'] ?? 0);
  Map<String, dynamic> toJson() => {'name': name, 'duration': duration, 'cal': cal};
}

class DayPlan {
  final String day;
  final Map<String, List<MealItem>> meals;
  final List<ExercisePlanItem> exercise;
  final int totalIntake;
  final int totalBurn;
  final String? note;

  DayPlan({required this.day, required this.meals, required this.exercise, required this.totalIntake, required this.totalBurn, this.note});

  factory DayPlan.fromJson(Map<String, dynamic> j) {
    final mealsJson = j['meals'] as Map<String, dynamic>? ?? {};
    final meals = <String, List<MealItem>>{};
    mealsJson.forEach((k, v) {
      meals[k] = (v as List).map((e) => MealItem.fromJson(e)).toList();
    });
    return DayPlan(
      day: j['day'] ?? '',
      meals: meals,
      exercise: (j['exercise'] as List?)?.map((e) => ExercisePlanItem.fromJson(e)).toList() ?? [],
      totalIntake: j['total_intake'] ?? 0,
      totalBurn: j['total_burn'] ?? 0,
      note: j['note'],
    );
  }

  Map<String, dynamic> toJson() => {
        'day': day,
        'meals': meals.map((k, v) => MapEntry(k, v.map((e) => e.toJson()).toList())),
        'exercise': exercise.map((e) => e.toJson()).toList(),
        'total_intake': totalIntake,
        'total_burn': totalBurn,
        'note': note,
      };
}

class WeekPlan {
  final List<DayPlan> days;

  WeekPlan({required this.days});

  factory WeekPlan.fromJson(Map<String, dynamic> j) =>
      WeekPlan(days: (j['days'] as List).map((e) => DayPlan.fromJson(e)).toList());
  Map<String, dynamic> toJson() => {'days': days.map((e) => e.toJson()).toList()};
}

// ============ 食物/运动数据库 ============
class FoodItem {
  final String name;
  final int cal;
  const FoodItem(this.name, this.cal);
}

class ExerciseItem {
  final String name;
  final int cal;
  final String icon;
  const ExerciseItem(this.name, this.cal, this.icon);
}

const List<FoodItem> foodDB = [
  FoodItem('米饭(一碗200g)', 232), FoodItem('馒头(一个100g)', 223),
  FoodItem('面条(一碗200g)', 280), FoodItem('鸡蛋(一个50g)', 72),
  FoodItem('鸡胸肉(100g)', 133), FoodItem('牛肉(100g)', 125),
  FoodItem('猪肉(瘦100g)', 143), FoodItem('豆腐(100g)', 81),
  FoodItem('西兰花(100g)', 34), FoodItem('番茄(一个150g)', 27),
  FoodItem('黄瓜(一根200g)', 32), FoodItem('苹果(一个200g)', 104),
  FoodItem('香蕉(一根120g)', 106), FoodItem('牛奶(250ml)', 163),
  FoodItem('酸奶(200g)', 144), FoodItem('红薯(一个200g)', 172),
  FoodItem('玉米(一根200g)', 224), FoodItem('可乐(330ml)', 139),
  FoodItem('方便面(一包)', 450), FoodItem('饺子(10个200g)', 420),
  FoodItem('包子(一个100g)', 220), FoodItem('豆浆(300ml)', 105),
];

const List<ExerciseItem> exerciseDB = [
  ExerciseItem('散步30分钟', 120, '🚶'), ExerciseItem('快走30分钟', 180, '🏃'),
  ExerciseItem('站立办公1小时', 50, '🧍'), ExerciseItem('饭后站立15分钟', 20, '🧍'),
  ExerciseItem('爬楼梯10分钟', 80, '🪜'), ExerciseItem('骑车30分钟', 200, '🚲'),
  ExerciseItem('拉伸15分钟', 40, '🤸'), ExerciseItem('深蹲20个', 30, '💪'),
  ExerciseItem('跳绳15分钟', 200, '⏫'),
];
