import 'package:flutter/material.dart';
import '../services/category_service.dart';

class CategoryScreen extends StatefulWidget {
  final String token;

  const CategoryScreen({super.key, required this.token});

  @override
  CategoryScreenState createState() => CategoryScreenState();
}

class CategoryScreenState extends State<CategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedType = 'expense';
  late CategoryService _categoryService;
  List<Category> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _categoryService = CategoryService(widget.token);
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final categories = await _categoryService.getCategories();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки категорий: $e')),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        await _categoryService.createCategory(
          _nameController.text,
          _selectedType,
        );
        _nameController.clear();
        await _loadCategories();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Категории'),
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
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Название категории'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Пожалуйста, введите название категории';
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
                            });
                          },
                          decoration: const InputDecoration(labelText: 'Тип'),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _submitForm,
                          child: const Text('Добавить категорию'),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      return ListTile(
                        leading: Icon(
                          category.type == 'expense' ? Icons.remove : Icons.add,
                          color: category.type == 'expense' ? Colors.red : Colors.green,
                        ),
                        title: Text(category.name),
                        subtitle: Text(category.type == 'expense' ? 'Расход' : 'Доход'),
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
    _nameController.dispose();
    super.dispose();
  }
} 