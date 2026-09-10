import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/price_forecast.dart';

class MandiPriceForecastChart extends StatelessWidget {
  final PriceForecastResponse forecastData;
  final bool showConfidenceBands;

  const MandiPriceForecastChart({
    Key? key,
    required this.forecastData,
    this.showConfidenceBands = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (forecastData.forecast.isEmpty) {
      return const Center(child: Text('No forecast points available.'));
    }

    final mainLineSpots = forecastData.forecast.map((p) => p.toFlSpot()).toList();
    final highCiSpots = forecastData.forecast.map((p) => p.toHighCiSpot()).toList();
    final floorSpots = forecastData.forecast.map((p) => p.toFloorSpot()).toList();

    return AspectRatio(
      aspectRatio: 1.70,
      child: Padding(
        padding: const EdgeInsets.only(right: 18, left: 12, top: 24, bottom: 12),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              horizontalInterval: 500,
              verticalInterval: 1,
              getDrawingHorizontalLine: (value) => const FlLine(
                color: Color(0x1AFFFFFF),
                strokeWidth: 1,
              ),
              getDrawingVerticalLine: (value) => const FlLine(
                color: Color(0x1AFFFFFF),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < forecastData.forecast.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          forecastData.forecast[index].dayName,
                          style: const TextStyle(
                            color: Color(0xFF8E9BB0),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
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
                  interval: 500,
                  reservedSize: 42,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      '₹${value.toInt()}',
                      style: const TextStyle(
                        color: Color(0xFF8E9BB0),
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.left,
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: const Color(0x1AFFFFFF)),
            ),
            lineBarsData: [
              // 1. Primary Predicted Price Line (Green Gradient)
              LineChartBarData(
                spots: mainLineSpots,
                isCurved: true,
                color: const Color(0xFF00E699),
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF00E699).withOpacity(0.3),
                      const Color(0xFF00E699).withOpacity(0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              // 2. High Confidence Bound (Dotted Cyan)
              if (showConfidenceBands)
                LineChartBarData(
                  spots: highCiSpots,
                  isCurved: true,
                  color: const Color(0xFF00D2FF).withOpacity(0.5),
                  barWidth: 1.5,
                  dashArray: [5, 5],
                  dotData: const FlDotData(show: false),
                ),
              // 3. Recommended Listing Floor (Amber)
              if (showConfidenceBands)
                LineChartBarData(
                  spots: floorSpots,
                  isCurved: true,
                  color: const Color(0xFFFFB703).withOpacity(0.7),
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (touchedSpot) => const Color(0xE60A0E17),
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((LineBarSpot touchedSpot) {
                    final isMain = touchedSpot.barIndex == 0;
                    return LineTooltipItem(
                      isMain
                          ? '₹${touchedSpot.y.toStringAsFixed(0)}'
                          : (touchedSpot.barIndex == 1 ? 'Max: ₹${touchedSpot.y.toStringAsFixed(0)}' : 'Floor: ₹${touchedSpot.y.toStringAsFixed(0)}'),
                      TextStyle(
                        color: isMain ? const Color(0xFF00E699) : Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }).toList();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
