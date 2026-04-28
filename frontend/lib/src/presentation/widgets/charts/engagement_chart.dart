// lib/src/presentation/widgets/charts/engagement_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class EngagementChart extends StatelessWidget {
  const EngagementChart({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final dividerColor = theme.dividerColor;

    return SizedBox(
      height: 240,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LineChart(
          LineChartData(
            // Grid & Borders
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              horizontalInterval: 1,
              verticalInterval: 1,
              getDrawingHorizontalLine: (value) => FlLine(
                color: dividerColor.withValues(alpha: 0.3), // FIXED
                strokeWidth: 1,
              ),
              getDrawingVerticalLine: (value) => FlLine(
                color: dividerColor.withValues(alpha: 0.3), // FIXED
                strokeWidth: 1,
              ),
            ),

            // Titles (minimal & clean)
            titlesData: FlTitlesData(
              show: true,
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: 1,
                  getTitlesWidget: (value, meta) => Text(
                    'D${value.toInt() + 1}',
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  interval: 2,
                  getTitlesWidget: (value, meta) => Text(
                    '${value.toInt()}h',
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ),
            ),

            // Border
            borderData: FlBorderData(show: false),

            // Line data
            lineBarsData: [
              LineChartBarData(
                spots: const [
                  FlSpot(0, 3),
                  FlSpot(1, 4),
                  FlSpot(2, 3.5),
                  FlSpot(3, 5),
                  FlSpot(4, 6),
                  FlSpot(5, 8),
                  FlSpot(6, 7.5),
                ],
                isCurved: true,
                curveSmoothness: 0.35,
                color: primaryColor,
                barWidth: 4,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: primaryColor.withValues(alpha: 0.15), // FIXED
                ),
              ),
            ],

            // Min/Max values
            minX: 0,
            maxX: 6,
            minY: 0,
            maxY: 10,
          ),
        ),
      ),
    );
  }
}
