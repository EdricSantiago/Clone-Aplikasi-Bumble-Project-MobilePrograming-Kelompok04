import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../widgets/photo_grid.dart';
import 'verification_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Stream<UserModel?> _streamProfile() {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return Stream.value(null);

    return FirebaseFirestore.instance
        .collection('users')
        .doc(firebaseUser.uid)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return UserModel(
          uid: firebaseUser.uid,
          name: firebaseUser.displayName ?? 'Your name',
          email: firebaseUser.email ?? '',
        );
      }
      return UserModel.fromMap(firebaseUser.uid, snapshot.data()!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: _streamProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Profil tidak dapat dimuat.'));
        }

        final profile = snapshot.data;
        return _ProfileContent(profile: profile);
      },
    );
  }
}

class _ProfileContent extends StatefulWidget {
  const _ProfileContent({required this.profile});

  final UserModel? profile;

  @override
  State<_ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends State<_ProfileContent> {
  final GlobalKey _photosKey = GlobalKey();
  final GlobalKey _verifyKey = GlobalKey();
  final GlobalKey _myLifeKey = GlobalKey();
  final GlobalKey _moreAboutYouKey = GlobalKey();
  final GlobalKey _bioKey = GlobalKey();

  bool _isMyLifeComplete(UserModel? profile) {
    if (profile == null) return false;
    return profile.work.isNotEmpty &&
        profile.education.isNotEmpty &&
        profile.gender.isNotEmpty &&
        profile.location.isNotEmpty &&
        profile.hometown.isNotEmpty;
  }

  bool _isMoreAboutYouComplete(UserModel? profile) {
    if (profile == null) return false;
    return profile.lookingFor.isNotEmpty &&
        profile.relationship.isNotEmpty &&
        profile.haveKids.isNotEmpty &&
        profile.smoking.isNotEmpty &&
        profile.drinking.isNotEmpty &&
        profile.exercise.isNotEmpty &&
        profile.interests.isNotEmpty;
  }

  int _calculatePercentage(UserModel? profile) {
    if (profile == null) return 0;
    int total = 0;

    if (profile.photos.isNotEmpty) total += 10;
    if (profile.isVerified) total += 20;
    if (_isMyLifeComplete(profile)) total += 25;
    if (_isMoreAboutYouComplete(profile)) total += 25;
    if (profile.bio.trim().isNotEmpty) total += 20;

    return total;
  }

  void _handleCompleteProfileTap() {
    final profile = widget.profile;

    if (profile == null || profile.photos.isEmpty) {
      _scrollToSection(_photosKey);
    } else if (!profile.isVerified) {
      _scrollToSection(_verifyKey);
    } else if (!_isMyLifeComplete(profile)) {
      _scrollToSection(_myLifeKey);
    } else if (!_isMoreAboutYouComplete(profile)) {
      _scrollToSection(_moreAboutYouKey);
    } else if (profile.bio.trim().isEmpty) {
      _scrollToSection(_bioKey);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil Anda sudah 100% lengkap! 🎉')),
      );
    }
  }

