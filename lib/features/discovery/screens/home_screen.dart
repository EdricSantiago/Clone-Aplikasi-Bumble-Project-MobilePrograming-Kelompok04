import 'package:flutter/material.dart';

import 'package:bumble/core/theme/app_theme.dart';
import 'package:bumble/features/auth/services/auth_service.dart';
import 'package:bumble/features/chat/screens/chat_list_screen.dart';
import 'package:bumble/features/discovery/screens/discovery_filter_screen.dart';
import 'package:bumble/features/discovery/screens/liked_you_screen.dart';
import 'package:bumble/features/discovery/services/discovery_service.dart';
import 'package:bumble/features/discovery/widgets/swipe_card_stack.dart';
import 'package:bumble/features/discovery/widgets/swipeable_card.dart';
import 'package:bumble/features/profile/models/user_model.dart';
import 'package:bumble/features/profile/screens/profile_screen.dart';
import 'package:bumble/features/settings/screens/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _discovery = DiscoveryService();
  late final Stream<DiscoveryData> _stream;
  int _selectedIndex = 1;
  bool _legacySyncFailed = false;
  @override
  void initState() {
    super.initState();
    _stream = _discovery.watchDiscovery();
    _syncLegacyLikes();
  }

  Future<void> _syncLegacyLikes() async {
    try {
      await _discovery.syncLegacyLikes();
      if (mounted) setState(() => _legacySyncFailed = false);
    } catch (_) {
      if (mounted) setState(() => _legacySyncFailed = true);
    }
  }

  Future<void> _recordSwipe(UserModel target, SwipeDirection direction) async {
    final matchId = await _discovery.swipe(
      target.uid,
      like: direction == SwipeDirection.right,
    );
    if (mounted && matchId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kamu match dengan ${target.name}!'),
          action: SnackBarAction(
            label: 'Chats',
            onPressed: () => setState(() => _selectedIndex = 3),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<DiscoveryData>(
    stream: _stream,
    builder: (context, snapshot) {
      final data = snapshot.data;
      final title = ['Profile', 'People', 'Liked You', 'Chats'][_selectedIndex];
      Widget body;
      if (_selectedIndex == 0) {
        body = const ProfileScreen();
      } else if (_selectedIndex == 3) {
        body = const ChatListScreen();
      } else if (snapshot.hasError) {
        body = const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Data gagal dimuat. Periksa koneksi dan Firestore Rules (lihat PANDUAN_FITUR.md).',
              textAlign: TextAlign.center,
            ),
          ),
        );
      } else if (data == null) {
        body = const Center(
          child: CircularProgressIndicator(color: Colors.black),
        );
      } else if (_selectedIndex == 2) {
        body = LikedYouScreen(profiles: data.likedYou);
      } else {
        body = Column(
          children: [
            if (data.filter.isActive)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.tune, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Filter aktif • ${data.filter.minAge}–${data.filter.maxAge} tahun',
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              DiscoveryFilterScreen(initial: data.filter),
                        ),
                      ),
                      child: const Text(
                        'Ubah',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: SwipeCardStack(
                profiles: data.people,
                onSwiped: _recordSwipe,
              ),
            ),
          ],
        );
      }
      return Scaffold(
        backgroundColor: _selectedIndex == 0 || _selectedIndex == 3
            ? Colors.white
            : kBumbleYellow,
        appBar: AppBar(
          backgroundColor: _selectedIndex == 0 ? Colors.white : kBumbleYellow,
          foregroundColor: Colors.black,
          elevation: 0,
          title: Text(
            title,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          actions: [
            if (_selectedIndex == 1)
              IconButton(
                icon: Icon(
                  data?.filter.isActive == true ? Icons.filter_alt : Icons.tune,
                ),
                tooltip: 'Filter matching',
                onPressed: data == null
                    ? null
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              DiscoveryFilterScreen(initial: data.filter),
                        ),
                      ),
              ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Settings',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
            if (_selectedIndex != 0)
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Logout',
                onPressed: () => AuthService().logout(),
              ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (_legacySyncFailed)
                MaterialBanner(
                  content: const Text(
                    'Like lama belum tersinkron. Periksa koneksi dan Firestore Rules.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: _syncLegacyLikes,
                      child: const Text('Coba lagi'),
                    ),
                  ],
                ),
              Expanded(child: body),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.black54,
          backgroundColor: Colors.white,
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
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
    },
  );
}
