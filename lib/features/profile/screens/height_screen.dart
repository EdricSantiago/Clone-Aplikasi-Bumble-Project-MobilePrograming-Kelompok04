import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:bumble/features/profile/services/profile_service.dart';

class HeightScreen extends StatefulWidget {
  const HeightScreen({
    super.key,
    required this.userId,
  });

  final String userId;

  @override
  State<HeightScreen> createState() => _HeightScreenState();
}

class _HeightScreenState extends State<HeightScreen> {
  final ProfileService _profileService = ProfileService();
  final TextEditingController _heightController = TextEditingController();
  bool _isLoading = false;

  Future<void> _saveHeight(String height) async {
    if (height.trim().isEmpty || _isLoading) return;

    setState(() => _isLoading = true);
    try {
      await _profileService.updateHeight(
        userId: widget.userId,
        height: height,
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan tinggi: $e')),
        );
      }
    }
  }

  void _showHeightPickerDialog(String currentHeight) {
    final initialText = currentHeight.replaceAll(RegExp(r'[^0-9]'), '');
    _heightController.text = initialText;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Enter your height (cm)'),
          content: TextField(
            controller: _heightController,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'e.g. 175 cm',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
            ),
            ElevatedButton(
              onPressed: () {
                final text = _heightController.text.trim();
                Navigator.pop(ctx);
                if (text.isNotEmpty) {
                  final formatted = text.contains('cm') ? text : '$text cm';
                  _saveHeight(formatted);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E1E1E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? {};
        final currentHeight = (data['height'] ?? '').toString().trim();
        final isFilled = currentHeight.isNotEmpty;

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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.straighten,
                    size: 48,
                    color: Colors.black,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'What is your height?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 36),
                  InkWell(
                    onTap: _isLoading ? null : () => _showHeightPickerDialog(currentHeight),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isFilled ? Colors.black : const Color(0xFFE0E0E0),
                          width: isFilled ? 2.0 : 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          isFilled ? currentHeight : 'Enter your height',
                          style: TextStyle(
                            fontSize: 16,
                            color: isFilled ? Colors.black : Colors.black54,
                            fontWeight: isFilled ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}