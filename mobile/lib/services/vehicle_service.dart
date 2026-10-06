import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/vehicle_model.dart';
import 'auth_service.dart';

class VehicleService {
  final String baseUrl = AuthService.baseUrl;

  Future<List<Vehicle>> getAvailableVehicles() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/vehicles/'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Vehicle.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load vehicles');
      }
    } catch (e) {
      debugPrint('Error fetching vehicles: $e');
      return [];
    }
  }

  Future<Vehicle?> getVehicleById(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/vehicles/$id'));

      if (response.statusCode == 200) {
        return Vehicle.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('Error fetching vehicle details: $e');
    }
    return null;
  }
}

