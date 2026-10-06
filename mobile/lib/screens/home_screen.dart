import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/rental_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NotificationService _notifService = NotificationService();
  int _unreadCount = 0;
  Map<String, dynamic>? _dashboardStats;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
    _loadDashboardStats();
  }

  Future<void> _loadDashboardStats() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final token = await auth.getToken();
    if (token != null) {
      final rentalService = RentalService();
      final stats = await rentalService.getDashboardStats(token);
      if (mounted && stats != null) {
        setState(() => _dashboardStats = stats);
      }
    }
  }

  Future<void> _loadUnreadCount() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final token = await auth.getToken();
    if (token != null) {
      final count = await _notifService.getUnreadCount(token);
      if (mounted) setState(() => _unreadCount = count);
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 150) return Colors.green;
    if (score >= 100) return Colors.blue;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }

  String _getScoreLabel(double score) {
    if (score >= 150) return 'Excellent';
    if (score >= 100) return 'Good';
    if (score >= 50) return 'Fair';
    return 'Needs Improvement';
  }

  String _getScoreDescription(double score) {
    if (score >= 180) return 'You qualify for all premium vehicles';
    if (score >= 150) return 'You qualify for 5% discount';
    if (score >= 100) return 'You qualify for standard vehicles';
    if (score >= 50) return 'You have basic rental access';
    return 'Complete rentals to improve your score';
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('AutoVision Rent'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [

          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () async {
                  await context.push('/notifications');
                  _loadUnreadCount();
                  authService.fetchUserProfile();
                },
              ),
              if (_unreadCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      _unreadCount > 9 ? '9+' : '$_unreadCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () async {
              await context.push('/profile');
              authService.fetchUserProfile();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authService.logout();
              context.go('/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await authService.fetchUserProfile();
          await _loadUnreadCount();
          await _loadDashboardStats();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[700]!, Colors.blue[500]!],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, ${authService.currentUser?.fullName ?? 'User'}!',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ready for your next adventure?',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if ((authService.currentUser?.verificationStatus ?? 'unverified') != 'verified')
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (authService.currentUser?.verificationStatus ?? 'unverified') == 'rejected'
                      ? Colors.red.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (authService.currentUser?.verificationStatus ?? 'unverified') == 'rejected'
                        ? Colors.red
                        : Colors.orange,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      (authService.currentUser?.verificationStatus ?? 'unverified') == 'rejected'
                          ? Icons.error
                          : Icons.warning_amber_rounded,
                      color: (authService.currentUser?.verificationStatus ?? 'unverified') == 'rejected'
                          ? Colors.red
                          : Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (authService.currentUser?.verificationStatus ?? 'unverified') == 'pending'
                                ? 'Verification Pending'
                                : (authService.currentUser?.verificationStatus ?? 'unverified') == 'rejected'
                                    ? 'Verification Rejected'
                                    : 'Account Unverified',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            (authService.currentUser?.verificationStatus ?? 'unverified') == 'pending'
                                ? 'Your documents are under review.'
                                : 'Verify your account to rent vehicles.',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => context.push('/verification'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (authService.currentUser?.verificationStatus ?? 'unverified') == 'rejected'
                            ? Colors.red
                            : Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: const Text('Check'),
                    ),
                  ],
                ),
              ),

            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickAction(
                    context,
                    icon: Icons.directions_car,
                    label: 'Browse\nVehicles',
                    color: Colors.blue,
                    onTap: () async {
                      await context.push('/vehicles');
                      authService.fetchUserProfile();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                  Expanded(
                  child: _buildQuickAction(
                    context,
                    icon: Icons.favorite,
                    label: 'My\nWishlist',
                    color: Colors.pink,
                    onTap: () async {
                      await context.push('/wishlist');
                      authService.fetchUserProfile();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickAction(
                    context,
                    icon: Icons.star,
                    label: 'Credit\nScore',
                    color: Colors.purple,
                    onTap: () async {
                      await context.push('/credit-score');
                      authService.fetchUserProfile();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickAction(
                    context,
                    icon: Icons.key,
                    label: 'Active\nRental',
                    color: Colors.green,
                    onTap: () async {
                      await context.push('/active-rental');
                      authService.fetchUserProfile();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            const Text(
              'Your Trust Score',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => context.push('/credit-score'),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 70,
                            height: 70,
                            child: CircularProgressIndicator(
                              value: (authService.currentUser?.creditScore ?? 0) / 200,
                              strokeWidth: 8,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation(_getScoreColor(authService.currentUser?.creditScore ?? 0)),
                            ),
                          ),
                          Text(
                            (authService.currentUser?.creditScore ?? 0).toStringAsFixed(0),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _getScoreColor(authService.currentUser?.creditScore ?? 0),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_getScoreLabel(authService.currentUser?.creditScore ?? 0)} Standing',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getScoreDescription(authService.currentUser?.creditScore ?? 0),
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (_dashboardStats != null) ...[
              const Text(
                'Dashboard',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      label: 'Active Rentals',
                      count: _dashboardStats!['active_rentals']?.toString() ?? '0',
                      icon: Icons.key,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      label: 'Completed',
                      count: _dashboardStats!['completed_rentals']?.toString() ?? '0',
                      icon: Icons.check_circle,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            if (_dashboardStats != null && (_dashboardStats!['recent_rentals'] as List).isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Activity',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {

                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...(_dashboardStats!['recent_rentals'] as List).map((rental) {
                final vehicleName = rental['vehicle'] ?? 'Unknown Vehicle';
                final status = rental['status'] ?? 'unknown';
                final date = rental['start_date'] != null
                    ? DateTime.parse(rental['start_date']).toString().split(' ')[0]
                    : '--';
                final price = rental['total_price']?.toString() ?? '0.00';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(status).withOpacity(0.1),
                      child: Icon(
                        _getStatusIcon(status),
                        color: _getStatusColor(status),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      vehicleName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('$date • \$$price'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(status),
                        ),
                      ),
                    ),
                    onTap: () {
                      if (status == 'active' || status == 'post_inspection') {
                        context.push('/active-rental/${rental['id']}');
                      } else if (status == 'pending' || status == 'pre_inspection') {
                        context.push('/booking-detail/${rental['id']}');
                      } else {
                        context.push('/review-details/${rental['id']}');
                      }
                    },
                  ),
                );
              }),
            ] else
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text('No recent activity'),
                ),
              ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildStatCard({
    required String label,
    required String count,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              count,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active': return Colors.green;
      case 'completed': return Colors.blue;
      case 'cancelled': return Colors.red;
      case 'pending': return Colors.orange;
      case 'pre_inspection': return Colors.indigo;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'active': return Icons.key;
      case 'completed': return Icons.check_circle;
      case 'cancelled': return Icons.cancel;
      case 'pending': return Icons.schedule;
      case 'pre_inspection': return Icons.camera_alt;
      default: return Icons.info;
    }
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

