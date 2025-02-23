import 'dart:convert';
import 'package:http/http.dart' as http;

class Category {
  final int id;
  final String name;
  final String type;

  Category({
    required this.id,
    required this.name,
    required this.type,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    print('Parsing category JSON: $json'); // Для отладки
    final category = Category(
      id: json['id'] as int,
      name: json['name'] as String,
      type: (json['type'] as String).toLowerCase().trim(),
    );
    print('Created category: id=${category.id}, name=${category.name}, type=${category.type}'); // Для отладки
    return category;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
    };
  }
}

class CategoryService {
  static const baseUrl = 'http://localhost:8080/api';
  final String token;

  CategoryService(this.token);

  Future<List<Category>> getCategories() async {
    print('Getting categories...'); // Для отладки
    final response = await http.get(
      Uri.parse('$baseUrl/categories'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    print('Get categories response: ${response.statusCode} - ${response.body}'); // Для отладки

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      final categories = data.map((json) => Category.fromJson(json)).toList();
      print('Parsed ${categories.length} categories:'); // Для отладки
      for (var category in categories) {
        print('Category: id=${category.id}, name=${category.name}, type=${category.type}');
      }
      return categories;
    } else {
      throw Exception('Failed to load categories: ${response.body}');
    }
  }

  Future<Category> createCategory(String name, String type) async {
    final response = await http.post(
      Uri.parse('$baseUrl/categories'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'type': type,
      }),
    );

    print('Create category response: ${response.statusCode} - ${response.body}'); // Для отладки

    if (response.statusCode == 200) {
      return Category.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create category: ${response.body}');
    }
  }
} 