import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:bumble/features/profile/services/profile_service.dart';

class DrinkingScreen extends StatefulWidget {
  const DrinkingScreen({
    super.key,
    required this.userId,
  });

  final String userId;

  @override
  State<DrinkingScreen> createState() => _DrinkingScreenState();
}

class _DrinkingScreenState extends State<DrinkingScreen> {
  final ProfileService _profileService = ProfileService();
  bool _isLoading = false;

  static const List<String> _options = [
    'Yes, I drink',
    'I drink sometimes',
    'I rarely drink',
    "No, I don't drink",
    "I'm sober",
  ];

  Future<void> _selectOption(String option) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      await _profileService.updateDrinking(
        userId: widget.userId,
        drinking: option,
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan kebiasaan minum: $e')),
        );
      }
    }
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
        final currentDrinking = (data['drinking'] ?? '').toString().trim();

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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const Icon(
                    Icons.wine_bar_outlined,
                    size: 48,
                    color: Colors.black,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Do you drink?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 36),
                  ..._options.map(
                    (opt) {
                      final isSelected = opt.toLowerCase() == currentDrinking.toLowerCase();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: InkWell(
                          onTap: _isLoading ? null : () => _selectOption(opt),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? Colors.black : const Color(0xFFE0E0E0),
                                width: isSelected ? 2.0 : 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                opt,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
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