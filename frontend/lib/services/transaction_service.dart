import 'dart:convert';
import 'package:http/http.dart' as http;

class Transaction {
  final int id;
  final double amount;
  final int? categoryId;
  final String type;
  final String description;
  final DateTime date;

  Transaction({
    required this.id,
    required this.amount,
    this.categoryId,
    required this.type,
    required this.description,
    required this.date,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    print('Parsing transaction JSON: $json'); // Для отладки
    return Transaction(
      id: json['id'] as int,
      amount: (json['amount'] is int) 
          ? (json['amount'] as int).toDouble() 
          : json['amount'] as double,
      categoryId: json['category_id'] != null ? json['category_id'] as int : null,
      type: json['type'] as String,
      description: json['description'] as String,
      date: DateTime.parse(json['date'] as String),
    );
  }
}

class TransactionService {
  static const baseUrl = 'http://localhost:8080/api';
  final String token;

  TransactionService(this.token);

  Future<Transaction> createTransaction(
    double amount,
    int? categoryId,
    String type,
    String description,
  ) async {
    final Map<String, dynamic> body = {
      'amount': amount,
      'type': type,
      'description': description,
    };

    if (categoryId != null) {
      body['category_id'] = categoryId;
    }

    print('Creating transaction with body: $body'); // Для отладки

    final response = await http.post(
      Uri.parse('$baseUrl/transactions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    print('Create transaction response: ${response.statusCode} - ${response.body}'); // Для отладки

    if (response.statusCode == 200) {
      return Transaction.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create transaction: ${response.body}');
    }
  }

  Future<List<Transaction>> getTransactions() async {
    final response = await http.get(
      Uri.parse('$baseUrl/transactions'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    print('Get transactions response: ${response.statusCode} - ${response.body}'); // Для отладки

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Transaction.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load transactions: ${response.body}');
    }
  }
} 