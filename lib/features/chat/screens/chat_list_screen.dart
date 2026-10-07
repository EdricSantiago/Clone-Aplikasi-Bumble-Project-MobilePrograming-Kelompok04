import 'package:flutter/material.dart';

import 'package:bumble/features/chat/screens/chat_detail_screen.dart';
import 'package:bumble/features/chat/services/chat_service.dart';
import 'package:bumble/features/chat/services/presence_service.dart';
import 'package:bumble/features/discovery/models/match_model.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  late final _matches = _chatService.getMatches();
  final Map<String, Stream<Map<String, dynamic>>> _presenceCache = {};

  final Map<String, Future<Map<String, dynamic>?>> _userDataCache = {};

  Future<Map<String, dynamic>?> _getCachedUserData(String uid) {
    if (uid.isEmpty) return Future.value(null);
    return _userDataCache.putIfAbsent(uid, () => _chatService.getUserData(uid));
  }

  Stream<Map<String, dynamic>> _presenceStream(String uid) {
    return _presenceCache.putIfAbsent(
      uid,
      () => PresenceService().watchUserStatus(uid),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _chatService.currentUserId;

    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: StreamBuilder<List<MatchModel>>(
        stream: _matches,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Chat gagal dimuat. Coba lagi.'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Belum ada chat tersedia!.'));
          }

          final matches = snapshot.data!;

          return ListView.builder(
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];
              final otherUserId = match.getOtherUserId(currentUserId ?? '');

              return FutureBuilder<Map<String, dynamic>?>(
                future: _getCachedUserData(otherUserId),
                builder: (context, userSnapshot) {
                  final otherUserName =
                      userSnapshot.data?['name'] ?? 'Memuat...';

                  return ListTile(
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.orange,
                          child: Text(
                            otherUserName.isNotEmpty
                                ? otherUserName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: StreamBuilder<Map<String, dynamic>>(
                            stream: otherUserId.isEmpty
                                ? const Stream.empty()
                                : _presenceStream(otherUserId),
                            builder: (context, snapshot) {
                              final isOnline =
                                  !snapshot.hasError &&
                                  snapshot.data?['online'] == true;
                              return Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: isOnline ? Colors.green : Colors.grey,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    title: Text(otherUserName),
                    subtitle: Text(
                      match.lastMessage.isEmpty
                          ? 'Mulai percakapan'
                          : match.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatDetailScreen(
                            matchId: match.id,
                            otherUserName: otherUserName,
                            otherUserId: otherUserId,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
