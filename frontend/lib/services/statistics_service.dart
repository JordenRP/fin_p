import 'dart:convert';
import 'package:http/http.dart' as http;

class CategoryTotal {
  final int categoryId;
  final String categoryName;
  final double total;
  final String type;

  CategoryTotal({
    required this.categoryId,
    required this.categoryName,
    required this.total,
    required this.type,
  });

  factory CategoryTotal.fromJson(Map<String, dynamic> json) {
    return CategoryTotal(
      categoryId: json['category_id'] as int,
      categoryName: json['category_name'] as String,
      total: (json['total'] is int)
          ? (json['total'] as int).toDouble()
          : json['total'] as double,
      type: json['type'] as String,
    );
  }
}

class DailyTotal {
  final DateTime date;
  final double total;
  final String type;

  DailyTotal({
    required this.date,
    required this.total,
    required this.type,
  });

  factory DailyTotal.fromJson(Map<String, dynamic> json) {
    return DailyTotal(
      date: DateTime.parse(json['date'] as String),
      total: (json['total'] is int)
          ? (json['total'] as int).toDouble()
          : json['total'] as double,
      type: json['type'] as String,
    );
  }
}

class StatisticsResponse {
  final List<CategoryTotal> categoryTotals;
  final List<DailyTotal> dailyTotals;
  final List<DailyTotal> balanceHistory;

  StatisticsResponse({
    required this.categoryTotals,
    required this.dailyTotals,
    required this.balanceHistory,
  });

  factory StatisticsResponse.fromJson(Map<String, dynamic> json) {
    return StatisticsResponse(
      categoryTotals: (json['category_totals'] as List)
          .map((e) => CategoryTotal.fromJson(e as Map<String, dynamic>))
          .toList(),
      dailyTotals: (json['daily_totals'] as List?)
          ?.map((e) => DailyTotal.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      balanceHistory: (json['balance_history'] as List)
          .map((e) => DailyTotal.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class StatisticsService {
  static const baseUrl = 'http://localhost:8080/api';
  final String token;

  StatisticsService(this.token);

  Future<StatisticsResponse> getStatistics({
    required DateTime startDate,
    required DateTime endDate,
    String? type,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/statistics'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'start_date': startDate.toUtc().toIso8601String(),
          'end_date': endDate.toUtc().toIso8601String(),
          if (type != null) 'type': type,
        }),
      );

      if (response.statusCode == 200) {
        return StatisticsResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load statistics: ${response.body}');
      }
    } catch (e) {
      print('Error getting statistics: $e');
      rethrow;
    }
  }
} 