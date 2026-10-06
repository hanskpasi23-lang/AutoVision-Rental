import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/rental_service.dart';

class ReviewDetailsScreen extends StatelessWidget {
  final int bookingId;
  final Map<String, dynamic> reviewData;

  const ReviewDetailsScreen({
    Key? key,
    required this.bookingId,
    required this.reviewData,
  }) : super(key: key);

  Future<Map<String, dynamic>?> _fetchData(BuildContext context) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final token = await auth.getToken();
    if (token != null) {
      final rentalService = RentalService();
      return await rentalService.getInspectionResults(bookingId, token);
    }
    return null;
  }

  Color _getSeverityColor(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'none':
        return Colors.green;
      case 'minor':
        return Colors.amber;
      case 'moderate':
        return Colors.orange;
      case 'severe':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getSeverityIcon(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'none':
        return Icons.check_circle;
      case 'minor':
        return Icons.info;
      case 'moderate':
        return Icons.warning;
      case 'severe':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetchData(context),
      initialData: reviewData.isNotEmpty ? reviewData : null,
      builder: (context, snapshot) {
        final data = snapshot.data ?? reviewData;

        if (data.isEmpty && snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
            );
        }

        final severity = data['severity_grade'] as String? ?? 'none';
        final originalSeverity = data['original_severity'] as String?;
        final reviewType = data['review_type'] as String? ?? 'AI Assessment';
        final vehicleName = data['vehicle_name'] as String? ?? 'Vehicle';
        final damageDetected = data['damage_detected'] as bool? ?? false;
        final damageSummary = data['damage_summary'] as String?;
        final costEstimate = (data['damage_cost_estimate'] as num?)?.toDouble() ?? 0.0;
        final creditAdjustment = (data['credit_adjustment'] as num?)?.toDouble() ?? 0.0;
        final oldCredit = (data['old_credit_score'] as num?)?.toDouble() ?? 0.0;
        final newCredit = (data['new_credit_score'] as num?)?.toDouble() ?? 0.0;
        final refundAmount = (data['refund_amount'] as num?)?.toDouble() ?? 0.0;
        final walletBalance = (data['wallet_balance'] as num?)?.toDouble() ?? 0.0;
        final adminNotes = data['admin_notes'] as String? ?? '';
        final sevColor = _getSeverityColor(severity);

        return Scaffold(
          backgroundColor: Colors.grey[50],
          body: CustomScrollView(
            slivers: [

              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                backgroundColor: sevColor,
                foregroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [sevColor, sevColor.withOpacity(0.7)],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                Icon(_getSeverityIcon(severity), color: Colors.white, size: 32),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Inspection Review Complete',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        vehicleName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([

                    _buildCard(
                      icon: _getSeverityIcon(severity),
                      iconColor: sevColor,
                      title: 'Severity Assessment',
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: sevColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: sevColor.withOpacity(0.2)),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  severity.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: sevColor,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: sevColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    reviewType,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: sevColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (originalSeverity != null && originalSeverity != severity) ...[
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'AI suggested: ',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    originalSeverity.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: _getSeverityColor(originalSeverity),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward, size: 14, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                  'Admin set: ',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: sevColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    severity.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: sevColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    if (damageSummary != null && damageSummary.isNotEmpty)
                      _buildCard(
                        icon: Icons.description,
                        iconColor: Colors.blueGrey,
                        title: 'Damage Summary',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: damageDetected ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    damageDetected ? '⚠ Damage Detected' : '✓ No Damage',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: damageDetected ? Colors.red : Colors.green,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  'Est. Cost: \$${costEstimate.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              damageSummary,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (damageSummary != null && damageSummary.isNotEmpty)
                      const SizedBox(height: 12),

                    _buildCard(
                      icon: Icons.trending_up,
                      iconColor: creditAdjustment >= 0 ? Colors.green : Colors.red,
                      title: 'Credit Score Impact',
                      child: Column(
                        children: [

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: (creditAdjustment >= 0 ? Colors.green : Colors.red).withOpacity(0.06),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '${creditAdjustment >= 0 ? '+' : ''}${creditAdjustment.toStringAsFixed(1)}',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    color: creditAdjustment >= 0 ? Colors.green : Colors.red,
                                  ),
                                ),
                                Text(
                                  'Credit Points',
                                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: _buildStatBox(
                                  'Before',
                                  oldCredit.toStringAsFixed(0),
                                  Colors.grey,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Icon(
                                  Icons.arrow_forward,
                                  size: 18,
                                  color: Colors.grey[400],
                                ),
                              ),
                              Expanded(
                                child: _buildStatBox(
                                  'After',
                                  newCredit.toStringAsFixed(0),
                                  creditAdjustment >= 0 ? Colors.green : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    if (refundAmount > 0)
                      _buildCard(
                        icon: Icons.account_balance_wallet,
                        iconColor: Colors.teal,
                        title: 'Early Return Refund',
                        child: Column(
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.teal.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.teal, size: 32),
                                  const SizedBox(height: 8),
                                  Text(
                                    '\$${refundAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.teal,
                                    ),
                                  ),
                                  Text(
                                    'Refunded to Wallet',
                                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.account_balance_wallet, size: 16, color: Colors.grey[400]),
                                const SizedBox(width: 6),
                                Text(
                                  'New Wallet Balance: \$${walletBalance.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                    if (refundAmount > 0) const SizedBox(height: 12),

                    if (adminNotes.isNotEmpty)
                      _buildCard(
                        icon: Icons.note,
                        iconColor: Colors.purple,
                        title: 'Admin Notes',
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.purple.withOpacity(0.1)),
                          ),
                          child: Text(
                            adminNotes,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              fontStyle: FontStyle.italic,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    Center(
                      child: Text(
                        'Booking #$bookingId',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1a1a2e),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
