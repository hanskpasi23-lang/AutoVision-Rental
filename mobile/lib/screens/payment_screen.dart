import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../services/rental_service.dart';

class PaymentScreen extends StatefulWidget {
  final int bookingId;

  const PaymentScreen({super.key, required this.bookingId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final RentalService _rentalService = RentalService();
  bool _isLoading = true;
  bool _isProcessing = false;
  Map<String, dynamic>? _booking;
  String? _error;

  String _selectedPaymentMethod = 'credit_card';

  @override
  void initState() {
    super.initState();
    _loadBookingDetails();
  }

  Future<void> _loadBookingDetails() async {
    final token = await AuthService().getToken();
    if (token == null) {
      setState(() {
        _error = 'Please log in again';
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/bookings/${widget.bookingId}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _booking = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load booking details';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Connection error. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);

    await Future.delayed(const Duration(seconds: 2));

    final token = await AuthService().getToken();
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in again')),
        );
      }
      setState(() => _isProcessing = false);
      return;
    }

    final result = await _rentalService.startRental(
      bookingId: widget.bookingId,
      token: token,
    );

    setState(() => _isProcessing = false);

    if (result != null && mounted) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment successful! Rental started.'),
          backgroundColor: Colors.green,
        ),
      );
      context.go('/active-rental/${widget.bookingId}');
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment processed but failed to start rental. Contact support.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Payment'),
          backgroundColor: Colors.green[700],
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _booking == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Payment'),
          backgroundColor: Colors.green[700],
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                _error ?? 'Booking not found',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final totalPrice = (_booking!['total_price'] as num?)?.toDouble() ?? 0.0;
    final vehicle = _booking!['vehicle'] as Map<String, dynamic>?;
    final vehicleName = vehicle != null
        ? '${vehicle['make']} ${vehicle['model']}'
        : 'Vehicle';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Order Summary',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Vehicle', style: TextStyle(color: Colors.grey[600])),
                        Text(vehicleName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Booking ID', style: TextStyle(color: Colors.grey[600])),
                        Text('#${widget.bookingId}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total to Pay',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '\$${totalPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Select Payment Method',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _buildPaymentMethodOption(
              'credit_card',
              'Credit / Debit Card',
              Icons.credit_card,
            ),
            const SizedBox(height: 8),
            _buildPaymentMethodOption(
              'paypal',
              'PayPal',
              Icons.paypal,
            ),
            const SizedBox(height: 8),
            _buildPaymentMethodOption(
              'apple_pay',
              'Apple Pay / Google Pay',
              Icons.phone_android,
            ),

            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _isProcessing ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      'Pay \$${totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    'Payments are secure and encrypted',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodOption(String id, String title, IconData icon) {
    final isSelected = _selectedPaymentMethod == id;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = id;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.green : Colors.grey[600]),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.green),
          ],
        ),
      ),
    );
  }
}
