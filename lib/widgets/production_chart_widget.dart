import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';


class ProductionChartWidget extends StatefulWidget {
  final Map<String, dynamic> dataByPeriod;

  const ProductionChartWidget({super.key, required this.dataByPeriod});

  @override
  State<ProductionChartWidget> createState() => _ProductionChartWidgetState();
}

class _ProductionChartWidgetState extends State<ProductionChartWidget> {
  String selectedPeriod = 'Days';

  final List<int> selectedHours = [6, 9, 12, 15, 18, 20];

  List<String> _xLabels(String period) {
    if (period == 'Days') {
      return ['06:00', '09:00', '12:00', '15:00', '18:00', '20:00'];
    } else if (period == 'Weeks') {
      return ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labels = _xLabels(selectedPeriod);

    List<double> data;

    if (selectedPeriod == 'Days') {
      final hourlyMap = widget.dataByPeriod['Days'] as Map<int, double>? ?? {};
      data = selectedHours.map((h) => hourlyMap[h] ?? 0.0).toList();
    } else {
      data = (widget.dataByPeriod[selectedPeriod] as List<double>? ?? []);
    }

    // ✅ Y ekseni ayrı ayrı hesaplanıyor
    double minY, maxY, interval;

    if (selectedPeriod == 'Days') {
      maxY = data.isNotEmpty ? data.reduce((a, b) => a > b ? a : b) + 1 : 10.0;
      minY = 0.0;
      interval = 1.0;
    } else {
      final minValue =
          data.isNotEmpty ? data.reduce((a, b) => a < b ? a : b) : 0.0;
      final maxValue =
          data.isNotEmpty ? data.reduce((a, b) => a > b ? a : b) : 10.0;
      minY = minValue.floorToDouble();
      maxY = maxValue.ceilToDouble();
      final range = maxY - minY;
      interval = (range / 5).clamp(1.0, double.infinity);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: ['Days', 'Weeks'].map((period) {
            final isSelected = selectedPeriod == period;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              child: ElevatedButton(
                onPressed: () => setState(() => selectedPeriod = period),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceVariant,
                  foregroundColor: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                child: Text(period,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 260,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: (data.length - 1).toDouble(),
              minY: minY,
              maxY: maxY,
              gridData: FlGridData(show: true, drawVerticalLine: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < labels.length) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          space: 6,
                          child: Text(
                            labels[index],
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.textTheme.bodyMedium?.color ??
                                  Colors.black,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: interval,
                    getTitlesWidget: (value, meta) => SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        value.toStringAsFixed(0),
                        style: TextStyle(
                          fontSize: 10,
                          color:
                              theme.textTheme.bodyMedium?.color ?? Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: data
                      .asMap()
                      .entries
                      .map((e) => FlSpot(e.key.toDouble(), e.value))
                      .toList(),
                  isCurved: true,
                  color: theme.colorScheme.primary,
                  barWidth: 3,
                  dotData: FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: theme.colorScheme.primary.withOpacity(0.25),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
