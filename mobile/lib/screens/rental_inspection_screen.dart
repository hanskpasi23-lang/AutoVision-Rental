import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../services/rental_service.dart';
import '../services/auth_service.dart';

class RentalInspectionScreen extends StatefulWidget {
  final int bookingId;
  final String inspectionType;

  const RentalInspectionScreen({
    super.key,
    required this.bookingId,
    required this.inspectionType,
  });

  @override
  State<RentalInspectionScreen> createState() => _RentalInspectionScreenState();
}

class _RentalInspectionScreenState extends State<RentalInspectionScreen> {
  final RentalService _rentalService = RentalService();
  final ImagePicker _picker = ImagePicker();

  File? _frontImage;
  File? _backImage;
  File? _leftImage;
  File? _rightImage;

  int _currentStep = 0;
  bool _isUploading = false;

  final List<Map<String, dynamic>> _angles = [
    {'key': 'front', 'label': 'Front View', 'icon': Icons.arrow_upward},
    {'key': 'back', 'label': 'Back View', 'icon': Icons.arrow_downward},
    {'key': 'left', 'label': 'Left Side', 'icon': Icons.arrow_back},
    {'key': 'right', 'label': 'Right Side', 'icon': Icons.arrow_forward},
  ];

  File? _getImageForStep(int step) {
    switch (step) {
      case 0: return _frontImage;
      case 1: return _backImage;
      case 2: return _leftImage;
      case 3: return _rightImage;
      default: return null;
    }
  }

  void _setImageForStep(int step, File image) {
    setState(() {
      switch (step) {
        case 0: _frontImage = image; break;
        case 1: _backImage = image; break;
        case 2: _leftImage = image; break;
        case 3: _rightImage = image; break;
      }
    });
  }

  Future<void> _capturePhoto() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (photo != null) {
      _setImageForStep(_currentStep, File(photo.path));

      if (_currentStep < 3) {
        await Future.delayed(const Duration(milliseconds: 500));
        setState(() => _currentStep++);
      }
    }
  }

  Future<void> _pickFromGallery() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (photo != null) {
      _setImageForStep(_currentStep, File(photo.path));
    }
  }

  bool get _allPhotosCapture =>
      _frontImage != null &&
      _backImage != null &&
      _leftImage != null &&
      _rightImage != null;

  Future<void> _submitInspection() async {
    if (!_allPhotosCapture) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please capture all 4 photos')),
      );
      return;
    }

    setState(() => _isUploading = true);

    final token = await AuthService().getToken();
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in again')),
        );
      }
      setState(() => _isUploading = false);
      return;
    }

    Map<String, dynamic>? result;

    if (widget.inspectionType == 'pre') {
      result = await _rentalService.uploadPreInspection(
        bookingId: widget.bookingId,
        token: token,
        frontImage: _frontImage!,
        backImage: _backImage!,
        leftImage: _leftImage!,
        rightImage: _rightImage!,
      );
    } else {
      result = await _rentalService.uploadPostInspection(
        bookingId: widget.bookingId,
        token: token,
        frontImage: _frontImage!,
        backImage: _backImage!,
        leftImage: _leftImage!,
        rightImage: _rightImage!,
      );
    }

    if (mounted) {
      setState(() {
        _isUploading = false;
      });
    }

    if (result != null) {
      if (result['error'] == true) {

        String errorMessage = 'Image validation failed.';
        String? failedAngle;

        final detail = result['detail'];
        if (detail is Map) {
          if (detail['message'] != null) {
            errorMessage = detail['message'];
          }
          if (detail['failed_angle'] != null) {
            failedAngle = detail['failed_angle'];
          }
        } else if (detail is String) {
          errorMessage = detail;
        }

        if (mounted) {
          if (failedAngle != null) {

            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                    SizedBox(width: 8),
                    Text('Validation Failed'),
                  ],
                ),
                content: Text(errorMessage),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);

                      setState(() {
                        switch (failedAngle) {
                          case 'front':
                            _frontImage = null;
                            _currentStep = 0;
                            break;
                          case 'back':
                            _backImage = null;
                            _currentStep = 1;
                            break;
                          case 'left':
                            _leftImage = null;
                            _currentStep = 2;
                            break;
                          case 'right':
                            _rightImage = null;
                            _currentStep = 3;
                            break;
                        }
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[700],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retake Photo'),
                  ),
                ],
              ),
            );
          } else {

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                duration: const Duration(seconds: 8),
                backgroundColor: Colors.orange[800],
              ),
            );
          }
        }
      } else {

        if (mounted) {
          context.push('/inspection-result/${widget.bookingId}', extra: {
            'result': result,
            'type': widget.inspectionType,
          });
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inspection upload failed. Check your connection and try again.'),
            duration: Duration(seconds: 5),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPre = widget.inspectionType == 'pre';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: isPre ? Colors.blue[700] : Colors.orange[700],
        foregroundColor: Colors.white,
        title: Text(isPre ? 'Pre-Rental Inspection' : 'Post-Rental Inspection'),
        centerTitle: true,
      ),
      body: Column(
        children: [

          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(4, (index) {
                    final isComplete = _getImageForStep(index) != null;
                    final isCurrent = _currentStep == index;
                    return Column(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isComplete
                                ? Colors.green
                                : isCurrent
                                    ? (isPre ? Colors.blue : Colors.orange)
                                    : Colors.grey[300],
                          ),
                          child: Icon(
                            isComplete ? Icons.check : _angles[index]['icon'],
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _angles[index]['label'],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            color: isCurrent ? (isPre ? Colors.blue[700] : Colors.orange[700]) : Colors.grey[600],
                          ),
                        ),
                      ],
                    );
                  }),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (_frontImage != null ? 0.25 : 0) +
                         (_backImage != null ? 0.25 : 0) +
                         (_leftImage != null ? 0.25 : 0) +
                         (_rightImage != null ? 0.25 : 0),
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation(isPre ? Colors.blue : Colors.orange),
                ),
              ],
            ),
          ),

          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: _getImageForStep(_currentStep) != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              _getImageForStep(_currentStep)!,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: _capturePhoto,
                                  icon: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.refresh, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            bottom: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check, color: Colors.white, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${_angles[_currentStep]['label']} captured',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : InkWell(
                        onTap: _capturePhoto,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.grey[200],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _angles[_currentStep]['icon'],
                                size: 80,
                                color: isPre ? Colors.blue[300] : Colors.orange[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Capture ${_angles[_currentStep]['label']}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Take a clear photo of the vehicle\'s ${_angles[_currentStep]['label'].toLowerCase()}',
                                style: TextStyle(color: Colors.grey[600]),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: _capturePhoto,
                                    icon: const Icon(Icons.camera_alt),
                                    label: const Text('Camera'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isPre ? Colors.blue[700] : Colors.orange[700],
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  OutlinedButton.icon(
                                    onPressed: _pickFromGallery,
                                    icon: const Icon(Icons.photo_library),
                                    label: const Text('Gallery'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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

          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _currentStep--),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Previous'),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isUploading
                        ? null
                        : _currentStep < 3
                            ? () => setState(() => _currentStep++)
                            : _allPhotosCapture
                                ? _submitInspection
                                : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPre ? Colors.blue[700] : Colors.orange[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isUploading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            _currentStep < 3
                                ? 'Next'
                                : _allPhotosCapture
                                    ? 'Analyze for Damage'
                                    : 'Complete all photos',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
