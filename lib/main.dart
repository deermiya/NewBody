import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/data_models.dart';
import 'services/storage_service.dart';
import 'widgets/common.dart';
import 'pages/home_page.dart';
import 'pages/food_page.dart';
import 'pages/exercise_page.dart';
import 'pages/trend_page.dart';
import 'pages/mind_page.dart';
import 'config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark, // 亮色背景使用深色图标
      systemNavigationBarColor: C.bg,
    ),
  );
  runApp(const NewBodyApp());
}

class NewBodyApp extends StatelessWidget {
  const NewBodyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NewBody Mint',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: C.bg,
        fontFamily: 'PingFang SC',
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        colorScheme: ColorScheme.fromSeed(
          seedColor: C.green,
          brightness: Brightness.light,
          surface: C.bgSurface,
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _tabIndex = 0;
  AppData _data = AppData();
  WeekPlan? _plan;
  bool _loaded = false;
  int _exercisePlanVersion = 0;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await AppConfig.load();
    final data = await StorageService.loadData();
    final plan = await StorageService.loadPlan();
    setState(() {
      _data = data;
      _plan = plan;
      _loaded = true;
    });
  }

  void _updateData(AppData newData) {
    setState(() => _data = newData);
    StorageService.saveData(newData);
  }

  Future<void> _reloadLocalState() async {
    await AppConfig.load();
    final data = await StorageService.loadData();
    final plan = await StorageService.loadPlan();
    if (!mounted) return;
    setState(() {
      _data = data;
      _plan = plan;
      _exercisePlanVersion++;
    });
  }

  double get _latestWeight {
    if (_data.weightLog.isNotEmpty) return _data.weightLog.last.weight;
    return AppConfig.startWeight;
  }

  List<FoodEntry> get _todayFood =>
      _data.foodLog.where((f) => f.date == todayStr()).toList();
  List<ExerciseEntry> get _todayExercise =>
      _data.exerciseLog.where((e) => e.date == todayStr()).toList();
  int get _todayCal => _todayFood.fold(0, (s, f) => s + f.cal);
  int get _todayBurn => _todayExercise.fold(0, (s, e) => s + e.cal);
  int get _todayMindCount =>
      _data.mindLog.where((m) => m.date == todayStr()).length;

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: C.green)),
      );
    }

    final pages = [
      HomePage(
        data: _data,
        updateData: _updateData,
        plan: _plan,
        todayCal: _todayCal,
        todayBurn: _todayBurn,
        latestWeight: _latestWeight,
        onConfigChanged: () => setState(() {}),
        onPlansImported: _reloadLocalState,
      ),
      FoodPage(data: _data, updateData: _updateData, todayCal: _todayCal),
      ExercisePage(
        key: ValueKey(_exercisePlanVersion),
        data: _data,
        updateData: _updateData,
        todayExercise: _todayExercise,
        todayBurn: _todayBurn,
      ),
      TrendPage(
        data: _data,
        updateData: _updateData,
        latestWeight: _latestWeight,
      ),
      MindPage(data: _data, getTodayMindCount: () => _todayMindCount),
    ];

    return Scaffold(
      extendBody: true,
      body: SafeArea(
        child: IndexedStack(index: _tabIndex, children: pages),
      ),
      bottomNavigationBar: _buildNavbar(),
    );
  }

  Widget _buildNavbar() {
    return Container(
      height: 80,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: C.green.withOpacity(0.08), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: C.green.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavBtn(0, Icons.home_rounded, '首页'),
                _NavBtn(1, Icons.restaurant_rounded, '饮食'),
                _NavBtn(2, Icons.fitness_center_rounded, '运动'),
                _NavBtn(3, Icons.analytics_rounded, '趋势'),
                _NavBtn(4, Icons.visibility_rounded, '觉察'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ignore: non_constant_identifier_names
  Widget _NavBtn(int index, IconData icon, String label) {
    final active = _tabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _tabIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: active ? C.cyan.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: active ? C.green : C.textMuted, size: 24),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: active ? C.green : C.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
