import 'package:flutter/material.dart';

import 'package:bumble/features/chat/services/chat_service.dart';
import 'package:bumble/core/services/safety_service.dart';
import 'package:bumble/core/theme/app_theme.dart';

class BlockedAccountsScreen extends StatefulWidget {
  const BlockedAccountsScreen({super.key});
  @override
  State<BlockedAccountsScreen> createState() => _BlockedAccountsScreenState();
}

class _BlockedAccountsScreenState extends State<BlockedAccountsScreen> {
  final _safety = SafetyService();
  late final _blocks = _safety.watchBlocks();
  final Set<String> _busy = {};
  final Map<String, Future<Map<String, dynamic>?>> _profiles = {};
  Future<void> _unblock(String uid, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Buka block $name?'),
        content: const Text(
          'Jika akun tersebut tidak memblokirmu, chat lama akan tersedia kembali.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Buka block'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy.add(uid));
    try {
      await _safety.unblockUser(uid);
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Block gagal dibuka. Coba lagi.')),
        );
    } finally {
      if (mounted) setState(() => _busy.remove(uid));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: kBumbleYellow,
      title: const Text('Akun diblokir'),
    ),
    body: StreamBuilder(
      stream: _blocks,
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return const Center(child: Text('Daftar block gagal dimuat.'));
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final blocks = snapshot.data!.docs
            .where((doc) => doc.data()['blockerId'] == _safety.uid)
            .toList();
        if (blocks.isEmpty)
          return const Center(child: Text('Kamu belum memblokir akun.'));
        return ListView.builder(
          itemCount: blocks.length,
          itemBuilder: (context, index) {
            final uid = blocks[index].data()['blockedId'] as String;
            return FutureBuilder<Map<String, dynamic>?>(
              future: _profiles.putIfAbsent(
                uid,
                () => ChatService().getUserData(uid),
              ),
              builder: (context, profile) {
                final name = profile.data?['name'] as String? ?? 'Pengguna';
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: kBumbleYellow,
                    child: Icon(Icons.block, color: Colors.black),
                  ),
                  title: Text(name),
                  subtitle: const Text('Akun diblokir'),
                  trailing: TextButton(
                    onPressed: _busy.contains(uid)
                        ? null
                        : () => _unblock(uid, name),
                    child: Text(_busy.contains(uid) ? '...' : 'Buka block'),
                  ),
                );
              },
            );
          },
        );
      },
    ),
  );
}
