import 'package:flutter/material.dart';
import '../services/export_service.dart';

class ExportScreen extends StatefulWidget {
  final String token;

  const ExportScreen({super.key, required this.token});

  @override
  ExportScreenState createState() => ExportScreenState();
}

class ExportScreenState extends State<ExportScreen> {
  late ExportService _exportService;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _exportService = ExportService(widget.token);
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
    }
  }

  Future<void> _exportTransactions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _exportService.exportTransactions(
        startDate: _startDate,
        endDate: _endDate,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Экспорт успешно завершен')),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Экспорт данных'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Выберите период для экспорта:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Начало'),
                    subtitle: Text(
                      '${_startDate.day}.${_startDate.month}.${_startDate.year}',
                    ),
                    onTap: _selectDateRange,
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: const Text('Конец'),
                    subtitle: Text(
                      '${_endDate.day}.${_endDate.month}.${_endDate.year}',
                    ),
                    onTap: _selectDateRange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Ошибка: $_error',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            Center(
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      onPressed: _exportTransactions,
                      icon: const Icon(Icons.download),
                      label: const Text('Экспортировать транзакции'),
                    ),
            ),
            const SizedBox(height: 32),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Информация об экспорте',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Экспорт создаст CSV файл с вашими транзакциями\n'
                      '• В файл будут включены все транзакции за выбранный период\n'
                      '• Файл будет содержать следующие данные:\n'
                      '  - Дата и время транзакции\n'
                      '  - Тип (доход/расход)\n'
                      '  - Категория\n'
                      '  - Сумма\n'
                      '  - Описание',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 