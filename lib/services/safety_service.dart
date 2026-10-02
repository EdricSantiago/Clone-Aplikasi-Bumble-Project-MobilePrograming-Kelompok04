import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SafetyService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  static const reportReasons = [
    'Ucapan menyinggung / pelecehan',
    'Ancaman atau kekerasan',
    'Konten seksual yang tidak diinginkan',
    'Penipuan / spam',
    'Akun palsu',
    'Pengguna di bawah umur',
    'Lainnya',
  ];

  Stream<QuerySnapshot<Map<String, dynamic>>> watchBlocks() =>
      _db.collection('blocks').where('userIds', arrayContains: uid).snapshots();

  Stream<Set<String>> watchHiddenUserIds() => watchBlocks().map(
    (snapshot) => snapshot.docs.map((doc) {
      final data = doc.data();
      return data['blockerId'] == uid
          ? data['blockedId'] as String
          : data['blockerId'] as String;
    }).toSet(),
  );

  Future<bool> isBlocked(String otherUid) async {
    final own = await _db.collection('blocks').doc('${uid}_$otherUid').get();
    final other = await _db.collection('blocks').doc('${otherUid}_$uid').get();
    return own.exists || other.exists;
  }

  Map<String, dynamic> _blockData(String otherUid) => {
    'blockerId': uid,
    'blockedId': otherUid,
    'userIds': [uid, otherUid],
    'createdAt': FieldValue.serverTimestamp(),
  };

  Future<void> blockUser(String otherUid) async {
    if (otherUid == uid || otherUid.isEmpty)
      throw StateError('Akun tidak valid.');
    await _db
        .collection('blocks')
        .doc('${uid}_$otherUid')
        .set(_blockData(otherUid));
  }

  Future<void> unblockUser(String otherUid) =>
      _db.collection('blocks').doc('${uid}_$otherUid').delete();

  Future<void> reportUser({
    required String otherUid,
    required String reason,
    required String details,
    String? matchId,
    String? messageId,
    bool alsoBlock = false,
  }) async {
    if (otherUid.isEmpty ||
        otherUid == uid ||
        !reportReasons.contains(reason)) {
      throw StateError('Laporan tidak valid.');
    }
    final batch = _db.batch();
    batch.set(_db.collection('reports').doc(), {
      'reporterId': uid,
      'reportedId': otherUid,
      'reason': reason,
      'details': details.trim(),
      'matchId': matchId,
      'messageId': messageId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (alsoBlock) {
      batch.set(
        _db.collection('blocks').doc('${uid}_$otherUid'),
        _blockData(otherUid),
      );
    }
    await batch.commit();
  }
}
