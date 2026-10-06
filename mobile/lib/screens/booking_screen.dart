import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/vehicle_model.dart';
import '../services/vehicle_service.dart';
import '../services/rental_service.dart';
import '../services/auth_service.dart';

class BookingScreen extends StatefulWidget {
  final int vehicleId;

  const BookingScreen({super.key, required this.vehicleId});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final VehicleService _vehicleService = VehicleService();
  final RentalService _rentalService = RentalService();
  Vehicle? _vehicle;
  DateTimeRange? _selectedDateRange;
  bool _isLoading = true;
  bool _isBooking = false;

  @override
  void initState() {
    super.initState();
    _loadVehicle();
  }

  Future<void> _loadVehicle() async {
    final vehicle = await _vehicleService.getVehicleById(widget.vehicleId);
    setState(() {
      _vehicle = vehicle;
      _isLoading = false;
    });
  }

  Future<void> _selectDateRange() async {
    final DateTime now = DateTime.now();
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  Future<void> _confirmBooking() async {
    if (_selectedDateRange == null || _vehicle == null) return;

    setState(() => _isBooking = true);

    final token = await AuthService().getToken();
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in again')),
        );
      }
      setState(() => _isBooking = false);
      return;
    }

    final days = _selectedDateRange!.duration.inDays + 1;
    final totalPrice = days * _vehicle!.dailyRate;

    final result = await _rentalService.createBooking(
      vehicleId: widget.vehicleId,
      token: token,
      startDate: _selectedDateRange!.start,
      endDate: _selectedDateRange!.end,
      totalPrice: totalPrice,
    );

    setState(() => _isBooking = false);

    if (result != null && mounted) {
      final bookingId = result['id'];
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking created! Proceeding to vehicle inspection...'),
            backgroundColor: Colors.green,
          ),
        );

        context.push('/rental-inspection/$bookingId/pre');
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create booking. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return '';
    if (imageUrl.startsWith('http')) return imageUrl;
    return '${AuthService.baseUrl}$imageUrl';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_vehicle == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Vehicle not found')),
      );
    }

    final days = (_selectedDateRange?.duration.inDays ?? 0) + 1;
    final totalCost = days * _vehicle!.dailyRate;
    final imageUrl = _getImageUrl(_vehicle!.imageUrl);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        title: const Text('Book Vehicle'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue[100]!, Colors.blue[50]!],
                        ),
                      ),
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.directions_car,
                                size: 80,
                                color: Colors.blue[300],
                              ),
                            )
                          : Icon(
                              Icons.directions_car,
                              size: 80,
                              color: Colors.blue[300],
                            ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_vehicle!.make} ${_vehicle!.model}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_vehicle!.year}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              '\$${_vehicle!.dailyRate.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                            Text(
                              ' / day',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Rental Dates',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _selectDateRange,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: Colors.blue[700]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedDateRange == null
                                    ? 'Tap to select dates'
                                    : '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month}/${_selectedDateRange!.start.year} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}/${_selectedDateRange!.end.year}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _selectedDateRange == null
                                      ? Colors.grey
                                      : Colors.black87,
                                ),
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_selectedDateRange != null) ...[
              const SizedBox(height: 16),

              Card(
                elevation: 2,
                color: Colors.green[50],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Rental Duration'),
                          Text(
                            '$days days',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Daily Rate'),
                          Text('\$${_vehicle!.dailyRate.toStringAsFixed(2)}'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Cost',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '\$${totalCost.toStringAsFixed(2)}',
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

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'After booking, you\'ll need to complete a vehicle inspection by taking 4 photos.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Consumer<AuthService>(
                builder: (context, auth, _) {
                  final isVerified = auth.currentUser?.verificationStatus == 'verified';

                  if (!isVerified) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Verification Required',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'You need to verify your account before you can book a vehicle.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () => context.push('/verification'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Verify Account Now'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            'Confirm & Proceed',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    );
                  }

                  return ElevatedButton(
                  onPressed: _isBooking ? null : _confirmBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isBooking
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Confirm & Proceed to Inspection',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                );
                }
              ),
            ],
          ],
        ),
      ),
    );
  }
}

