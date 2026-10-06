import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../services/rental_service.dart';
import '../services/auth_service.dart';

class ActiveRentalScreen extends StatefulWidget {
  final int bookingId;

  const ActiveRentalScreen({super.key, required this.bookingId});

  @override
  State<ActiveRentalScreen> createState() => _ActiveRentalScreenState();
}

class _ActiveRentalScreenState extends State<ActiveRentalScreen> {
  final RentalService _rentalService = RentalService();
  Map<String, dynamic>? _rentalData;
  bool _isLoading = true;
  bool _isEnding = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadRentalData();

    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadRentalData() async {
    final token = await AuthService().getToken();
    if (token == null) return;

    final result = await _rentalService.getActiveRental(token);
    if (mounted) {
      setState(() {
        _rentalData = result?['active_rental'];
        _isLoading = false;
      });
    }
  }

  String _formatDuration(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;

    if (days > 0) {
      return '$days days, $hours hrs';
    } else if (hours > 0) {
      return '$hours hrs, $minutes min';
    } else {
      return '$minutes minutes';
    }
  }

  Duration? get _timeRemaining {
    if (_rentalData == null) return null;
    final endDate = DateTime.tryParse(_rentalData!['end_date'] ?? '');
    if (endDate == null) return null;
    return endDate.difference(DateTime.now());
  }

  Duration? get _timeElapsed {
    if (_rentalData == null) return null;
    final startDate = DateTime.tryParse(_rentalData!['start_date'] ?? '');
    if (startDate == null) return null;
    return DateTime.now().difference(startDate);
  }

  Future<void> _endRental() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Rental?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to end this rental?'),
            if (_timeRemaining != null && _timeRemaining!.inHours > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.green[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You\'re returning early! A refund will be calculated for unused days.',
                        style: TextStyle(color: Colors.green[800], fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('End Rental'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isEnding = true);

    try {
      final token = await AuthService().getToken();
      if (token == null) {
        setState(() => _isEnding = false);
        return;
      }

      final bookingId = _rentalData != null ? _rentalData!['booking_id'] : widget.bookingId;

      if (bookingId == null || bookingId == 0) {
        setState(() => _isEnding = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Invalid booking ID.')),
          );
        }
        return;
      }

      final result = await _rentalService.endRental(
        bookingId: bookingId,
        token: token,
      );

      if (result != null && mounted) {

        context.push('/rental-inspection/$bookingId/post');

        setState(() => _isEnding = false);
      } else {
        setState(() => _isEnding = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to end rental. Please try again.')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error in _endRental: $e');
      setState(() => _isEnding = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_rentalData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Active Rental')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.car_rental, size: 80, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text('No active rental found', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      );
    }

    final vehicle = _rentalData!['vehicle'];
    final remaining = _timeRemaining;
    final elapsed = _timeElapsed;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        title: const Text('Active Rental'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue[100]!, Colors.blue[50]!],
                        ),
                      ),
                      child: vehicle['image_url'] != null
                          ? Image.network(
                              '${AuthService.baseUrl}${vehicle['image_url']}',
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
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${vehicle['make']} ${vehicle['model']}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'ACTIVE',
                                style: TextStyle(
                                  color: Colors.green[800],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${vehicle['year']}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(Icons.timer, color: Colors.blue[700], size: 32),
                          const SizedBox(height: 8),
                          const Text('Time Elapsed', style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(
                            elapsed != null ? _formatDuration(elapsed) : '--',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    color: remaining != null && remaining.isNegative ? Colors.red[50] : null,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(
                            Icons.hourglass_bottom,
                            color: remaining != null && remaining.isNegative
                                ? Colors.red
                                : Colors.orange[700],
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            remaining != null && remaining.isNegative ? 'Overdue' : 'Time Left',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            remaining != null
                                ? _formatDuration(remaining.isNegative ? -remaining : remaining)
                                : '--',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: remaining != null && remaining.isNegative
                                  ? Colors.red
                                  : Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rental Details',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Divider(height: 24),
                    _buildDetailRow(
                      'Start Date',
                      _formatDate(_rentalData!['start_date']),
                    ),
                    _buildDetailRow(
                      'End Date',
                      _formatDate(_rentalData!['end_date']),
                    ),
                    _buildDetailRow(
                      'Total Paid',
                      '\$${(_rentalData!['paid_amount'] ?? 0).toStringAsFixed(2)}',
                      valueColor: Colors.green,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isEnding ? null : _endRental,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isEnding
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.stop_circle_outlined, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'End Rental',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Contact support: +1 (555) 123-4567')),
                );
              },
              icon: const Icon(Icons.support_agent),
              label: const Text('Need Help?'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '--';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '--';
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
