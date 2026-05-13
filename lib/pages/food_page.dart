import 'package:flutter/material.dart';
import '../config.dart';
import '../models/data_models.dart';
import '../widgets/common.dart';
import 'shopping_list_page.dart';

class FoodPage extends StatefulWidget {
  final AppData data;
  final void Function(AppData) updateData;
  final int todayCal;
  final WeekPlan? plan;

  const FoodPage({super.key, required this.data, required this.updateData, required this.todayCal, this.plan});

  @override
  State<FoodPage> createState() => _FoodPageState();
}

class _FoodPageState extends State<FoodPage> {
  String _search = '';
  String _customName = '';
  String _customCal = '';
  bool _showCustom = false;

  int get remaining => AppConfig.dailyCalorieTarget - widget.todayCal;
  List<FoodEntry> get todayFoods => widget.data.foodLog.where((f) => f.date == todayStr()).toList();
  List<FoodItem> get filtered => _search.isEmpty ? foodDB : foodDB.where((f) => f.name.contains(_search)).toList();

  void _addFood(String name, int cal) {
    final entry = FoodEntry(name: name, cal: cal, date: todayStr(), time: nowTime());
    final newData = AppData(
      weightLog: widget.data.weightLog,
      foodLog: [...widget.data.foodLog, entry],
      exerciseLog: widget.data.exerciseLog,
    );
    widget.updateData(newData);
  }

  void _removeFood(int todayIndex) {
    final allWithIndex = <int>[];
    for (int i = 0; i < widget.data.foodLog.length; i++) {
      if (widget.data.foodLog[i].date == todayStr()) allWithIndex.add(i);
    }
    if (todayIndex >= allWithIndex.length) return;
    final removeAt = allWithIndex[todayIndex];
    final newList = List<FoodEntry>.from(widget.data.foodLog)..removeAt(removeAt);
    widget.updateData(AppData(weightLog: widget.data.weightLog, foodLog: newList, exerciseLog: widget.data.exerciseLog));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: C.bg,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('饮食记录', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: C.textPrimary)),
              _buildTopBadge(),
            ],
          ),
          const SizedBox(height: 24),

          // Search and Custom
          _buildSearchBox(),
          const SizedBox(height: 16),

          // Shopping List Entry
          if (widget.plan != null)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ShoppingListPage(plan: widget.plan!),
                  ),
                );
              },
              child: AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                borderColor: C.cyan.withOpacity(0.18),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: C.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.shopping_cart_rounded,
                        color: C.amber,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '本周购物清单',
                            style: TextStyle(
                              color: C.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '根据饮食计划自动生成，可勾选已买食材',
                            style: TextStyle(
                              color: C.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: C.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          if (widget.plan != null) const SizedBox(height: 8),

          // Today Log
          if (todayFoods.isNotEmpty) ...[
            const Text('今日已记录', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: C.textSecondary)),
            const SizedBox(height: 12),
            for (int i = 0; i < todayFoods.length; i++)
              _LogRow(food: todayFoods[i], onDelete: () => _removeFood(i)),
            const SizedBox(height: 24),
          ],

          // Common Foods Database
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('推荐库', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: C.textSecondary)),
              GestureDetector(
                onTap: () => setState(() => _showCustom = !_showCustom),
                child: Text(_showCustom ? '取消' : '+ 自定义', style: const TextStyle(color: C.green, fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_showCustom) _buildCustomInput(),
          
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final f in filtered)
                  _DatabaseRow(food: f, onAdd: () => _addFood(f.name, f.cal)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (remaining >= 0 ? C.green : C.rose).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: (remaining >= 0 ? C.green : C.rose).withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(remaining >= 0 ? Icons.check_circle_outline : Icons.warning_amber_rounded, size: 14, color: remaining >= 0 ? C.green : C.rose),
          const SizedBox(width: 6),
          Text(
            remaining >= 0 ? '还可吃 $remaining' : '超标 ${-remaining}',
            style: TextStyle(color: remaining >= 0 ? C.green : C.rose, fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.border),
      ),
      child: TextField(
        onChanged: (v) => setState(() => _search = v),
        style: const TextStyle(color: C.textPrimary, fontSize: 14),
        decoration: const InputDecoration(
          hintText: '搜索或选择食物...',
          hintStyle: TextStyle(color: C.textMuted),
          prefixIcon: Icon(Icons.search_rounded, color: C.textMuted, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildCustomInput() {
    return AppCard(
      borderColor: C.green.withOpacity(0.3),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => _customName = v,
                  style: const TextStyle(color: C.textPrimary, fontSize: 14),
                  decoration: const InputDecoration(hintText: '食物名称', hintStyle: TextStyle(color: C.textMuted, fontSize: 13), border: InputBorder.none),
                ),
              ),
              Container(width: 1, height: 20, color: C.border),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  onChanged: (v) => _customCal = v,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: C.textPrimary, fontSize: 14),
                  decoration: const InputDecoration(hintText: '热量 (kcal)', hintStyle: TextStyle(color: C.textMuted, fontSize: 13), border: InputBorder.none),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GradientButton(
            text: '添加自定义项',
            onTap: () {
              final cal = int.tryParse(_customCal);
              if (_customName.isNotEmpty && cal != null) {
                _addFood(_customName, cal);
                setState(() { _customName = ''; _customCal = ''; _showCustom = false; });
              }
            },
          ),
        ],
      ),
    );
  }
}

class _DatabaseRow extends StatelessWidget {
  final FoodItem food;
  final VoidCallback onAdd;
  const _DatabaseRow({required this.food, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onAdd,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: C.border, width: 0.5))),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: C.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.fastfood_rounded, size: 16, color: C.amber),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(food.name, style: const TextStyle(color: C.textPrimary, fontSize: 14, fontWeight: FontWeight.w600))),
            Text('${food.cal}kcal', style: const TextStyle(color: C.textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(width: 12),
            const Icon(Icons.add_circle_outline_rounded, color: C.green, size: 20),
          ],
        ),
      ),
    );
  }
}

class _LogRow extends StatelessWidget {
  final FoodEntry food;
  final VoidCallback onDelete;
  const _LogRow({required this.food, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.border),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(food.name, style: const TextStyle(color: C.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(food.time, style: const TextStyle(color: C.textMuted, fontSize: 11)),
            ],
          ),
          const Spacer(),
          Text('${food.cal} kcal', style: const TextStyle(color: C.amber, fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: onDelete,
            child: Icon(Icons.close_rounded, size: 18, color: C.rose.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }
}
