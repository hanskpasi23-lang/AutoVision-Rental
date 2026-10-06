import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../models/vehicle_model.dart';

class WishlistService {
  Future<List<Vehicle>> getWishlist() async {
    final token = await AuthService().getToken();
    if (token == null) return [];

    final response = await http.get(
      Uri.parse('${AuthService.baseUrl}/wishlist/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Vehicle.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load wishlist');
    }
  }

  Future<void> addToWishlist(int vehicleId) async {
    final token = await AuthService().getToken();
    if (token == null) return;

    final response = await http.post(
      Uri.parse('${AuthService.baseUrl}/wishlist/$vehicleId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to add to wishlist');
    }
  }

  Future<void> removeFromWishlist(int vehicleId) async {
    final token = await AuthService().getToken();
    if (token == null) return;

    final response = await http.delete(
      Uri.parse('${AuthService.baseUrl}/wishlist/$vehicleId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to remove from wishlist');
    }
  }
}
