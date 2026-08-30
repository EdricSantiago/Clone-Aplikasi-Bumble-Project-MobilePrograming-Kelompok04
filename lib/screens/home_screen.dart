import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../widgets/swipe_card_stack.dart';
import '../widgets/swipeable_card.dart';
import 'settings_screen.dart';
import 'chat_list_screen.dart';

const Color kBumbleYellow = Color(0xFFFFD84D);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 1;

  Future<void> _handleLogout(BuildContext context) async {
    final authService = AuthService();
    await authService.logout();
  }

  Future<void> _recordSwipe(UserModel target, SwipeDirection direction) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final action = direction == SwipeDirection.right ? 'like' : 'pass';

    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('swipes')
        .doc(target.uid)
        .set({'action': action, 'timestamp': FieldValue.serverTimestamp()});
  }

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildProfilePage() {
    return FutureBuilder<UserModel?>(
      future: _loadProfile(),
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

  Future<UserModel?> _loadProfile() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return null;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(firebaseUser.uid)
        .get();

    if (!snapshot.exists) {
      return UserModel(
        uid: firebaseUser.uid,
        name: firebaseUser.displayName ?? 'Your name',
        email: firebaseUser.email ?? '',
      );
    }

    return UserModel.fromMap(firebaseUser.uid, snapshot.data()!);
  }

  Widget _buildPeoplePage() {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Gagal memuat data: ${snapshot.error}'));
        }

        final docs = snapshot.data?.docs ?? [];
        final profiles = docs
            .where((doc) => doc.id != currentUid)
            .map((doc) => UserModel.fromMap(doc.id, doc.data()))
            .toList();

        return SwipeCardStack(profiles: profiles, onSwiped: _recordSwipe);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildProfilePage(),
      _buildPeoplePage(),
      const Center(child: Text('Halaman ini masih dalam pengerjaan!.')),
      const ChatListScreen(),
    ];

    final isProfileTab = _selectedIndex == 0;
    final appBarBgColor = isProfileTab ? Colors.white : kBumbleYellow;
    final bodyBgColor = isProfileTab ? Colors.white : kBumbleYellow;

    return Scaffold(
      backgroundColor: bodyBgColor,
      appBar: AppBar(
        backgroundColor: appBarBgColor,
        elevation: 0,
        foregroundColor: Colors.black,
        title: _selectedIndex == 0
            ? const Text(
                'Profile',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
              )
            : const Text(
                'Home',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
        actions: [
          if (_selectedIndex == 0)
            IconButton(
              icon: const Icon(Icons.help_outline, size: 31),
              tooltip: 'Help',
              onPressed: () => _showMessage(context, 'Help belum tersedia.'),
            ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          if (_selectedIndex != 0)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () => _handleLogout(context),
            ),
        ],
      ),
      body: SafeArea(child: pages[_selectedIndex]),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        backgroundColor: Colors.white,
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt),
            label: 'People',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: 'Liked You',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chats',
          ),
        ],
      ),
    );
  }

  static void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.profile});

  final UserModel? profile;

  @override
  Widget build(BuildContext context) {
    final name = profile?.name.isNotEmpty == true ? profile!.name : 'Your name';
    final age = profile?.age ?? 0;
    final ageLabel = age > 0 ? ', $age' : '';
    final bio = profile?.bio ?? '';

    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
      children: [
        Row(
          children: [
            Stack(
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
                    child: const Text(
                      '10%',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ],
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
                    onPressed: () =>
                        _showPlaceholder(context, 'Complete profile'),
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
        const SizedBox(height: 35),
        SizedBox(
          height: 58,
          child: Row(
            children: [
              _ProfileTab(label: 'BFF', selected: true),
              _ProfileTab(label: 'Date'),
              _ProfileTab(label: 'Bizz'),
            ],
          ),
        ),
        const SizedBox(height: 25),
        const _ProfileSectionTitle('Profile strength'),
        const SizedBox(height: 12),
        _ProfileRow(
          icon: Icons.bolt_outlined,
          title: '10% complete',
          onTap: () => _showPlaceholder(context, 'Profile strength'),
        ),
        const SizedBox(height: 28),
        const _ProfileSectionTitle('Photos and videos'),
        const _ProfileDescription('Pick some that show the true you.'),
        const SizedBox(height: 14),
        const _PhotoGrid(),
        const SizedBox(height: 10),
        const Text(
          'Photo upload is a placeholder for now.',
          style: TextStyle(color: Colors.black54, fontSize: 14),
        ),
        const SizedBox(height: 28),
        _ProfileRow(
          icon: Icons.verified_outlined,
          title: 'Verify my profile',
          value: 'Not verified',
          onTap: () => _showPlaceholder(context, 'Verify my profile'),
        ),
        const SizedBox(height: 30),
        const _ProfileSectionTitle('My life'),
        const _ProfileDescription(
          'Share where you are in life with your friends.',
        ),
        const SizedBox(height: 14),
        _ProfileRow(
          icon: Icons.work_outline,
          title: 'Work',
          value: 'Add',
          onTap: () => _showPlaceholder(context, 'Work'),
        ),
        _ProfileRow(
          icon: Icons.school_outlined,
          title: 'Education',
          value: 'Add',
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
          value: 'Add',
          onTap: () => _showPlaceholder(context, 'Location'),
        ),
        _ProfileRow(
          icon: Icons.home_outlined,
          title: 'Hometown',
          value: 'Add',
          onTap: () => _showPlaceholder(context, 'Hometown'),
        ),
        const SizedBox(height: 18),
        const _ProfileSectionTitle('More about you'),
        const _ProfileDescription(
          'Cover the things most people are curious about.',
        ),
        const SizedBox(height: 14),
        _ProfileRow(
          icon: Icons.search,
          title: 'Looking for',
          value: 'Add',
          onTap: () => _showPlaceholder(context, 'Looking for'),
        ),
        _ProfileRow(
          icon: Icons.favorite_border,
          title: 'Relationship',
          value: 'Single',
          onTap: () => _showPlaceholder(context, 'Relationship'),
        ),
        _ProfileRow(
          icon: Icons.child_friendly_outlined,
          title: 'Have kids',
          value: 'Add',
          onTap: () => _showPlaceholder(context, 'Have kids'),
        ),
        _ProfileRow(
          icon: Icons.smoking_rooms_outlined,
          title: 'Smoking',
          value: 'Add',
          onTap: () => _showPlaceholder(context, 'Smoking'),
        ),
        _ProfileRow(
          icon: Icons.wine_bar_outlined,
          title: 'Drinking',
          value: 'Add',
          onTap: () => _showPlaceholder(context, 'Drinking'),
        ),
        _ProfileRow(
          icon: Icons.fitness_center,
          title: 'Exercise',
          value: 'Add',
          onTap: () => _showPlaceholder(context, 'Exercise'),
        ),
        _ProfileRow(
          icon: Icons.auto_awesome_mosaic_outlined,
          title: 'Interests',
          value: 'Add',
          onTap: () => _showPlaceholder(context, 'Interests'),
        ),
        const SizedBox(height: 24),
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

class _PhotoGrid extends StatelessWidget {
  const _PhotoGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemBuilder: (context, index) => InkWell(
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload foto belum tersedia.')),
        ),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xffdddddd), width: 1.5),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.add, size: 38),
        ),
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: selected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.black, width: 1.1),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
    );
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
    required this.onTap,
    this.value,
  });

  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 29),
            const SizedBox(width: 22),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 17))),
            Text(
              value ?? '',
              style: TextStyle(
                color: value == 'Add' ? Colors.black54 : Colors.black,
                fontSize: 17,
              ),
            ),
            const SizedBox(width: 16),
            const Icon(Icons.arrow_forward_ios, size: 20),
          ],
        ),
      ),
    );
  }
}
