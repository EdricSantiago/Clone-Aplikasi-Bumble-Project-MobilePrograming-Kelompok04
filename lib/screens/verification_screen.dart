import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/profile_service.dart';

class VerificationScreen extends StatelessWidget {
  const VerificationScreen({super.key, required this.userId});

  final String userId;

  Future<void> _openCamera(BuildContext context) async {
    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
    );

    if (photo != null && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VerificationReviewScreen(
            userId: userId,
            capturedImage: File(photo.path),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          children: [
            const SizedBox(height: 10),
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 140,
                    height: 190,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                      image: const DecorationImage(
                        image: NetworkImage(
                          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified,
                        color: Colors.black,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Copy this pose and take a photo',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              "We'll check this photo matches the person in your profile. It won't be visible on your profile.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 24),
            const Text(
              'To verify successfully:',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text('  • Your face must be clearly visible',
                style: TextStyle(color: Colors.black87, fontSize: 15)),
            const SizedBox(height: 4),
            const Text('  • You must be copying this pose exactly',
                style: TextStyle(color: Colors.black87, fontSize: 15)),
            const SizedBox(height: 20),
            const Text(
              'For more info on how we use, retain and protect your personal data, please read our Privacy Policy.',
              style: TextStyle(color: Colors.black54, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                onPressed: () => _openCamera(context),
                child: const Text(
                  'Take my photo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildOptionRow('View Privacy Policy', Icons.arrow_forward_ios),
            _buildOptionRow('Why is this needed?', Icons.arrow_forward_ios),
            _buildOptionRow('Get Help', Icons.info_outline),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionRow(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, color: Colors.black87)),
          Icon(icon, size: 18, color: Colors.black54),
        ],
      ),
    );
  }
}

class VerificationReviewScreen extends StatefulWidget {
  const VerificationReviewScreen({
    super.key,
    required this.userId,
    required this.capturedImage,
  });

  final String userId;
  final File capturedImage;

  @override
  State<VerificationReviewScreen> createState() =>
      _VerificationReviewScreenState();
}

class _VerificationReviewScreenState extends State<VerificationReviewScreen> {
  final ProfileService _profileService = ProfileService();
  late File _currentImage;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _currentImage = widget.capturedImage;
  }

  Future<void> _retakePhoto() async {
    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
    );

    if (photo != null && mounted) {
      setState(() {
        _currentImage = File(photo.path);
      });
    }
  }

  Future<void> _submitVerification() async {
    setState(() => _isSubmitting = true);

    await _profileService.verifyProfile(widget.userId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diverifikasi!')),
      );

      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 130,
                    height: 170,
                    color: Colors.amber,
                    child: Image.network(
                      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 130,
                    height: 170,
                    child: Image.file(
                      _currentImage,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            const Text(
              'Review and save your photo',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '• Bumble will compare this photo with your profile photo, which may include the use of facial recognition technology',
              style: TextStyle(color: Colors.black87, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 10),
            const Text(
              "• We'll keep your photo and scans to verify your photos in the future",
              style: TextStyle(color: Colors.black87, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 16),
            const Text(
              'Contact us via our Help Centre to withdraw your consent',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                onPressed: _isSubmitting ? null : _submitVerification,
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Agree and submit',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 52,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Colors.black, width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                onPressed: _retakePhoto,
                child: const Text(
                  'Retake',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildOptionRow('View Privacy Policy', Icons.arrow_forward_ios),
            _buildOptionRow('Why is this needed?', Icons.arrow_forward_ios),
            _buildOptionRow('Get Help', Icons.info_outline),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionRow(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, color: Colors.black87)),
          Icon(icon, size: 18, color: Colors.black54),
        ],
      ),
    );
  }
}