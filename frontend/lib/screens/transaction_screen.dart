import 'package:flutter/material.dart';
import '../services/transaction_service.dart';
import '../services/category_service.dart';
import 'category_screen.dart';
import 'budget_screen.dart';

class TransactionScreen extends StatefulWidget {
  final String token;

  const TransactionScreen({super.key, required this.token});

  @override
  TransactionScreenState createState() => TransactionScreenState();
}

class TransactionScreenState extends State<TransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedType = 'expense';
  Category? _selectedCategory;
  late TransactionService _transactionService;
  late CategoryService _categoryService;
  List<Transaction> _transactions = [];
  List<Category> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _transactionService = TransactionService(widget.token);
    _categoryService = CategoryService(widget.token);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      print('Loading transactions and categories...'); // Для отладки
      final transactions = await _transactionService.getTransactions();
      final categories = await _categoryService.getCategories();
      print('Loaded ${transactions.length} transactions'); // Для отладки
      print('Loaded ${categories.length} categories'); // Для отладки
      setState(() {
        _transactions = transactions;
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e'); // Для отладки
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки данных: $e')),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        await _transactionService.createTransaction(
          double.parse(_amountController.text),
          _selectedCategory?.id,
          _selectedType,
          _descriptionController.text,
        );
        _amountController.clear();
        _descriptionController.clear();
        setState(() => _selectedCategory = null);
        await _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeCategories = _categories.where((c) => c.type == _selectedType).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Транзакции'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CategoryScreen(token: widget.token),
                ),
              ).then((_) => _loadData());
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BudgetScreen(token: widget.token),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _amountController,
                          decoration: const InputDecoration(labelText: 'Сумма'),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Пожалуйста, введите сумму';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Пожалуйста, введите корректное число';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(labelText: 'Описание'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Пожалуйста, введите описание';
                            }
                            return null;
                          },
                        ),
                        DropdownButtonFormField<String>(
                          value: _selectedType,
                          items: const [
                            DropdownMenuItem(
                              value: 'expense',
                              child: Text('Расход'),
                            ),
                            DropdownMenuItem(
                              value: 'income',
                              child: Text('Доход'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedType = value!;
                              _selectedCategory = null;
                            });
                          },
                        ),
                        if (_categories.isNotEmpty) // Показываем выбор категории только если они есть
                          DropdownButtonFormField<Category?>(
                            value: _selectedCategory,
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('Без категории'),
                              ),
                              ...typeCategories.map((category) {
                                return DropdownMenuItem(
                                  value: category,
                                  child: Text(category.name),
                                );
                              }),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedCategory = value;
                              });
                            },
                            decoration: const InputDecoration(labelText: 'Категория'),
                          ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _submitForm,
                          child: const Text('Добавить'),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: _transactions.isEmpty
                      ? const Center(
                          child: Text('Нет транзакций'),
                        )
                      : ListView.builder(
                          itemCount: _transactions.length,
                          itemBuilder: (context, index) {
                            final transaction = _transactions[index];
                            String categoryName = 'Без категории';
                            
                            if (transaction.categoryId != null && _categories.isNotEmpty) {
                              try {
                                final category = _categories.firstWhere(
                                  (c) => c.id == transaction.categoryId,
                                  orElse: () => Category(id: 0, name: 'Без категории', type: transaction.type),
                                );
                                categoryName = category.name;
                              } catch (e) {
                                print('Error finding category: $e');
                                categoryName = 'Без категории';
                              }
                            }

                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: ListTile(
                                leading: Icon(
                                  transaction.type == 'expense' ? Icons.remove : Icons.add,
                                  color: transaction.type == 'expense' ? Colors.red : Colors.green,
                                ),
                                title: Text(transaction.description),
                                subtitle: Text('$categoryName • ${_formatDate(transaction.date)}'),
                                trailing: Text(
                                  '${transaction.type == 'expense' ? '-' : '+'}${transaction.amount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: transaction.type == 'expense' ? Colors.red : Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
} 