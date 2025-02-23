import 'dart:convert';
import 'package:http/http.dart' as http;

class Budget {
  final int id;
  final int categoryId;
  final double amount;
  final double spent;
  final DateTime startDate;
  final DateTime endDate;

  Budget({
    required this.id,
    required this.categoryId,
    required this.amount,
    required this.spent,
    required this.startDate,
    required this.endDate,
  });

  double get remainingAmount => amount - spent;
  double get progress => (spent / amount * 100).clamp(0, 100);

  factory Budget.fromJson(Map<String, dynamic> json) {
    print('Parsing budget JSON in fromJson: $json'); // Для отладки
    try {
      return Budget(
        id: json['id'] as int,
        categoryId: json['category_id'] as int,
        amount: (json['amount'] is int)
            ? (json['amount'] as int).toDouble()
            : json['amount'] as double,
        spent: (json['spent'] is int)
            ? (json['spent'] as int).toDouble()
            : json['spent'] as double,
        startDate: DateTime.parse(json['start_date'] as String),
        endDate: DateTime.parse(json['end_date'] as String),
      );
    } catch (e, stackTrace) {
      print('Error parsing budget JSON: $e\n$stackTrace'); // Для отладки
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'amount': amount,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
    };
  }
}

class BudgetService {
  static const baseUrl = 'http://localhost:8080/api';
  final String token;

  BudgetService(this.token);

  Future<List<Budget>> getBudgets() async {
    print('Getting budgets...'); // Для отладки
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/budgets'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('Get budgets response: ${response.statusCode} - ${response.body}'); // Для отладки

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('Parsed budgets data: $data'); // Для отладки
        final budgets = data.map((json) {
          print('Parsing budget JSON: $json'); // Для отладки
          return Budget.fromJson(json);
        }).toList();
        print('Successfully parsed ${budgets.length} budgets'); // Для отладки
        return budgets;
      } else {
        throw Exception('Failed to load budgets: ${response.body}');
      }
    } catch (e, stackTrace) {
      print('Error in getBudgets: $e\n$stackTrace'); // Для отладки
      return []; // Возвращаем пустой список вместо исключения
    }
  }

  Future<Budget> createBudget(
    int categoryId,
    double amount,
    DateTime startDate,
    DateTime endDate,
  ) async {
    print('Creating budget: categoryId=$categoryId, amount=$amount, startDate=$startDate, endDate=$endDate'); // Для отладки
    try {
      final requestBody = {
        'category_id': categoryId,
        'amount': amount,
        'start_date': startDate.toUtc().toIso8601String(),
        'end_date': endDate.toUtc().toIso8601String(),
      };
      print('Request body: $requestBody'); // Для отладки

      final response = await http.post(
        Uri.parse('$baseUrl/budgets'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('Create budget response: ${response.statusCode} - ${response.body}'); // Для отладки

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        print('Parsing created budget JSON: $json'); // Для отладки
        return Budget.fromJson(json);
      } else {
        throw Exception('Failed to create budget: ${response.body}');
      }
    } catch (e, stackTrace) {
      print('Error in createBudget: $e\n$stackTrace'); // Для отладки
      rethrow;
    }
  }

  Future<void> deleteBudget(int budgetId) async {
    print('Deleting budget: $budgetId'); // Для отладки
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/budgets/$budgetId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('Delete budget response: ${response.statusCode} - ${response.body}'); // Для отладки

      if (response.statusCode != 200) {
        throw Exception('Failed to delete budget: ${response.body}');
      }
    } catch (e, stackTrace) {
      print('Error in deleteBudget: $e\n$stackTrace'); // Для отладки
      rethrow;
    }
  }
} 