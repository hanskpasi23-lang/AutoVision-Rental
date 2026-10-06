import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/inspection_service.dart';

class InspectionUploadScreen extends StatefulWidget {
  final String imagePath;

  const InspectionUploadScreen({super.key, required this.imagePath});

  @override
  State<InspectionUploadScreen> createState() => _InspectionUploadScreenState();
}

class _InspectionUploadScreenState extends State<InspectionUploadScreen> {
  final InspectionService _inspectionService = InspectionService();
  bool _isUploading = false;
  Map<String, dynamic>? _result;

  Future<void> _uploadImage() async {
    setState(() {
      _isUploading = true;
    });

    try {
      final result = await _inspectionService.uploadInspectionImage(widget.imagePath);
      setState(() {
        _result = result;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review Photo')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.file(File(widget.imagePath)),
            const SizedBox(height: 20),
            if (_result != null) ...[
              const Text(
                'AI Analysis Result:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _result.toString(),
                  style: const TextStyle(color: Colors.green),
                ),
              ),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                child: const Text('Finish Inspection'),
              ),
            ] else ...[
              if (_isUploading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _uploadImage,
                  child: const Text('Analyze for Damage'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
