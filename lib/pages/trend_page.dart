import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../config.dart';
import '../models/data_models.dart';
import '../widgets/common.dart';
import '../services/export_service.dart';

class TrendPage extends StatefulWidget {
  final AppData data;
  final void Function(AppData) updateData;
  final double latestWeight;

  const TrendPage({
    super.key,
    required this.data,
    required this.updateData,
    required this.latestWeight,
  });

  @override
  State<TrendPage> createState() => _TrendPageState();
}

class _TrendPageState extends State<TrendPage> {
  final _controller = TextEditingController();

  bool get todayRecorded =>
      widget.data.weightLog.any((w) => w.date == todayStr());

  void _recordWeight() {
    final w = double.tryParse(_controller.text);
    if (w == null || w < 30 || w > 200) return;
    final existing = widget.data.weightLog
        .where((l) => l.date != todayStr())
        .toList();
    final newLog = [...existing, WeightEntry(date: todayStr(), weight: w)]
      ..sort((a, b) => a.date.compareTo(b.date));
    widget.updateData(
      AppData(
        weightLog: newLog,
        foodLog: widget.data.foodLog,
        exerciseLog: widget.data.exerciseLog,
      ),
    );
    _controller.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<_ChartPoint> chartData = widget.data.weightLog
        .map((w) => _ChartPoint(w.date.substring(5), w.weight * 2))
        .toList();

    return Container(
      color: C.bg,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '体重趋势',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: C.textPrimary,
                ),
              ),
              Row(
                children: [
                  _buildExportBtn(),
                  const SizedBox(width: 8),
                  _buildDiffBadge(),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Input Card
          _buildInputCard(),
          const SizedBox(height: 24),

          // Chart Section
          if (chartData.length > 1) ...[
            const Text(
              '体重曲线',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: C.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              padding: const EdgeInsets.fromLTRB(10, 24, 24, 10),
              child: SizedBox(height: 240, child: _buildChart(chartData)),
            ),
          ] else
            _buildEmptyChart(),
          const SizedBox(height: 24),

          // History Section
          if (widget.data.weightLog.isNotEmpty) ...[
            const Text(
              '历史记录',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: C.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final w in widget.data.weightLog.reversed.take(14))
                    _HistoryRow(entry: w),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExportBtn() {
    return GestureDetector(
      onTap: () async {
        final total = widget.data.weightLog.length +
            widget.data.foodLog.length +
            widget.data.exerciseLog.length +
            widget.data.mindLog.length;
        if (total == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('还没有任何记录可以导出'), backgroundColor: C.rose),
          );
          return;
        }
        try {
          await ExportService.exportAll(widget.data);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('导出失败: $e'), backgroundColor: C.rose),
            );
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: C.green.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: C.green.withOpacity(0.2)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.ios_share_rounded, size: 14, color: C.green),
            SizedBox(width: 5),
            Text(
              '导出',
              style: TextStyle(color: C.green, fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiffBadge() {
    final diff = AppConfig.startWeight - widget.latestWeight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: C.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: C.purple.withOpacity(0.2)),
      ),
      child: Text(
        '已减 ${(diff * 2).toStringAsFixed(1)} 斤',
        style: const TextStyle(
          color: C.purple,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.monitor_weight_rounded,
                color: C.green,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                todayRecorded ? '今日记录已完成' : '输入今日体重',
                style: const TextStyle(
                  color: C.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: C.bg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: C.border),
                  ),
                  child: TextField(
                    controller: _controller,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: const TextStyle(
                      color: C.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: const InputDecoration(
                      hintText: '00.0',
                      hintStyle: TextStyle(color: C.textMuted),
                      border: InputBorder.none,
                      suffixText: 'kg',
                      suffixStyle: TextStyle(color: C.textMuted, fontSize: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 100,
                child: GradientButton(
                  text: todayRecorded ? '更新' : '记录',
                  onTap: _recordWeight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChart() {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(
            Icons.show_chart_rounded,
            color: C.textDim.withOpacity(0.5),
            size: 40,
          ),
          const SizedBox(height: 12),
          const Text(
            '记录2天以上体重后显示趋势图',
            style: TextStyle(color: C.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(List<_ChartPoint> points) {
    final targetJin = AppConfig.targetWeight * 2;
    final minY = (targetJin - 5).floorToDouble();
    final maxY = points.map((p) => p.value).reduce((a, b) => a > b ? a : b) + 5;

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: const FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 5,
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (val, _) {
                final idx = val.toInt();
                if (idx < 0 ||
                    idx >= points.length ||
                    (points.length > 7 && idx % 2 != 0))
                  return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    points[idx].label,
                    style: const TextStyle(color: C.textMuted, fontSize: 10),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (val, _) => Text(
                val.toStringAsFixed(0),
                style: const TextStyle(color: C.textMuted, fontSize: 10),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: targetJin,
              color: C.green.withOpacity(0.3),
              strokeWidth: 1.5,
              dashArray: [6, 4],
            ),
          ],
        ),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              points.length,
              (i) => FlSpot(i.toDouble(), points[i].value),
            ),
            isCurved: true,
            color: C.purple,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                    radius: 4,
                    color: C.purple,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [C.purple.withOpacity(0.1), C.purple.withOpacity(0.0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => C.green,
            getTooltipItems: (spots) => spots
                .map(
                  (s) => LineTooltipItem(
                    '${s.y.toStringAsFixed(1)} 斤',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final WeightEntry entry;
  const _HistoryRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: C.border, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            entry.date,
            style: const TextStyle(
              color: C.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: [
              Text(
                (entry.weight * 2).toStringAsFixed(1),
                style: const TextStyle(
                  color: C.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                '斤',
                style: TextStyle(color: C.textMuted, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartPoint {
  final String label;
  final double value;
  _ChartPoint(this.label, this.value);
}