  void _scrollToSection(GlobalKey key) {
    final targetContext = key.currentContext;
    if (targetContext != null) {
      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final name = profile?.name.isNotEmpty == true ? profile!.name : 'Your name';
    final age = profile?.age ?? 0;
    final ageLabel = age > 0 ? ', $age' : '';
    final bio = profile?.bio ?? '';
    final isVerified = profile?.isVerified ?? false;

    final percentage = _calculatePercentage(profile);
    final percentageLabel = '$percentage% complete';

    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: _handleCompleteProfileTap,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 58,
                    backgroundColor: const Color(0xfff3f3f3),
                    backgroundImage: profile?.photoUrl.isNotEmpty == true
                        ? NetworkImage(profile!.photoUrl)
                        : null,
                    child: profile?.photoUrl.isEmpty != false
                        ? const Icon(
                            Icons.person,
                            size: 67,
                            color: Colors.black45,
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: -8,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '$percentage%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$name$ageLabel',
                    style: const TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 18),
                  OutlinedButton(
                    onPressed: _handleCompleteProfileTap,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.black, width: 1.2),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      minimumSize: const Size(0, 42),
                    ),
                    child: const Text(
                      'Complete profile',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        const _ProfileSectionTitle('Profile strength'),
        const SizedBox(height: 12),
        _ProfileRow(
          icon: Icons.bolt_outlined,
          title: percentageLabel,
          onTap: _handleCompleteProfileTap,
        ),
        const SizedBox(height: 28),
        Container(key: _photosKey),
        const _ProfileSectionTitle('Photos and videos'),
        const _ProfileDescription('Pick some that show the true you.'),
        const SizedBox(height: 14),
        PhotoGrid(userId: profile?.uid ?? ''),
        const SizedBox(height: 28),
        Container(key: _verifyKey),
        _ProfileRow(
          icon: isVerified ? Icons.verified : Icons.verified_outlined,
          title: 'Verify my profile',
          value: isVerified ? 'Verified' : 'Not verified',
          onTap: isVerified
              ? null
              : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          VerificationScreen(userId: profile?.uid ?? ''),
                    ),
                  );
                },
        ),
        const SizedBox(height: 30),
        Container(key: _myLifeKey),
        const _ProfileSectionTitle('My life'),
        const _ProfileDescription(
          'Share where you are in life with your friends.',
        ),
        const SizedBox(height: 14),
        _ProfileRow(
          icon: Icons.work_outline,
          title: 'Work',
          value: profile?.work.isNotEmpty == true ? profile!.work : 'Add',
          onTap: () => _showPlaceholder(context, 'Work'),
        ),
        _ProfileRow(
          icon: Icons.school_outlined,
          title: 'Education',
          value: profile?.education.isNotEmpty == true
              ? profile!.education
              : 'Add',
          onTap: () => _showPlaceholder(context, 'Education'),
        ),
        _ProfileRow(
          icon: Icons.wc_outlined,
          title: 'Gender',
          value: profile?.gender.isNotEmpty == true ? profile!.gender : 'Add',
          onTap: () => _showPlaceholder(context, 'Gender'),
        ),
        _ProfileRow(
          icon: Icons.location_on_outlined,
          title: 'Location',
          value: profile?.location.isNotEmpty == true
              ? profile!.location
              : 'Add',
          onTap: () => _showPlaceholder(context, 'Location'),
        ),
        _ProfileRow(
          icon: Icons.home_outlined,
          title: 'Hometown',
          value: profile?.hometown.isNotEmpty == true
              ? profile!.hometown
              : 'Add',
          onTap: () => _showPlaceholder(context, 'Hometown'),
        ),
        const SizedBox(height: 18),
        Container(key: _moreAboutYouKey),
        const _ProfileSectionTitle('More about you'),
        const _ProfileDescription(
          'Cover the things most people are curious about.',
        ),
        const SizedBox(height: 14),
        _ProfileRow(
          icon: Icons.search,
          title: 'Looking for',
          value: profile?.lookingFor.isNotEmpty == true
              ? profile!.lookingFor
              : 'Add',
          onTap: () => _showPlaceholder(context, 'Looking for'),
        ),
        _ProfileRow(
          icon: Icons.favorite_border,
          title: 'Relationship',
          value: profile?.relationship.isNotEmpty == true
              ? profile!.relationship
              : 'Single',
          onTap: () => _showPlaceholder(context, 'Relationship'),
        ),
        _ProfileRow(
          icon: Icons.child_friendly_outlined,
          title: 'Have kids',
          value: profile?.haveKids.isNotEmpty == true
              ? profile!.haveKids
              : 'Add',
          onTap: () => _showPlaceholder(context, 'Have kids'),
        ),
        _ProfileRow(
          icon: Icons.smoking_rooms_outlined,
          title: 'Smoking',
          value: profile?.smoking.isNotEmpty == true ? profile!.smoking : 'Add',
          onTap: () => _showPlaceholder(context, 'Smoking'),
        ),
        _ProfileRow(
          icon: Icons.wine_bar_outlined,
          title: 'Drinking',
          value: profile?.drinking.isNotEmpty == true
              ? profile!.drinking
              : 'Add',
          onTap: () => _showPlaceholder(context, 'Drinking'),
        ),
        _ProfileRow(
          icon: Icons.fitness_center,
          title: 'Exercise',
          value: profile?.exercise.isNotEmpty == true
              ? profile!.exercise
              : 'Add',
          onTap: () => _showPlaceholder(context, 'Exercise'),
        ),
        _ProfileRow(
          icon: Icons.auto_awesome_mosaic_outlined,
          title: 'Interests',
          value: profile?.interests.isNotEmpty == true
              ? profile!.interests
              : 'Add',
          onTap: () => _showPlaceholder(context, 'Interests'),
        ),
        const SizedBox(height: 24),
        Container(key: _bioKey),
        const _ProfileSectionTitle('Bio'),
        const _ProfileDescription('Write a fun and punchy intro.'),
        const SizedBox(height: 14),
        Container(
          constraints: const BoxConstraints(minHeight: 110),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xffdddddd), width: 1.5),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            bio.isNotEmpty ? bio : 'A little bit about you...',
            style: TextStyle(
              color: bio.isNotEmpty ? Colors.black : Colors.black54,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  static void _showPlaceholder(BuildContext context, String title) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$title belum tersedia.')));
  }
}

class _ProfileSectionTitle extends StatelessWidget {
  const _ProfileSectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
    );
  }
}

class _ProfileDescription extends StatelessWidget {
  const _ProfileDescription(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black54,
          fontSize: 16,
          height: 1.4,
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.title,
    this.onTap,
    this.value,
  });

  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 29, color: Colors.black),
            const SizedBox(width: 22),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 17, color: Colors.black),
              ),
            ),
            Text(
              value ?? '',
              style: TextStyle(
                color: value == 'Add' ? Colors.black54 : Colors.black,
                fontSize: 17,
                fontWeight: isDisabled ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 16),
            if (!isDisabled)
              const Icon(Icons.arrow_forward_ios, size: 20)
            else
              const SizedBox(width: 20),
          ],
        ),
      ),
    );
  }
}