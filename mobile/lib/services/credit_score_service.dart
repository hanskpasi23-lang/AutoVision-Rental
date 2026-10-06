import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'auth_service.dart';

class CreditHistoryItem {
  final int id;
  final double change;
  final String reason;
  final String date;

  CreditHistoryItem({
    required this.id,
    required this.change,
    required this.reason,
    required this.date,
  });

  factory CreditHistoryItem.fromJson(Map<String, dynamic> json) {
    return CreditHistoryItem(
      id: json['id'],
      change: (json['change'] as num).toDouble(),
      reason: json['reason'],
      date: json['created_at'].toString().split('T')[0],
    );
  }
}

class CreditScoreService {
  Future<List<CreditHistoryItem>> getCreditHistory() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'jwt_token');
    if (token == null) return [];

    final response = await http.get(
      Uri.parse('${AuthService.baseUrl}/users/me/credit-history'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => CreditHistoryItem.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load credit history');
    }
  }
}
