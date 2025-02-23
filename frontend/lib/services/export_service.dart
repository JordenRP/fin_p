import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:universal_html/html.dart' as html;

class ExportService {
  static const baseUrl = 'http://localhost:8080/api';
  final String token;

  ExportService(this.token);

  Future<void> exportTransactions({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/export/transactions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'start_date': startDate.toUtc().toIso8601String(),
          'end_date': endDate.toUtc().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        final blob = html.Blob([response.body]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'transactions.csv')
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        throw Exception('Failed to export transactions: ${response.body}');
      }
    } catch (e) {
      print('Error exporting transactions: $e');
      rethrow;
    }
  }
} 