import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:bumble/features/discovery/models/match_model.dart';
import 'package:bumble/features/chat/models/message_model.dart';
import 'package:bumble/core/utils/combined_stream.dart';
import 'package:bumble/core/services/safety_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  Stream<List<MatchModel>> getMatches() {
    final uid = currentUserId;
    if (uid == null) return const Stream.empty();

    final matches = _firestore
        .collection('matches')
        .where('userIds', arrayContains: uid)
        .snapshots();
    return combineStreams(matches, SafetyService().watchHiddenUserIds(), (
      snapshot,
      blocked,
    ) {
      final rooms = snapshot.docs
          .map((doc) => MatchModel.fromMap(doc.id, doc.data()))
          .where((room) => !blocked.contains(room.getOtherUserId(uid)))
          .toList();
      rooms.sort(
        (a, b) => (b.lastMessageAt ?? b.createdAt ?? DateTime(1970)).compareTo(
          a.lastMessageAt ?? a.createdAt ?? DateTime(1970),
        ),
      );
      return rooms;
    });
  }

  Stream<List<MessageModel>> getMessages(String matchId) {
    return _firestore
        .collection('matches')
        .doc(matchId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MessageModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> sendMessage(String matchId, String text) async {
    final uid = currentUserId;
    if (uid == null || text.trim().isEmpty) return;
    await _send(
      matchId,
      MessageModel(id: '', senderId: uid, text: text.trim()),
      text.trim(),
    );
  }

  Future<void> sendImageMessage(String matchId, String imageUrl) async {
    final uid = currentUserId;
    if (uid == null || imageUrl.isEmpty) return;
    await _send(
      matchId,
      MessageModel(id: '', senderId: uid, text: '', imageUrl: imageUrl),
      '📷 Photo',
    );
  }

  Future<void> ensureCanChat(String matchId) async {
    final doc = await _firestore.collection('matches').doc(matchId).get();
    if (!doc.exists) throw StateError('Match tidak ditemukan.');
    final room = MatchModel.fromMap(doc.id, doc.data()!);
    if (!room.userIds.contains(currentUserId) ||
        await SafetyService().isBlocked(
          room.getOtherUserId(currentUserId ?? ''),
        )) {
      throw StateError('Percakapan tidak tersedia.');
    }
  }

  Future<void> _send(
    String matchId,
    MessageModel message,
    String preview,
  ) async {
    await ensureCanChat(matchId);
    final room = _firestore.collection('matches').doc(matchId);
    final batch = _firestore.batch();
    batch.set(room.collection('messages').doc(), message.toMap());
    batch.update(room, {
      'lastMessage': preview,
      'lastMessageAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<Map<String, dynamic>?> getUserData(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data();
  }

  Future<void> deleteMessage(String matchId, String messageId) async {
    await _firestore
        .collection('matches')
        .doc(matchId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }
}
