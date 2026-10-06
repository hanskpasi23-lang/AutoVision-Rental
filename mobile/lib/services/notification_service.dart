import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class NotificationService {
  final String baseUrl = AuthService.baseUrl;

  Future<List<Map<String, dynamic>>> getNotifications(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notifications/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    }
    return [];
  }

  Future<int> getUnreadCount(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notifications/unread-count'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['unread_count'] ?? 0;
      }
    } catch (e) {
      debugPrint('Error fetching unread count: $e');
    }
    return 0;
  }

  Future<bool> markAsRead(int notificationId, String token) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/notifications/$notificationId/read'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      return false;
    }
  }

  Future<bool> markAllAsRead(String token) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/notifications/read-all'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error marking all as read: $e');
      return false;
    }
  }
}
