import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'auth_service.dart';

class RentalService {
  final String baseUrl = AuthService.baseUrl;

  Future<Map<String, dynamic>?> uploadPreInspection({
    required int bookingId,
    required String token,
    required File frontImage,
    required File backImage,
    required File leftImage,
    required File rightImage,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/rental/pre-inspection/$bookingId');
      final request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $token';

      request.files.add(await http.MultipartFile.fromPath(
        'front', frontImage.path,
        contentType: MediaType('image', 'jpeg'),
      ));
      request.files.add(await http.MultipartFile.fromPath(
        'back', backImage.path,
        contentType: MediaType('image', 'jpeg'),
      ));
      request.files.add(await http.MultipartFile.fromPath(
        'left', leftImage.path,
        contentType: MediaType('image', 'jpeg'),
      ));
      request.files.add(await http.MultipartFile.fromPath(
        'right', rightImage.path,
        contentType: MediaType('image', 'jpeg'),
      ));

      debugPrint('Sending pre-inspection to: $uri');
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 120),
      );
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('Pre-inspection response: ${response.statusCode}');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Pre-inspection failed [${response.statusCode}]: ${response.body}');
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map && errorBody.containsKey('detail')) {
            return {'error': true, 'detail': errorBody['detail']};
          }
        } catch (_) {}
        return null;
      }
    } catch (e) {
      debugPrint('Error uploading pre-inspection: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> startRental({
    required int bookingId,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/rental/start/$bookingId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Start rental failed: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error starting rental: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> endRental({
    required int bookingId,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/rental/end/$bookingId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint('End rental failed: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error ending rental: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> uploadPostInspection({
    required int bookingId,
    required String token,
    required File frontImage,
    required File backImage,
    required File leftImage,
    required File rightImage,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/rental/post-inspection/$bookingId');
      final request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $token';

      request.files.add(await http.MultipartFile.fromPath(
        'front', frontImage.path,
        contentType: MediaType('image', 'jpeg'),
      ));
      request.files.add(await http.MultipartFile.fromPath(
        'back', backImage.path,
        contentType: MediaType('image', 'jpeg'),
      ));
      request.files.add(await http.MultipartFile.fromPath(
        'left', leftImage.path,
        contentType: MediaType('image', 'jpeg'),
      ));
      request.files.add(await http.MultipartFile.fromPath(
        'right', rightImage.path,
        contentType: MediaType('image', 'jpeg'),
      ));

      debugPrint('Sending post-inspection to: $uri');
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 120),
      );
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('Post-inspection response: ${response.statusCode}');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Post-inspection failed [${response.statusCode}]: ${response.body}');
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map && errorBody.containsKey('detail')) {
            return {'error': true, 'detail': errorBody['detail']};
          }
        } catch (_) {}
        return null;
      }
    } catch (e) {
      debugPrint('Error uploading post-inspection: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getActiveRental(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/rental/active'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error getting active rental: $e');
    }
    return null;
  }

  Future<bool> cancelBooking({
    required int bookingId,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/rental/cancel/$bookingId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error cancelling booking: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> createBooking({
    required int vehicleId,
    required String token,
    required DateTime startDate,
    required DateTime endDate,
    required double totalPrice,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/bookings/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'vehicle_id': vehicleId,
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
          'total_price': totalPrice,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Create booking failed: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error creating booking: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getDashboardStats(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/user-stats'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error getting dashboard stats: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getInspectionResults(int bookingId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/rental/results/$bookingId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Get inspection results failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error getting inspection results: $e');
    }
    return null;
  }
}
