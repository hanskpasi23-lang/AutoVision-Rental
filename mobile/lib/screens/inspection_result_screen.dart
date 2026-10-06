import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/rental_service.dart';
import '../services/auth_service.dart';

class InspectionResultScreen extends StatefulWidget {
  final int bookingId;
  final Map<String, dynamic> result;
  final String inspectionType;

  const InspectionResultScreen({
    super.key,
    required this.bookingId,
    required this.result,
    required this.inspectionType,
  });

  @override
  State<InspectionResultScreen> createState() => _InspectionResultScreenState();
}

class _InspectionResultScreenState extends State<InspectionResultScreen> {
  final RentalService _rentalService = RentalService();
  bool _isProcessing = false;

  Map<String, dynamic> get analysis => widget.result['analysis'] ?? {};
  bool get isPre => widget.inspectionType == 'pre';
  bool get damageDetected => isPre
      ? (analysis['damage_detected'] ?? false)
      : (analysis['new_damage_detected'] ?? false);
  bool get canProceed => widget.result['can_proceed'] ?? (analysis['can_proceed'] ?? true);

  Color get _severityColor {
    final severity = analysis['severity_grade'] ?? 'none';
    switch (severity) {
      case 'none': return Colors.green;
      case 'minor': return Colors.orange;
      case 'moderate': return Colors.deepOrange;
      case 'severe': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData get _severityIcon {
    final severity = analysis['severity_grade'] ?? 'none';
    switch (severity) {
      case 'none': return Icons.check_circle;
      case 'minor': return Icons.warning;
      case 'moderate': return Icons.error_outline;
      case 'severe': return Icons.dangerous;
      default: return Icons.help_outline;
    }
  }

  Future<void> _proceedWithRental() async {
    context.push('/payment/${widget.bookingId}');
  }

  Future<void> _cancelBooking() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking?'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final token = await AuthService().getToken();
      if (token != null) {
        final success = await _rentalService.cancelBooking(
          bookingId: widget.bookingId,
          token: token,
        );
        if (success && mounted) {
          context.go('/home');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: isPre ? Colors.blue[700] : Colors.orange[700],
        foregroundColor: Colors.white,
        title: Text(isPre ? 'Pre-Rental Analysis' : 'Post-Rental Analysis'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: damageDetected
                        ? [Colors.orange[100]!, Colors.orange[50]!]
                        : [Colors.green[100]!, Colors.green[50]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      damageDetected ? Icons.warning_amber : Icons.check_circle,
                      size: 80,
                      color: damageDetected ? Colors.orange[700] : Colors.green[700],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      damageDetected
                          ? (isPre ? 'Existing Damage Detected' : 'New Damage Detected')
                          : (isPre ? 'No Damage Detected' : 'No New Damage'),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: damageDetected ? Colors.orange[900] : Colors.green[900],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      analysis['summary'] ?? 'Analysis complete',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            if (!isPre) ...[
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(_severityIcon, color: _severityColor, size: 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Severity Grade', style: TextStyle(color: Colors.grey)),
                                Text(
                                  (analysis['severity_grade'] ?? 'none').toString().toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: _severityColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatItem(
                            'Credit Adjustment',
                            '${(analysis['credit_adjustment'] ?? 0) >= 0 ? '+' : ''}${analysis['credit_adjustment'] ?? 0}',
                            (analysis['credit_adjustment'] ?? 0) >= 0 ? Colors.green : Colors.red,
                          ),
                          _buildStatItem(
                            'Damage Cost',
                            '\$${(analysis['damage_cost_estimate'] ?? 0).toStringAsFixed(2)}',
                            Colors.orange,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (!isPre) ...[
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [Colors.amber[50]!, Colors.amber[100]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: Colors.amber[300]!, width: 1),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.amber[200],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.hourglass_top, size: 28, color: Colors.amber[800]),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Pending Admin Review',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[900],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your inspection report has been submitted for admin review. '
                        'Credit adjustments and any refunds will be processed after the review is complete.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.amber[800],
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.notifications_active, size: 16, color: Colors.amber[900]),
                            const SizedBox(width: 6),
                            Text(
                              'You\'ll receive a notification once reviewed',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.amber[900],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (damageDetected && (analysis['damage_details'] as List?)?.isNotEmpty == true) ...[
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Damage Details',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ...((analysis['damage_details'] as List?) ?? []).map((damage) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.orange[700], size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${damage['location']?.toString().toUpperCase()} - ${damage['type']}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    if (damage['description'] != null)
                                      Text(
                                        damage['description'],
                                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                      ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  damage['severity'] ?? 'unknown',
                                  style: TextStyle(
                                    color: Colors.orange[800],
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (isPre && analysis['recommendation'] != null)
              Card(
                elevation: 2,
                color: Colors.blue[50],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          analysis['recommendation'],
                          style: TextStyle(color: Colors.blue[900]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            if (isPre) ...[

              if (damageDetected && !canProceed) ...[
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [Colors.red[50]!, Colors.red[100]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: Colors.red[300]!, width: 1),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.block, size: 48, color: Colors.red[700]),
                        const SizedBox(height: 12),
                        Text(
                          'Rental Blocked',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[900],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This vehicle has pre-existing damage and cannot be rented. '
                          'Please cancel this booking and choose another vehicle.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red[800],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[

                ElevatedButton(
                  onPressed: _isProcessing ? null : _proceedWithRental,
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
                      : const Text(
                          'Pay & Start Rental',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(height: 12),
              ],
              OutlinedButton(
                onPressed: _cancelBooking,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Cancel Booking', style: TextStyle(fontSize: 16)),
              ),
            ] else ...[
              ElevatedButton(
                onPressed: () => context.go('/home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Back to Home',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'An admin will review your inspection. You\'ll be notified when it\'s complete.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
