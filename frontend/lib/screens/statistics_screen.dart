import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/statistics_service.dart';

class StatisticsScreen extends StatefulWidget {
  final String token;

  const StatisticsScreen({super.key, required this.token});

  @override
  StatisticsScreenState createState() => StatisticsScreenState();
}

class StatisticsScreenState extends State<StatisticsScreen> {
  late StatisticsService _statisticsService;
  StatisticsResponse? _statistics;
  bool _isLoading = true;
  String? _error;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _selectedType = 'expense';

  @override
  void initState() {
    super.initState();
    _statisticsService = StatisticsService(widget.token);
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final statistics = await _statisticsService.getStatistics(
        startDate: _startDate,
        endDate: _endDate,
        type: _selectedType,
      );

      setState(() {
        _statistics = statistics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _startDate,
        end: _endDate,
      ),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadStatistics();
    }
  }

  Widget _buildCategoryPieChart() {
    if (_statistics == null || _statistics!.categoryTotals.isEmpty) {
      return const Center(child: Text('Нет данных для отображения'));
    }

    final categoryTotals = _statistics!.categoryTotals
        .where((ct) => ct.type == _selectedType)
        .toList();

    if (categoryTotals.isEmpty) {
      return const Center(child: Text('Нет данных для выбранного типа'));
    }

    final total = categoryTotals.fold(0.0, (sum, ct) => sum + ct.total);

    return AspectRatio(
      aspectRatio: 1.5,
      child: PieChart(
        PieChartData(
          sections: categoryTotals.map((ct) {
            final percentage = (ct.total / total * 100).roundToDouble();
            return PieChartSectionData(
              color: Colors.primaries[categoryTotals.indexOf(ct) % Colors.primaries.length],
              value: ct.total,
              title: '${ct.categoryName}\n${percentage.toStringAsFixed(1)}%',
              radius: 100,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }).toList(),
          sectionsSpace: 2,
          centerSpaceRadius: 0,
        ),
      ),
    );
  }

  Widget _buildBalanceLineChart() {
    if (_statistics == null || _statistics!.balanceHistory.isEmpty) {
      return const Center(child: Text('Нет данных для отображения'));
    }

    final history = _statistics!.balanceHistory;
    final minY = history.map((dt) => dt.total).reduce((a, b) => a < b ? a : b);
    final maxY = history.map((dt) => dt.total).reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY) * 0.1;

    return AspectRatio(
      aspectRatio: 1.5,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(value.toStringAsFixed(0));
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < history.length) {
                    final date = history[value.toInt()].date;
                    return Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Text('${date.day}.${date.month}'),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: true),
          minX: 0,
          maxX: history.length.toDouble() - 1,
          minY: minY - padding,
          maxY: maxY + padding,
          lineBarsData: [
            LineChartBarData(
              spots: history.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value.total);
              }).toList(),
              isCurved: true,
              color: Colors.blue,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.withOpacity(0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Статистика'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDateRange,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatistics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Ошибка: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadStatistics,
                        child: const Text('Повторить попытку'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Период: ${_startDate.day}.${_startDate.month}.${_startDate.year} - '
                            '${_endDate.day}.${_endDate.month}.${_endDate.year}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(
                                value: 'expense',
                                label: Text('Расходы'),
                              ),
                              ButtonSegment(
                                value: 'income',
                                label: Text('Доходы'),
                              ),
                            ],
                            selected: {_selectedType},
                            onSelectionChanged: (Set<String> newSelection) {
                              setState(() {
                                _selectedType = newSelection.first;
                              });
                              _loadStatistics();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Распределение по категориям',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      _buildCategoryPieChart(),
                      const SizedBox(height: 32),
                      Text(
                        'История баланса',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      _buildBalanceLineChart(),
                    ],
                  ),
                ),
    );
  }
} 