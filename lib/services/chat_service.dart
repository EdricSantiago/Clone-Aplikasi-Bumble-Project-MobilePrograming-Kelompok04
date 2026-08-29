import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/massage_model.dart';
import '../models/match_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  Stream<List<MatchModel>> getMatches() {
    final uid = currentUserId;
    if (uid == null) return const Stream.empty();

    return _firestore
        .collection('matches')
        .where('userIds', arrayContains: uid)
        .orderBy('lastMassageAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MatchModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> sendMassage(String matchId, String text) async {
    final uid = currentUserId;
    if (uid == null || text.trim().isEmpty) return;

    final massage = MassageModel(id: '', senderId: uid, text: text.trim());

    await _firestore
        .collection('matches')
        .doc(matchId)
        .collection('massages')
        .add(massage.toMap());

    await _firestore.collection('matches').doc(matchId).update({
      'lastMassage': text.trim(),
      'lastMassageAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>?> getUserData(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data();
  }
}
