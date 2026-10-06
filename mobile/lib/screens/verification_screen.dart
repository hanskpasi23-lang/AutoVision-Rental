import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _uploading = false;
  Map<String, String?> _uploadedImages = {
    'license_front': null,
    'license_back': null,
    'id_card': null,
    'selfie': null,
  };

  Future<void> _pickAndUploadImage(String type) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _uploading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = await authService.getToken();

      if (token == null) throw Exception('Not authenticated');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AuthService.baseUrl}/users/verification-documents?document_type=$type'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('file', image.path));

      var response = await request.send();

      if (response.statusCode == 200) {
        setState(() {
          _uploadedImages[type] = image.path;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document uploaded successfully')),
        );

        await authService.fetchUserProfile();
      } else {
        throw Exception('Failed to upload');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading document: $e')),
      );
    } finally {
      setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).currentUser;
    final isPending = user?.verificationStatus == 'pending';
    final isVerified = user?.verificationStatus == 'verified';
    final isRejected = user?.verificationStatus == 'rejected';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Verification'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusCard(user?.verificationStatus ?? 'unverified'),
            const SizedBox(height: 24),

            if (isVerified)
               const Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 64),
                    SizedBox(height: 16),
                    Text(
                      'Your account is verified!',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text('You can now book vehicles.'),
                  ],
                ),
              )
            else ...[
              const Text(
                'Upload Documents',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please upload clear photos of the following documents to verify your identity.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),

              _buildUploadButton('Driver\'s License (Front)', 'license_front'),
              _buildUploadButton('Driver\'s License (Back)', 'license_back'),
              _buildUploadButton('National ID / Passport', 'id_card'),
              _buildUploadButton('Selfie with ID', 'selfie'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String status) {
    Color color;
    IconData icon;
    String text;

    switch (status) {
      case 'verified':
        color = Colors.green;
        icon = Icons.verified;
        text = 'Verified';
        break;
      case 'pending':
        color = Colors.orange;
        icon = Icons.pending;
        text = 'Pending Review';
        break;
      case 'rejected':
        color = Colors.red;
        icon = Icons.error;
        text = 'Rejected';
        break;
      default:
        color = Colors.grey;
        icon = Icons.info;
        text = 'Unverified';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Status: $text',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
              ),
              if (status == 'pending')
                const Text('Admin is reviewing your documents', style: TextStyle(fontSize: 12)),
               if (status == 'unverified')
                const Text('Upload documents to start renting', style: TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButton(String label, String type) {
    final isUploaded = _uploadedImages[type] != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: _uploading ? null : () => _pickAndUploadImage(type),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isUploaded ? Colors.green.shade50 : Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isUploaded ? Icons.check : Icons.upload_file,
                  color: isUploaded ? Colors.green : Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (isUploaded)
                      const Text(
                        'Uploaded',
                        style: TextStyle(color: Colors.green, fontSize: 12),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
