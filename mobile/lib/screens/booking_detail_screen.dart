import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../services/rental_service.dart';
import 'package:http/http.dart' as http;

class BookingDetailScreen extends StatefulWidget {
  final int bookingId;

  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final RentalService _rentalService = RentalService();
  Map<String, dynamic>? _booking;
  bool _isLoading = true;
  bool _isCancelling = false;
  String? _error;

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

  bool get _canCancel {
    if (_booking == null) return false;
    final status = _booking!['status'] as String?;
    return status == 'pending' || status == 'pre_inspection';
  }

  bool get _canStartRental {
    if (_booking == null) return false;
    final status = _booking!['status'] as String?;
    return status == 'pre_inspection';
  }

  Future<void> _cancelBooking() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red[600], size: 28),
            const SizedBox(width: 10),
            const Text('Cancel Booking?'),
          ],
        ),
        content: const Text(
          'Are you sure you want to cancel this booking? The vehicle will be made available for others.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No, Keep It'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Cancel Booking'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isCancelling = true);

    final token = await AuthService().getToken();
    if (token != null) {
      final success = await _rentalService.cancelBooking(
        bookingId: widget.bookingId,
        token: token,
      );

      if (mounted) {
        setState(() => _isCancelling = false);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking cancelled successfully'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/home');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to cancel booking. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _proceedToInspection() async {
    context.push('/rental-inspection/${widget.bookingId}/pre');
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'pre_inspection':
        return Colors.blue;
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.teal;
      case 'cancelled':
        return Colors.red;
      case 'rejected':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'pre_inspection':
        return Icons.camera_alt;
      case 'active':
        return Icons.key;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      case 'rejected':
        return Icons.block;
      default:
        return Icons.info;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'pre_inspection':
        return 'Pre-Inspection Done';
      case 'active':
        return 'Active';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'rejected':
        return 'Rejected';
      case 'post_inspection':
        return 'Post-Inspection';
      case 'pending_review':
        return 'Pending Review';
      default:
        return status;
    }
  }

  String _getStatusDescription(String status) {
    switch (status) {
      case 'pending':
        return 'Your booking has been created. Please complete the pre-rental vehicle inspection to proceed.';
      case 'pre_inspection':
        return 'Pre-rental inspection is complete. You can start your rental or cancel the booking.';
      case 'active':
        return 'Your rental is currently active.';
      case 'completed':
        return 'This rental has been completed.';
      case 'cancelled':
        return 'This booking was cancelled.';
      default:
        return '';
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '--';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '--';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _getImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return '';
    if (imageUrl.startsWith('http')) return imageUrl;
    return '${AuthService.baseUrl}$imageUrl';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
          title: const Text('Booking Details'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _booking == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
          title: const Text('Booking Details'),
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

    final status = _booking!['status'] as String? ?? 'unknown';
    final statusColor = _getStatusColor(status);
    final vehicle = _booking!['vehicle'] as Map<String, dynamic>?;
    final vehicleName = vehicle != null
        ? '${vehicle['make']} ${vehicle['model']}'
        : 'Unknown Vehicle';
    final vehicleYear = vehicle?['year']?.toString() ?? '';
    final vehicleImage = _getImageUrl(vehicle?['image_url']);
    final totalPrice = (_booking!['total_price'] as num?)?.toDouble() ?? 0.0;
    final startDate = _booking!['start_date'] as String?;
    final endDate = _booking!['end_date'] as String?;

    int days = 1;
    if (startDate != null && endDate != null) {
      final start = DateTime.tryParse(startDate);
      final end = DateTime.tryParse(endDate);
      if (start != null && end != null) {
        days = end.difference(start).inDays;
        if (days <= 0) days = 1;
      }
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        title: const Text('Booking Details'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [statusColor.withOpacity(0.15), statusColor.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_getStatusIcon(status), size: 36, color: statusColor),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getStatusLabel(status).toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _getStatusDescription(status),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Container(
                      height: 160,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue[100]!, Colors.blue[50]!],
                        ),
                      ),
                      child: vehicleImage.isNotEmpty
                          ? Image.network(
                              vehicleImage,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.directions_car,
                                size: 64,
                                color: Colors.blue[300],
                              ),
                            )
                          : Icon(
                              Icons.directions_car,
                              size: 64,
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
                          vehicleName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (vehicleYear.isNotEmpty)
                          Text(
                            vehicleYear,
                            style: TextStyle(color: Colors.grey[600], fontSize: 15),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
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
                      'Booking Details',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Divider(height: 24),
                    _buildDetailRow(
                      Icons.tag,
                      'Booking ID',
                      '#${widget.bookingId}',
                    ),
                    _buildDetailRow(
                      Icons.calendar_today,
                      'Start Date',
                      _formatDate(startDate),
                    ),
                    _buildDetailRow(
                      Icons.event,
                      'End Date',
                      _formatDate(endDate),
                    ),
                    _buildDetailRow(
                      Icons.timer,
                      'Duration',
                      '$days day${days > 1 ? 's' : ''}',
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Price',
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

            if (status == 'pending') ...[

              ElevatedButton.icon(
                onPressed: _proceedToInspection,
                icon: const Icon(Icons.camera_alt),
                label: const Text(
                  'Start Pre-Rental Inspection',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
            ],

            if (_canCancel) ...[

              OutlinedButton.icon(
                onPressed: _isCancelling ? null : _cancelBooking,
                icon: _isCancelling
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cancel_outlined),
                label: Text(
                  _isCancelling ? 'Cancelling...' : 'Cancel Booking',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],

            if (status == 'cancelled') ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.red[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This booking has been cancelled. The vehicle is now available for others.',
                        style: TextStyle(color: Colors.red[800], fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[500]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: TextStyle(color: Colors.grey[600])),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
