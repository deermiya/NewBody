import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/data_models.dart';
import '../widgets/common.dart';

class ShoppingListPage extends StatefulWidget {
  final WeekPlan plan;
  const ShoppingListPage({super.key, required this.plan});

  @override
  State<ShoppingListPage> createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends State<ShoppingListPage> {
  final Set<String> _checked = {};

  // 食物名 → 购买食材列表（一道菜可能需要多种食材）
  static final _ingredientMap = <String, List<_Ing>>{
    // 主食/谷物
    '全麦吐司': [_Ing('全麦吐司', '1包', '主食')],
    '糙米饭': [_Ing('糙米', '1kg', '主食')],
    '杂粮饭': [_Ing('杂粮米', '1kg', '主食')],
    '紫薯': [_Ing('紫薯', '500g', '主食')],
    '玉米': [_Ing('玉米', '3根', '主食')],
    '荞麦面条': [_Ing('荞麦面', '1包', '主食')],
    '全麦馒头': [_Ing('全麦馒头', '1袋', '主食')],
    '红薯': [_Ing('红薯', '500g', '主食')],
    '燕麦粥': [_Ing('燕麦片', '1袋(400g)', '主食')],
    '杂粮煎饼': [_Ing('杂粮煎饼粉', '1袋', '主食')],
    '全麦面条': [_Ing('全麦面条', '1包', '主食')],
    '紫薯燕麦粥': [_Ing('紫薯', '500g', '主食'), _Ing('燕麦片', '1袋(400g)', '主食')],
    '饺子': [_Ing('饺子皮+猪肉馅', '各500g', '主食')],

    // 蛋奶豆
    '煎蛋': [_Ing('鸡蛋', '1盒(10个)', '蛋奶')],
    '水煮蛋': [_Ing('鸡蛋', '1盒(10个)', '蛋奶')],
    '卤蛋': [_Ing('鸡蛋', '1盒(10个)', '蛋奶')],
    '鸡蛋': [_Ing('鸡蛋', '1盒(10个)', '蛋奶')],
    '脱脂牛奶': [_Ing('脱脂牛奶', '1箱', '蛋奶')],
    '豆浆': [_Ing('黄豆', '500g', '蛋奶')],
    '无糖酸奶': [_Ing('无糖酸奶', '4杯', '蛋奶')],
    '豆腐海带汤': [_Ing('豆腐', '2块', '蛋奶'), _Ing('海带', '1份', '蔬菜')],
    '凉拌豆腐丝': [_Ing('豆腐丝', '1包', '蛋奶')],
    '红烧豆腐': [_Ing('北豆腐', '2块', '蛋奶')],

    // 肉类+蔬菜（复合菜品）
    '清炒西兰花鸡胸肉': [_Ing('鸡胸肉', '500g', '肉类'), _Ing('西兰花', '2颗', '蔬菜')],
    '青椒炒鸡胸肉': [_Ing('鸡胸肉', '500g', '肉类'), _Ing('青椒', '4个', '蔬菜')],
    '宫保鸡丁': [_Ing('鸡胸肉', '500g', '肉类'), _Ing('花生米', '1小袋', '调料')],
    '香菇滑鸡': [_Ing('鸡腿肉(去皮)', '500g', '肉类'), _Ing('香菇', '200g', '蔬菜')],
    '番茄炖牛腩': [_Ing('牛腩', '500g', '肉类'), _Ing('番茄', '4个', '蔬菜')],
    '清炒芹菜牛肉丝': [_Ing('牛肉', '300g', '肉类'), _Ing('芹菜', '1把', '蔬菜')],
    '番茄牛肉酱': [_Ing('牛肉馅', '300g', '肉类'), _Ing('番茄', '4个', '蔬菜')],
    '糖醋里脊': [_Ing('猪里脊', '300g', '肉类')],
    '清蒸鱼': [_Ing('鲈鱼/龙利鱼', '1条', '肉类'), _Ing('姜', '1块', '调料'), _Ing('葱', '1把', '调料')],
    '白灼虾': [_Ing('鲜虾', '500g', '肉类'), _Ing('姜', '1块', '调料')],
    '清炒虾仁西兰花': [_Ing('虾仁', '300g', '肉类'), _Ing('西兰花', '2颗', '蔬菜')],

    // 纯蔬菜
    '凉拌黄瓜': [_Ing('黄瓜', '3根', '蔬菜')],
    '黄瓜': [_Ing('黄瓜', '3根', '蔬菜')],
    '清炒菠菜': [_Ing('菠菜', '1把', '蔬菜')],
    '番茄蛋花汤': [_Ing('番茄', '4个', '蔬菜'), _Ing('鸡蛋', '1盒(10个)', '蛋奶')],
    '番茄鸡蛋汤': [_Ing('番茄', '4个', '蔬菜'), _Ing('鸡蛋', '1盒(10个)', '蛋奶')],
    '蒜蓉生菜': [_Ing('生菜', '2颗', '蔬菜')],
    '白灼生菜': [_Ing('生菜', '2颗', '蔬菜')],
    '凉拌木耳': [_Ing('干木耳', '1包', '蔬菜')],
    '小青菜': [_Ing('小青菜', '1把', '蔬菜')],
    '清炒油麦菜': [_Ing('油麦菜', '1把', '蔬菜')],
    '南瓜': [_Ing('南瓜', '半个', '蔬菜')],
    '蒜蓉娃娃菜': [_Ing('娃娃菜', '2颗', '蔬菜')],
    '清炒丝瓜': [_Ing('丝瓜', '2根', '蔬菜')],
    '水煮青菜': [_Ing('小青菜', '1把', '蔬菜')],

    // 水果
    '苹果': [_Ing('苹果', '3个', '水果')],
    '香蕉': [_Ing('香蕉', '1把', '水果')],
    '小番茄': [_Ing('小番茄', '1盒', '水果')],
    '猕猴桃': [_Ing('猕猴桃', '3个', '水果')],

    // 调料/其他
    '紫菜蛋花汤': [_Ing('紫菜', '1包', '调料'), _Ing('鸡蛋', '1盒(10个)', '蛋奶')],
  };

  Map<String, List<_ShoppingItem>> _buildCategories() {
    final Map<String, Set<_ShoppingItem>> catItems = {
      '主食/谷物': {},
      '蔬菜': {},
      '肉类/水产': {},
      '蛋奶/豆制品': {},
      '水果': {},
      '调料/其他': {},
    };

    for (final day in widget.plan.days) {
      for (final mealEntries in day.meals.values) {
        for (final item in mealEntries) {
          final ings = _ingredientMap[item.food];
          if (ings != null) {
            for (final ing in ings) {
              final catKey = switch (ing.category) {
                '主食' => '主食/谷物',
                '蔬菜' => '蔬菜',
                '肉类' => '肉类/水产',
                '蛋奶' => '蛋奶/豆制品',
                '水果' => '水果',
                _ => '调料/其他',
              };
              catItems[catKey]!.add(_ShoppingItem(ing.name, ing.amount));
            }
          }
        }
      }
    }

    return {
      for (final e in catItems.entries)
        e.key: e.value.toList()..sort((a, b) => a.name.compareTo(b.name)),
    }..removeWhere((_, v) => v.isEmpty);
  }

  void _copyList() {
    final cats = _buildCategories();
    final sb = StringBuffer();
    sb.writeln('🛒 本周购物清单');
    sb.writeln('');
    for (final entry in cats.entries) {
      sb.writeln('【${entry.key}】');
      for (final item in entry.value) {
        final mark = _checked.contains('${entry.key}-${item.name}') ? '✅' : '⬜';
        sb.writeln('$mark ${item.name} ${item.amount}');
      }
      sb.writeln('');
    }
    Clipboard.setData(ClipboardData(text: sb.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('购物清单已复制'), backgroundColor: C.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cats = _buildCategories();
    final totalItems = cats.values.fold(0, (s, v) => s + v.length);
    final checkedCount = _checked.length;

    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, totalItems, checkedCount),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                children: [
                  for (final entry in cats.entries) ...[
                    _buildCategoryHeader(entry.key, entry.value.length),
                    const SizedBox(height: 8),
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (int i = 0; i < entry.value.length; i++)
                            _buildItemRow(entry.key, entry.value[i]),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int total, int checked) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: C.border, width: 0.5)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: C.bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: C.textSecondary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.shopping_cart_rounded, color: C.green, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '购物清单',
                  style: TextStyle(
                    color: C.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '已选 $checked / $total 项',
                  style: const TextStyle(
                    color: C.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _copyList,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: C.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.copy_rounded, size: 14, color: C.green),
                  SizedBox(width: 4),
                  Text(
                    '复制',
                    style: TextStyle(
                      color: C.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(String name, int count) {
    final icon = switch (name) {
      '主食/谷物' => Icons.rice_bowl_rounded,
      '蔬菜' => Icons.eco_rounded,
      '肉类/水产' => Icons.set_meal_rounded,
      '蛋奶/豆制品' => Icons.egg_rounded,
      '水果' => Icons.apple_rounded,
      _ => Icons.kitchen_rounded,
    };
    final color = switch (name) {
      '主食/谷物' => C.amber,
      '蔬菜' => C.green,
      '肉类/水产' => C.rose,
      '蛋奶/豆制品' => C.purple,
      '水果' => C.cyan,
      _ => C.textMuted,
    };

    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            name,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(String category, _ShoppingItem item) {
    final key = '$category-${item.name}';
    final checked = _checked.contains(key);

    return InkWell(
      onTap: () {
        setState(() {
          if (checked) {
            _checked.remove(key);
          } else {
            _checked.add(key);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: C.border, width: 0.5)),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: checked ? C.green : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: checked ? C.green : C.border,
                  width: 1.5,
                ),
              ),
              child: checked
                  ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                item.name,
                style: TextStyle(
                  color: checked ? C.textMuted : C.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  decoration: checked ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            Text(
              item.amount,
              style: TextStyle(
                color: checked ? C.textDim : C.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Ing {
  final String name;
  final String amount;
  final String category;
  const _Ing(this.name, this.amount, this.category);
}

class _ShoppingItem {
  final String name;
  final String amount;
  const _ShoppingItem(this.name, this.amount);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _ShoppingItem && name == other.name;

  @override
  int get hashCode => name.hashCode;
}
