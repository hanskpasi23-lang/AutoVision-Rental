import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/vehicle_model.dart';
import '../services/wishlist_service.dart';
import '../services/auth_service.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final WishlistService _wishlistService = WishlistService();
  late Future<List<Vehicle>> _wishlistFuture;

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  void _loadWishlist() {
    setState(() {
      _wishlistFuture = _wishlistService.getWishlist();
    });
  }

  String _getImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return '';
    if (imageUrl.startsWith('http')) return imageUrl;
    return '${AuthService.baseUrl}$imageUrl';
  }

  Future<void> _removeFromWishlist(int vehicleId) async {
    try {
      await _wishlistService.removeFromWishlist(vehicleId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from wishlist')),
      );
      _loadWishlist();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to remove from wishlist')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('My Wishlist'),
        centerTitle: true,
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Vehicle>>(
        future: _wishlistFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Your wishlist is empty',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          final vehicles = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async => _loadWishlist(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vehicles.length,
              itemBuilder: (context, index) {
                final vehicle = vehicles[index];
                return _buildWishlistCard(vehicle);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildWishlistCard(Vehicle vehicle) {
    final imageUrl = _getImageUrl(vehicle.imageUrl);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => context.push('/book/${vehicle.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [

            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 150,
                width: double.infinity,
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.directions_car, size: 50, color: Colors.grey),
                        ),
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.directions_car, size: 50, color: Colors.grey),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${vehicle.make} ${vehicle.model}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${vehicle.year} • \$${vehicle.dailyRate}/day',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.red),
                    onPressed: () => _removeFromWishlist(vehicle.id),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
