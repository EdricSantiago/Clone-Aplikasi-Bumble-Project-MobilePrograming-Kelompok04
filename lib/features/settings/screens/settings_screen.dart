import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:bumble/features/settings/screens/blocked_accounts_screen.dart';

import 'package:bumble/features/auth/services/auth_service.dart';
import 'package:bumble/features/profile/screens/location_screen.dart';
import 'package:bumble/features/profile/services/profile_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();

  Future<void> _logOut() async {
    await _authService.logout();
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  String _formatLocation(String rawLocation) {
    if (rawLocation.trim().isEmpty) return 'Add';

    final parts = rawLocation.split(',');
    if (parts.length < 2) return rawLocation;

    final city = parts[0].trim();
    final country = parts.sublist(1).join(',').trim();

    if (country.length == 2) {
      return '$city, ${country.toUpperCase()}';
    }

    const countryMap = {
      'indonesia': 'ID',
      'japan': 'JP',
      'jepang': 'JP',
      'united states': 'US',
      'united kingdom': 'UK',
      'singapore': 'SG',
      'singapura': 'SG',
      'south korea': 'KR',
      'korea': 'KR',
      'malaysia': 'MY',
      'thailand': 'TH',
      'vietnam': 'VN',
      'philippines': 'PH',
      'filipina': 'PH',
      'australia': 'AU',
      'china': 'CN',
      'germany': 'DE',
      'jerman': 'DE',
      'france': 'FR',
      'prancis': 'FR',
      'canada': 'CA',
      'kanada': 'CA',
    };

    final code = countryMap[country.toLowerCase()] ?? country;
    return '$city, $code';
  }

  void _showDurationBottomSheet(String uid) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 20,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFD600),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: const Text(
                  'How long do you want to be invisible for?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              _buildBottomSheetOption('24 hours', () {
                Navigator.pop(ctx);
                _showStatusBottomSheet(uid, 'another 1 day');
              }),
              _buildBottomSheetOption('72 hours', () {
                Navigator.pop(ctx);
                _showStatusBottomSheet(uid, 'another 3 days');
              }),
              _buildBottomSheetOption('A week', () {
                Navigator.pop(ctx);
                _showStatusBottomSheet(uid, 'another 7 days');
              }),
              _buildBottomSheetOption('Until I change it', () {
                Navigator.pop(ctx);
                _showStatusBottomSheet(uid, 'until you change it');
              }),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showStatusBottomSheet(String uid, String durationText) {
    final statusOptions = [
      '✈️ I\'m travelling',
      '📝 I\'m focused on work',
      '🔌 I\'m on a digital detox',
      '💖 I\'m prioritising myself',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 24,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFD600),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: const Text(
                  'Do you want to set a status for your existing matches while you\'re away?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              ...statusOptions.map(
                (status) => _buildBottomSheetOption(status, () {
                  Navigator.pop(ctx);
                  _activateSnooze(uid, durationText, status);
                }),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _activateSnooze(uid, durationText, null);
                },
                child: const Text(
                  'No thanks',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomSheetOption(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
        child: Text(
          text,
          textAlign: TextAlign.left,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Future<void> _activateSnooze(
    String uid,
    String durationText,
    String? reason,
  ) async {
    await _profileService.updateSnoozeMode(
      userId: uid,
      isSnoozed: true,
      snoozeDurationText: durationText,
      snoozeReason: reason,
    );
  }

  Future<void> _deactivateSnooze(String uid) async {
    await _profileService.updateSnoozeMode(userId: uid, isSnoozed: false);
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          final userData = snapshot.data?.data() ?? {};
          final isSnoozed = userData['isSnoozed'] == true;
          final durationText = userData['snoozeDurationText'] as String? ?? '';
          final reason = userData['snoozeReason'] as String? ?? '';
          final rawLocation = userData['location'] as String? ?? '';
          final formattedLocation = _formatLocation(rawLocation);

          String snoozeDescription;
          if (!isSnoozed) {
            snoozeDescription = 'Hide your profile temporarily. You won\'t lose any connections or chats.';
          } else if (reason.isNotEmpty) {
            snoozeDescription =
                'You are invisible for $durationText. You set your away status to "$reason".';
          } else {
            snoozeDescription = 'You are invisible for $durationText.';
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(28, 16, 28, 34),
            children: [
              _SettingsTile(
                title: 'Type of connection',
                trailing: 'Date',
                showChevron: false,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('You are in Dating mode')),
                  );
                },
              ),
              const SizedBox(height: 14),
              _SettingsTile(
                title: isSnoozed ? 'Deactivate snooze mode' : 'Snooze mode',
                onTap: () {
                  if (isSnoozed) {
                    _deactivateSnooze(uid);
                  } else {
                    _showDurationBottomSheet(uid);
                  }
                },
              ),
              _Description(snoozeDescription),
              const SizedBox(height: 26),
              const _SectionTitle('Location'),
              const SizedBox(height: 14),
              _SettingsTile(
                title: 'Current location',
                trailing: formattedLocation,
                onTap: () {
                  if (uid.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LocationScreen(userId: uid),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 26),
              const _SectionTitle('Privacy'),
              const SizedBox(height: 14),
              _SettingsTile(
                title: 'Akun diblokir',
                leading: const Icon(Icons.block),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BlockedAccountsScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 34),
              OutlinedButton(
                onPressed: _logOut,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  side: const BorderSide(color: Colors.black, width: 1.2),
                  foregroundColor: Colors.black,
                ),
                child: const Text(
                  'Log out',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 44),
              const Icon(
                Icons.hexagon_outlined,
                size: 32,
                color: Colors.black54,
              ),
              const SizedBox(height: 4),
              const Text(
                'Bumble',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Version 1.1.0\nCreated with love.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.title,
    required this.onTap,
    this.trailing,
    this.leading,
    this.showChevron = true,
  });

  final String title;
  final String? trailing;
  final Widget? leading;
  final bool showChevron;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        constraints: const BoxConstraints(minHeight: 74),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xffdddddd), width: 1.6),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 18)],
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: const TextStyle(fontSize: 17, color: Colors.black54),
              ),
            if (showChevron) ...[
              const SizedBox(width: 18),
              const Icon(Icons.arrow_forward_ios, size: 25),
            ],
          ],
        ),
      ),
    );
  }
}

class _Description extends StatelessWidget {
  const _Description(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 10, 24, 0),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black54,
          fontSize: 16,
          height: 1.5,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.black54,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
