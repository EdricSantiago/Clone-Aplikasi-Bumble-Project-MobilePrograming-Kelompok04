import 'package:flutter/material.dart';

import '../models/match_model.dart';
import '../services/chat_service.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();

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
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange,
                      child: Text(
                        otherUserName.isNotEmpty
                            ? otherUserName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(color: Colors.white),
                      ),
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
