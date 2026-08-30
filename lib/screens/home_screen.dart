import 'package:flutter/material.dart';

import '../services/auth_service.dart';
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

  final List<Widget> _pages = [
    const SizedBox(),
    const Center(child: Text('Halaman ini masih dalam pengerjaan!.')),
    const Center(child: Text('Halaman ini masih dalam pengerjaan!.')),
    const ChatListScreen(),
  ];

  Future<void> _handleLogout(BuildContext context) async {
    final authService = AuthService();
    await authService.logout();
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

  @override
  Widget build(BuildContext context) {
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
      body: SafeArea(
        child: _pages[_selectedIndex],
      ),
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
