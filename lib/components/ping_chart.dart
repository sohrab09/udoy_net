import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class PingChart extends StatelessWidget {
  final List<FlSpot> gatewayPingData;
  final List<FlSpot> internetPingData;
  final String gatewayPingLabel;
  final String internetPingLabel;

  const PingChart({
    Key? key,
    required this.gatewayPingData,
    required this.internetPingData,
    required this.gatewayPingLabel,
    required this.internetPingLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ping Data Chart',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  gatewayPingLabel,
                  style: TextStyle(
                      color: Colors.blue, fontWeight: FontWeight.bold),
                ),
                Text(
                  internetPingLabel,
                  style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12), // Smaller font size for right side data
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              width: double.infinity, // Make the chart box wider
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    drawHorizontalLine: false,
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Color(0xFFAFAFAF)),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          return LineTooltipItem(
                            '${spot.y.toStringAsFixed(0)} ms',
                            const TextStyle(color: Colors.white),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: gatewayPingData,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(show: false),
                    ),
                    LineChartBarData(
                      spots: internetPingData,
                      isCurved: true,
                      color: Colors.red,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                  minX: gatewayPingData.isNotEmpty
                      ? gatewayPingData.first.x - 10
                      : 0,
                  maxX: gatewayPingData.isNotEmpty
                      ? gatewayPingData.last.x +
                          50 // Add more space on the right
                      : 0,
                  minY: 0,
                  maxY: (gatewayPingData + internetPingData)
                          .map((spot) => spot.y)
                          .reduce((a, b) => a > b ? a : b) +
                      10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
