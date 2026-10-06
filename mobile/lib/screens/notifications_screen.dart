import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final token = await auth.getToken();
    if (token == null) return;

    final data = await _notificationService.getNotifications(token);
    if (mounted) {
      setState(() {
        _notifications = data;
        _loading = false;
      });
    }
  }

  Future<void> _markAllRead() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final token = await auth.getToken();
    if (token == null) return;

    await _notificationService.markAllAsRead(token);
    if (mounted) _loadNotifications();
  }

  Future<void> _onNotificationTap(Map<String, dynamic> notification) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final token = await auth.getToken();
    if (token == null) return;

    final id = notification['id'];
    if (id != null && !(notification['is_read'] ?? false)) {
      await _notificationService.markAsRead(id, token);
    }

    if (notification['type'] == 'review_complete' && notification['data'] != null) {
      final bookingId = notification['data']['booking_id'];
      if (bookingId != null && mounted) {
        context.push('/review-details/$bookingId', extra: notification['data']);
      }
    }

    if (mounted) _loadNotifications();
  }

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return '';
    }
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'review_complete':
        return Icons.verified;
      case 'refund_processed':
        return Icons.account_balance_wallet;
      case 'credit_updated':
        return Icons.trending_up;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String? type) {
    switch (type) {
      case 'review_complete':
        return Colors.blue;
      case 'refund_processed':
        return Colors.green;
      case 'credit_updated':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_notifications.any((n) => !(n['is_read'] ?? true)))
            TextButton.icon(
              onPressed: _markAllRead,
              icon: const Icon(Icons.done_all, size: 18, color: Colors.white70),
              label: const Text('Read All', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_none, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'No notifications yet',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[400]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You\'ll be notified when your\ninspection review is complete.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final n = _notifications[index];
                      final isRead = n['is_read'] ?? false;
                      final type = n['type'] as String?;
                      final color = _getNotificationColor(type);

                      return Material(
                        color: isRead ? Colors.white : color.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _onNotificationTap(n),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isRead ? Colors.grey[200]! : color.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _getNotificationIcon(type),
                                    color: color,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              n['title'] ?? 'Notification',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                                                color: Colors.grey[900],
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (!isRead)
                                            Container(
                                              width: 8,
                                              height: 8,
                                              margin: const EdgeInsets.only(left: 8),
                                              decoration: BoxDecoration(
                                                color: color,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        n['message'] ?? '',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                          height: 1.4,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.access_time, size: 13, color: Colors.grey[400]),
                                          const SizedBox(width: 4),
                                          Text(
                                            _timeAgo(n['created_at']),
                                            style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                                          ),
                                          const Spacer(),
                                          if (type == 'review_complete')
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: color.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                'View Details →',
                                                style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
