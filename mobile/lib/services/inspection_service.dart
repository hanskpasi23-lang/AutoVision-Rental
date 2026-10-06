import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class InspectionService {
  final String baseUrl = AuthService.baseUrl;

  Future<Map<String, dynamic>> uploadInspectionImage(String filePath) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/inspections/analyze'));
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to upload image');
      }
    } catch (e) {
      debugPrint('Error uploading inspection: $e');
      rethrow;
    }
  }
}

