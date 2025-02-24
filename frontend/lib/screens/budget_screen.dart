import 'package:flutter/material.dart';
import '../services/budget_service.dart';
import '../services/category_service.dart';

class BudgetScreen extends StatefulWidget {
  final String token;

  const BudgetScreen({super.key, required this.token});

  @override
  BudgetScreenState createState() => BudgetScreenState();
}

class BudgetScreenState extends State<BudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  late BudgetService _budgetService;
  late CategoryService _categoryService;
  List<Budget> _budgets = [];
  List<Category> _categories = [];
  List<Category> _expenseCategories = [];
  Category? _selectedCategory;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _budgetService = BudgetService(widget.token);
    _categoryService = CategoryService(widget.token);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _selectedCategory = null;
    });

    try {
      final categories = await _categoryService.getCategories();
      print('Loaded ${categories.length} categories');
      
      for (var category in categories) {
        print('Category details: id=${category.id}, name=${category.name}, type=${category.type}');
      }
      
      final expenseCategories = categories.where((c) => c.type.toLowerCase().trim() == 'expense').toList();
      print('Found ${expenseCategories.length} expense categories');
      
      final budgets = await _budgetService.getBudgets();
      print('Loaded ${budgets.length} budgets');

      if (mounted) {
        setState(() {
          _categories = categories;
          _expenseCategories = expenseCategories;
          _budgets = budgets;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('Error loading data: $e\n$stackTrace');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          _categories = [];
          _expenseCategories = [];
          _budgets = [];
        });
      }
    }
  }

  Future<void> _selectDate(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 1));
          }
        } else {
          _endDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _startDate = _endDate.subtract(const Duration(days: 1));
          }
        }
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() && _selectedCategory != null) {
      try {
        await _budgetService.createBudget(
          _selectedCategory!.id,
          double.parse(_amountController.text),
          _startDate,
          _endDate,
        );
        _amountController.clear();
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

  Future<void> _deleteBudget(Budget budget) async {
    try {
      await _budgetService.deleteBudget(budget.id);
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при удалении бюджета: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseCategories = _categories
        .where((c) => c.type.toLowerCase().trim() == 'expense')
        .toList();
    
    print('Building screen:');
    print('Total categories: ${_categories.length}');
    print('Expense categories: ${expenseCategories.length}');
    for (var category in expenseCategories) {
      print('Expense category: id=${category.id}, name=${category.name}, type=${category.type}');
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Бюджеты'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
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
                        onPressed: _loadData,
                        child: const Text('Повторить попытку'),
                      ),
                    ],
                  ),
                )
              : expenseCategories.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Сначала создайте хотя бы одну категорию расходов'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('Вернуться к транзакциям'),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                DropdownButtonFormField<Category>(
                                  value: _selectedCategory,
                                  items: expenseCategories.map((category) {
                                    return DropdownMenuItem(
                                      value: category,
                                      child: Text(category.name),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedCategory = value;
                                    });
                                  },
                                  decoration: const InputDecoration(labelText: 'Категория'),
                                  validator: (value) {
                                    if (value == null) {
                                      return 'Пожалуйста, выберите категорию';
                                    }
                                    return null;
                                  },
                                ),
                                TextFormField(
                                  controller: _amountController,
                                  decoration: const InputDecoration(labelText: 'Сумма бюджета'),
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
                                Row(
                                  children: [
                                    Expanded(
                                      child: ListTile(
                                        title: const Text('Начало'),
                                        subtitle: Text('${_startDate.day}.${_startDate.month}.${_startDate.year}'),
                                        onTap: () => _selectDate(true),
                                      ),
                                    ),
                                    Expanded(
                                      child: ListTile(
                                        title: const Text('Конец'),
                                        subtitle: Text('${_endDate.day}.${_endDate.month}.${_endDate.year}'),
                                        onTap: () => _selectDate(false),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _submitForm,
                                  child: const Text('Добавить бюджет'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: _budgets.isEmpty
                              ? const Center(
                                  child: Text('Нет бюджетов'),
                                )
                              : ListView.builder(
                                  itemCount: _budgets.length,
                                  itemBuilder: (context, index) {
                                    final budget = _budgets[index];
                                    final category = _categories.firstWhere(
                                      (c) => c.id == budget.categoryId,
                                      orElse: () => Category(id: 0, name: 'Категория удалена', type: 'expense'),
                                    );

                                    return Card(
                                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      child: Column(
                                        children: [
                                          ListTile(
                                            title: Text(category.name),
                                            subtitle: Text(
                                              'Период: ${budget.startDate.day}.${budget.startDate.month}.${budget.startDate.year} - '
                                              '${budget.endDate.day}.${budget.endDate.month}.${budget.endDate.year}',
                                            ),
                                            trailing: IconButton(
                                              icon: const Icon(Icons.delete),
                                              onPressed: () => _deleteBudget(budget),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Column(
                                              children: [
                                                LinearProgressIndicator(
                                                  value: budget.spent / budget.amount,
                                                  backgroundColor: Colors.grey[200],
                                                  valueColor: AlwaysStoppedAnimation<Color>(
                                                    budget.progress > 90 ? Colors.red : Colors.blue,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      'Потрачено: ${budget.spent.toStringAsFixed(2)}',
                                                      style: TextStyle(
                                                        color: budget.progress > 90 ? Colors.red : null,
                                                      ),
                                                    ),
                                                    Text(
                                                      'Осталось: ${budget.remainingAmount.toStringAsFixed(2)}',
                                                      style: TextStyle(
                                                        color: budget.remainingAmount < 0 ? Colors.red : Colors.green,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
} 