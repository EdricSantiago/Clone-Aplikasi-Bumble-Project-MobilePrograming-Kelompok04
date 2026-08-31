import 'package:flutter/material.dart';

import '../models/match_model.dart';
import '../services/chat_service.dart';
import '../services/presence_service.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  Stream<Map<String, dynamic>> _presenceStream(String uid) {
    return PresenceService().watchUserStatus(uid);
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _chatService.currentUserId;

    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: StreamBuilder<List<MatchModel>>(
        stream: _chatService.getMatches(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
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
                future: _chatService.getUserData(otherUserId),
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
                              final isOnline = snapshot.data?['online'] == true;
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
