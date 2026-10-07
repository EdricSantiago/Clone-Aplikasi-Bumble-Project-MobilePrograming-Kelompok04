import 'package:flutter/material.dart';

import 'package:bumble/core/theme/app_theme.dart';
import 'package:bumble/features/chat/screens/chat_detail_screen.dart';
import 'package:bumble/features/discovery/services/discovery_service.dart';
import 'package:bumble/core/models/user_model.dart';

class LikedYouScreen extends StatefulWidget {
  final List<UserModel> profiles;
  const LikedYouScreen({super.key, required this.profiles});
  @override
  State<LikedYouScreen> createState() => _LikedYouScreenState();
}

class _LikedYouScreenState extends State<LikedYouScreen> {
  final Set<String> _busy = {};
  Future<void> _respond(UserModel profile, bool like) async {
    if (_busy.contains(profile.uid)) return;
    setState(() => _busy.add(profile.uid));
    try {
      final matchId = await DiscoveryService().swipe(profile.uid, like: like);
      if (!mounted) return;
      if (matchId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(
              matchId: matchId,
              otherUserName: profile.name,
              otherUserId: profile.uid,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(like ? 'Like tersimpan.' : 'Profil dilewati.'),
          ),
        );
      }
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilihan gagal disimpan. Coba lagi.')),
        );
    } finally {
      if (mounted) setState(() => _busy.remove(profile.uid));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.profiles.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite_border, size: 68),
              SizedBox(height: 20),
              Text(
                'Belum ada like baru',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 8),
              Text(
                'Orang yang menyukaimu akan muncul di sini. Lengkapi profilmu dan mulai swipe!',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.profiles.length} orang menyukaimu',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Lihat profilnya dan like balik untuk mulai chat.',
                  style: TextStyle(color: Colors.black87),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverLayoutBuilder(
            builder: (context, constraints) => SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: constraints.crossAxisExtent > 650 ? 3 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 310,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final user = widget.profiles[index];
                final photo = user.photoUrl.isNotEmpty
                    ? user.photoUrl
                    : (user.photos.isEmpty ? '' : user.photos.first);
                final busy = _busy.contains(user.uid);
                return Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: SizedBox(
                          width: double.infinity,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (photo.isNotEmpty)
                                Image.network(
                                  photo,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, error, stack) =>
                                      const _PhotoPlaceholder(),
                                )
                              else
                                const _PhotoPlaceholder(),
                              const DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.center,
                                    colors: [
                                      Colors.black54,
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 12,
                                right: 12,
                                bottom: 12,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${user.name}, ${user.age}',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 19,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    if (user.isVerified)
                                      const Icon(
                                        Icons.verified,
                                        color: kBumbleYellow,
                                        size: 20,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                        child: Text(
                          user.location.isEmpty
                              ? 'Menyukai profilmu'
                              : user.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Lewati',
                            onPressed: busy
                                ? null
                                : () => _respond(user, false),
                            icon: const Icon(Icons.close),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: kBumbleYellow,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                ),
                                onPressed: busy
                                    ? null
                                    : () => _respond(user, true),
                                child: Text(
                                  busy ? '...' : 'Like balik',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }, childCount: widget.profiles.length),
            ),
          ),
        ),
      ],
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();
  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFFF0EEE8),
    child: const Center(
      child: Icon(Icons.person_outline, size: 60, color: Colors.black38),
    ),
  );
}
