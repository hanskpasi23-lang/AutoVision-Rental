import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    final status = user?.verificationStatus ?? 'unverified';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => authService.fetchUserProfile(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue[700],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                   const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 60, color: Colors.blue),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.fullName ?? 'User',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? 'No Email',
                    style: TextStyle(color: Colors.blue[100]),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(status),
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getStatusText(status),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Document Verification',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  _buildVerificationStatusCard(context, status),

                ],
              ),
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Account Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSettingsItem(
                    icon: Icons.person_outline,
                    title: 'Edit Profile',
                    onTap: () {},
                  ),
                  _buildSettingsItem(
                    icon: Icons.lock_outline,
                    title: 'Change Password',
                    onTap: () {},
                  ),
                  _buildSettingsItem(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    onTap: () => context.push('/notifications'),
                  ),
                  _buildSettingsItem(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    onTap: () {},
                  ),
                  _buildSettingsItem(
                    icon: Icons.logout,
                    title: 'Logout',
                    isDestructive: true,
                    onTap: () {
                      authService.logout();
                      context.go('/login');
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    if (status == 'verified') return Icons.verified;
    if (status == 'pending') return Icons.pending;
    if (status == 'rejected') return Icons.error_outline;
    return Icons.warning_amber_rounded;
  }

  String _getStatusText(String status) {
    if (status == 'verified') return 'Verified Account';
    if (status == 'pending') return 'Verification Pending';
    if (status == 'rejected') return 'Verification Failed';
    return 'Unverified Account';
  }

  Widget _buildVerificationStatusCard(BuildContext context, String status) {
    Color color;
    IconData icon;
    String title;
    String subtitle;
    Widget? action;

    if (status == 'verified') {
      color = Colors.green;
      icon = Icons.check_circle;
      title = 'Documents Verified';
      subtitle = 'You have full access to vehicle rentals.';
    } else if (status == 'pending') {
      color = Colors.orange;
      icon = Icons.schedule;
      title = 'Under Review';
      subtitle = 'Admin is reviewing your documents. Please wait.';
    } else if (status == 'rejected') {
      color = Colors.red;
      icon = Icons.cancel;
      title = 'Verification Rejected';
      subtitle = 'Please upload valid documents again.';
      action = ElevatedButton(
        onPressed: () => context.push('/verification'),
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red, foregroundColor: Colors.white),
        child: const Text('Update Documents'),
      );
    } else {
      color = Colors.blue;
      icon = Icons.upload_file;
      title = 'Verification Required';
      subtitle = 'Upload details to unlock rentals.';
      action = ElevatedButton(
        onPressed: () => context.push('/verification'),
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700], foregroundColor: Colors.white),
        child: const Text('Verify Now'),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (action != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: action,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive ? Colors.red : Colors.grey[700],
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? Colors.red : Colors.black,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
