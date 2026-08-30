import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../widgets/swipe_card_stack.dart';
import '../widgets/swipeable_card.dart';
import 'profile_screen.dart';
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
    if (index == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      );
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
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
      const SizedBox(),
      _buildPeoplePage(),
      const Center(child: Text('Halaman ini masih dalam pengerjaan!.')),
      const ChatListScreen(),
    ];

    return Scaffold(
      backgroundColor: kBumbleYellow,
      appBar: AppBar(
        backgroundColor: kBumbleYellow,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text(
          'Home',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
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
}
