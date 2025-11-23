import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../utils/app_theme.dart';
import '../services/language_service.dart';
import 'package:provider/provider.dart';

class ChartCard extends StatelessWidget {
  final String title;
  final String period;
  final List<Transaction> transactions;
  final bool isPieChart;

  const ChartCard({
    super.key,
    required this.title,
    required this.period,
    required this.transactions,
    this.isPieChart = false,
  });

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);
    
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 300,
            child: isPieChart ? _buildPieChart(languageService) : _buildLineChart(languageService),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(LanguageService languageService) {
    // Group transactions by date
    final Map<String, double> dailyTotals = {};
    
    for (var transaction in transactions) {
      if (transaction.status == TransactionStatus.success) {
        final date = transaction.date;
        dailyTotals[date] = (dailyTotals[date] ?? 0) + transaction.amount;
      }
    }

    if (dailyTotals.isEmpty) {
      return Center(
        child: Text(
          languageService.getText('لا توجد بيانات', 'No data available'),
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    final sortedDates = dailyTotals.keys.toList()..sort();
    if (sortedDates.isEmpty) {
      return Center(
        child: Text(
          languageService.getText('لا توجد بيانات', 'No data available'),
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }
    
    final maxAmount = dailyTotals.values.reduce((a, b) => a > b ? a : b);
    final minAmount = dailyTotals.values.reduce((a, b) => a < b ? a : b);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxAmount > 0 ? maxAmount / 5 : 100,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppTheme.borderColor,
              strokeWidth: 1,
            );
          },
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
              reservedSize: 30,
              interval: sortedDates.length > 7 ? (sortedDates.length / 7).ceilToDouble() : 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < sortedDates.length) {
                  final date = sortedDates[index];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      date.substring(5), // Show MM-DD
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              interval: maxAmount > 0 ? maxAmount / 5 : 200,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(0),
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: AppTheme.borderColor),
        ),
        minX: 0,
        maxX: (sortedDates.length - 1).toDouble() > 0 ? (sortedDates.length - 1).toDouble() : 1,
        minY: 0,
        maxY: maxAmount > 0 ? maxAmount * 1.2 : 1000,
        lineBarsData: [
          LineChartBarData(
            spots: sortedDates.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), dailyTotals[entry.value]!);
            }).toList(),
            isCurved: true,
            color: AppTheme.primaryColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: AppTheme.primaryColor,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.primaryColor.withOpacity(0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final dateIndex = barSpot.x.toInt();
                if (dateIndex >= 0 && dateIndex < sortedDates.length) {
                  return LineTooltipItem(
                    '${dailyTotals[sortedDates[dateIndex]]!.toStringAsFixed(2)} د.ل\n${sortedDates[dateIndex]}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }
                return null;
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPieChart(LanguageService languageService) {
    final successful = transactions
        .where((t) => t.status == TransactionStatus.success)
        .length;
    final rejected = transactions
        .where((t) => t.status == TransactionStatus.rejected)
        .length;
    final pending = transactions
        .where((t) => t.status == TransactionStatus.pending)
        .length;

    final total = successful + rejected + pending;

    if (total == 0) {
      return Center(
        child: Text(
          languageService.getText('لا توجد بيانات', 'No data available'),
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    return Column(
      children: [
        // Pie Chart
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 60,
                  sections: [
                    PieChartSectionData(
                      value: successful.toDouble(),
                      color: AppTheme.secondaryColor,
                      title: '',
                      radius: 80,
                    ),
                    PieChartSectionData(
                      value: rejected.toDouble(),
                      color: AppTheme.errorColor,
                      title: '',
                      radius: 80,
                    ),
                    PieChartSectionData(
                      value: pending.toDouble(),
                      color: AppTheme.warningColor,
                      title: '',
                      radius: 80,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Legend below chart
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem(
              languageService.getText('نجحت', 'Successful'),
              AppTheme.secondaryColor,
              successful,
              ((successful / total) * 100).toStringAsFixed(0),
            ),
            const SizedBox(width: 24),
            _buildLegendItem(
              languageService.getText('مرفوضة', 'Rejected'),
              AppTheme.errorColor,
              rejected,
              ((rejected / total) * 100).toStringAsFixed(0),
            ),
            const SizedBox(width: 24),
            _buildLegendItem(
              languageService.getText('معلقة', 'Pending'),
              AppTheme.warningColor,
              pending,
              ((pending / total) * 100).toStringAsFixed(0),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, int value, String percentage) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '$value (${percentage}%)',
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

