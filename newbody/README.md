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
