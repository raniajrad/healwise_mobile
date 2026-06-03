import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class HealthChart extends StatelessWidget {
  final String title;
  final List<FlSpot> data;
  final List<String> xAxisLabels;
  final Color lineColor;
  final String unit;
  final double minY;
  final double maxY;
  final bool isRisky;
  final String? riskMessage;
  final IconData? icon;

  const HealthChart({
    super.key,
    required this.title,
    required this.data,
    required this.xAxisLabels,
    required this.lineColor,
    required this.unit,
    required this.minY,
    required this.maxY,
    this.isRisky = false,
    this.riskMessage,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final chartColor = isRisky ? Colors.red : lineColor;
    final screenWidth = MediaQuery.of(context).size.width;

    final needsHorizontalScroll = xAxisLabels.length > 5 && screenWidth < 400;

    final adjustedMinY = data.isNotEmpty
        ? (data.map((e) => e.y).reduce((a, b) => a < b ? a : b) - 5).clamp(
            minY,
            maxY,
          )
        : minY;
    final adjustedMaxY = data.isNotEmpty
        ? (data.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 5).clamp(
            minY,
            maxY,
          )
        : maxY;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isRisky ? Colors.red.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isRisky
            ? Border.all(color: Colors.red, width: 2)
            : Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (icon != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: chartColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: chartColor, size: 20),
                      ),
                    if (icon != null) const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isRisky
                                  ? Colors.red.shade700
                                  : Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (data.isNotEmpty)
                            Text(
                              'Dernière valeur: ${data.last.y.toStringAsFixed(1)} $unit',
                              style: TextStyle(
                                fontSize: 11,
                                color: isRisky
                                    ? Colors.red.shade400
                                    : Colors.grey.shade500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: chartColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${data.length} ${data.length > 1 ? 'jours' : 'jour'}',
                  style: TextStyle(
                    fontSize: 11,
                    color: chartColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          if (isRisky && riskMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_rounded,
                    color: Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      riskMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          SizedBox(
            height: 220,
            child: data.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.show_chart,
                          color: Colors.grey.shade300,
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Aucune donnée',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                : needsHorizontalScroll
                ? SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: xAxisLabels.length * 65.0,
                      child: _buildLineChart(
                        chartColor,
                        adjustedMinY,
                        adjustedMaxY,
                        screenWidth,
                      ),
                    ),
                  )
                : _buildLineChart(
                    chartColor,
                    adjustedMinY,
                    adjustedMaxY,
                    screenWidth,
                  ),
          ),

          const SizedBox(height: 12),

          if (data.isNotEmpty && data.length >= 2)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatCard(
                  'Min',
                  '${_getMinValue().toStringAsFixed(1)} $unit',
                  chartColor,
                ),
                const SizedBox(width: 6),
                _buildStatCard(
                  'Moyenne',
                  '${_getAverageValue().toStringAsFixed(1)} $unit',
                  chartColor,
                ),
                const SizedBox(width: 6),
                _buildStatCard(
                  'Max',
                  '${_getMaxValue().toStringAsFixed(1)} $unit',
                  chartColor,
                ),
                const SizedBox(width: 6),
                _buildStatCard(
                  'Variation',
                  _calculateVariation(data),
                  chartColor,
                  showIcon: true,
                  isUp: _isVariationUp(data),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildLineChart(
    Color chartColor,
    double adjustedMinY,
    double adjustedMaxY,
    double screenWidth,
  ) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          verticalInterval: 1,
          horizontalInterval: (adjustedMaxY - adjustedMinY) / 4,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
            dashArray: [5, 5],
          ),
          getDrawingVerticalLine: (value) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
            dashArray: [5, 5],
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 1,
              getTitlesWidget: (value, titleMeta) {
                final index = value.toInt();
                if (index >= 0 && index < xAxisLabels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Transform.rotate(
                      angle: screenWidth < 380 ? -0.3 : 0,
                      child: Text(
                        xAxisLabels[index],
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: screenWidth < 380 ? 9 : 11,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
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
              interval: (adjustedMaxY - adjustedMinY) / 4,
              reservedSize: 35,
              getTitlesWidget: (value, titleMeta) => Text(
                value.toStringAsFixed(value % 1 == 0 ? 0 : 1),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: adjustedMinY,
        maxY: adjustedMaxY,
        lineBarsData: [
          LineChartBarData(
            spots: data,
            isCurved: true,
            color: chartColor,
            barWidth: 2.5,
            isStrokeCapRound: true,
            belowBarData: BarAreaData(
              show: true,
              color: chartColor.withOpacity(0.1),
            ),
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                final isLastPoint = index == data.length - 1;
                if (isLastPoint) {
                  return FlDotCirclePainter(
                    radius: 5,
                    color: Colors.white,
                    strokeWidth: 2.5,
                    strokeColor: chartColor,
                  );
                }
                return FlDotCirclePainter(
                  radius: 3.5,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: chartColor,
                );
              },
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) =>
                isRisky ? Colors.red : Colors.blueGrey.shade800,
            tooltipRoundedRadius: 8,
            tooltipMargin: 8,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                final value = touchedSpot.y;
                final displayValue = value.toStringAsFixed(
                  value % 1 == 0 ? 0 : 1,
                );
                final isLastPoint = touchedSpot.spotIndex == data.length - 1;
                return LineTooltipItem(
                  '$displayValue $unit${isLastPoint ? ' (Actuel)' : ''}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  double _getMinValue() =>
      data.isEmpty ? 0 : data.map((e) => e.y).reduce((a, b) => a < b ? a : b);
  double _getMaxValue() =>
      data.isEmpty ? 0 : data.map((e) => e.y).reduce((a, b) => a > b ? a : b);
  double _getAverageValue() => data.isEmpty
      ? 0
      : data.map((e) => e.y).reduce((a, b) => a + b) / data.length;

  Widget _buildStatCard(
    String label,
    String value,
    Color color, {
    bool showIcon = false,
    bool isUp = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (showIcon)
                  Icon(
                    isUp ? Icons.trending_up : Icons.trending_down,
                    size: 12,
                    color: isUp ? Colors.green : Colors.red,
                  ),
                if (showIcon) const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _calculateVariation(List<FlSpot> data) {
    if (data.length < 2) return '0%';
    final first = data.first.y;
    final last = data.last.y;
    if (first == 0) return '0%';
    final variation = ((last - first) / first * 100);
    final prefix = variation > 0 ? '+' : '';
    return '$prefix${variation.abs().toStringAsFixed(1)}%';
  }

  bool _isVariationUp(List<FlSpot> data) =>
      data.length >= 2 && data.last.y > data.first.y;
}
