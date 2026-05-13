# NewBody - 减肥助手 Flutter APP

## 快速开始

```bash
# 1. 创建Flutter工程
flutter create newbody
cd newbody

# 2. 用本项目文件覆盖
#    - 替换 lib/ 文件夹
#    - 替换 pubspec.yaml
#    - 把 assets/ 放到项目根目录

# 3. 生成APP图标（需要先把 assets/icon.svg 转成 icon.png）
#    推荐用 https://svgtopng.com 转换，1024x1024
#    然后执行：
flutter pub get
dart run flutter_launcher_icons

# 4. 配置API Key
#    编辑 lib/config.dart，填入你的 Anthropic API Key
#    ⚠️ 正式发布时应改为后端代理，不要把Key打包进APK

# 5. 运行
flutter run
```

## 项目结构

```
lib/
├── main.dart              # 入口 + 底部导航
├── config.dart            # 用户配置（身高体重目标等）
├── models/
│   └── data_models.dart   # 数据模型（食物/运动/体重/计划）
├── services/
│   ├── storage_service.dart  # SharedPreferences 持久化
│   └── ai_service.dart       # Anthropic API 调用
├── pages/
│   ├── home_page.dart     # 首页（进度环+今日计划）
│   ├── food_page.dart     # 饮食记录
│   ├── exercise_page.dart # 运动打卡
│   ├── trend_page.dart    # 体重趋势图
│   └── ai_page.dart       # AI对话+生成周计划
└── widgets/
    └── common.dart        # 主题色/通用组件/工具函数
```

## 后续可扩展

- 本地通知提醒（flutter_local_notifications）
- 计步器接入（pedometer_2）
- 数据导出CSV
- 深色/浅色主题切换
- 目标体重动态设置页


## JSON 外部导入功能
请按 NewBody APP 可导入 JSON 格式输出计划。只输出 JSON，不要 Markdown，不要解释，不要代码块。

根对象格式：

```json
{
  "diet_plan": {
    "days": [
      {
        "day": "周一",
        "meals": {
          "breakfast": [
            { "food": "食物名", "amount": "数量/重量", "cal": 数字 }
          ],
          "lunch": [
            { "food": "食物名", "amount": "数量/重量", "cal": 数字 }
          ],
          "dinner": [
            { "food": "食物名", "amount": "数量/重量", "cal": 数字 }
          ],
          "snack": [
            { "food": "食物名", "amount": "数量/重量", "cal": 数字 }
          ]
        },
        "exercise": [
          { "name": "运动名", "duration": "时长", "cal": 数字 }
        ],
        "total_intake": 数字,
        "total_burn": 数字,
        "note": "备注，可为空字符串"
      }
    ]
  },
  "exercise_plan": {
    "days": [
      {
        "day": "周一",
        "type": "训练日",
        "focus": "训练重点",
        "exercises": [
          {
            "name": "动作名",
            "equipment": "器械名或徒手",
            "sets": 数字,
            "reps": "次数/时长",
            "rest": "休息时间",
            "cal": 数字,
            "tip": "动作提示，可为空字符串"
          }
        ],
        "total_cal": 数字,
        "note": "备注，可为空字符串"
      }
    ]
  }
}
```

```
生成要求：
1. diet_plan.days 必须正好 7 天，day 依次为：周一、周二、周三、周四、周五、周六、周日。
2. exercise_plan.days 必须正好 7 天，day 依次为：周一、周二、周三、周四、周五、周六、周日。
3. 所有 cal、total_intake、total_burn、total_cal、sets 必须是数字，不要写成字符串，不要带 kcal。
4. meals 必须包含 breakfast、lunch、dinner、snack 四个字段；没有加餐时 snack 用空数组 []。
5. 饮食计划里的 exercise 可以为空数组 []。
6. 运动休息日这样写：
   {
     "day": "周二",
     "type": "休息日",
     "focus": "恢复",
     "exercises": [],
     "total_cal": 0,
     "note": "散步或轻度拉伸"
   }
7. 不要输出 plan_name、level、summary、建议说明等额外字段。
8. 不要使用注释，不要省略号，不要尾随逗号，必须是合法 JSON。
```
