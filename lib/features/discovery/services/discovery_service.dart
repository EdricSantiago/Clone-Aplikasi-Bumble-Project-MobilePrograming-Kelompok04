import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:bumble/core/utils/combined_stream.dart';
import 'package:bumble/features/discovery/models/discovery_filter.dart';
import 'package:bumble/core/models/user_model.dart';
import 'package:bumble/core/services/safety_service.dart';

class DiscoveryData {
  final List<UserModel> people;
  final List<UserModel> likedYou;
  final DiscoveryFilter filter;
  const DiscoveryData(this.people, this.likedYou, this.filter);
}

class DiscoveryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  Stream<DiscoveryData> watchDiscovery() {
    final profiles = _db.collection('users').snapshots();
    final swipes = _db
        .collection('users')
        .doc(uid)
        .collection('swipes')
        .snapshots();
    final likes = _db
        .collection('users')
        .doc(uid)
        .collection('likes')
        .snapshots();
    final preferences = _db
        .collection('users')
        .doc(uid)
        .collection('preferences')
        .doc('discovery')
        .snapshots();
    final profileAndSwipes = combineStreams(profiles, swipes, (a, b) => (a, b));
    final likesAndBlocks = combineStreams(
      likes,
      SafetyService().watchHiddenUserIds(),
      (a, b) => (a, b),
    );
    final sources = combineStreams(
      profileAndSwipes,
      likesAndBlocks,
      (a, b) => (a, b),
    );
    return combineStreams(sources, preferences, (source, prefs) {
      final allProfiles = source.$1.$1.docs
          .map((doc) => UserModel.fromMap(doc.id, doc.data()))
          .where((user) => user.uid != uid && !source.$2.$2.contains(user.uid))
          .toList();
      final swipedIds = source.$1.$2.docs.map((doc) => doc.id).toSet();
      final incomingIds = source.$2.$1.docs.map((doc) => doc.id).toSet();
      final filter = DiscoveryFilter.fromMap(prefs.data() ?? {});
      return DiscoveryData(
        allProfiles
            .where(
              (user) => !swipedIds.contains(user.uid) && filter.matches(user),
            )
            .toList(),
        allProfiles
            .where(
              (user) =>
                  incomingIds.contains(user.uid) &&
                  !swipedIds.contains(user.uid),
            )
            .toList(),
        filter,
      );
    });
  }

  Future<void> saveFilter(DiscoveryFilter filter) => _db
      .collection('users')
      .doc(uid)
      .collection('preferences')
      .doc('discovery')
      .set(filter.toMap());

  /// Also used for "Like balik". A transaction keeps the swipe, incoming like
  /// and deterministic match together, including simultaneous mutual likes.
  Future<String?> swipe(String otherUid, {required bool like}) async {
    if (otherUid == uid || otherUid.isEmpty)
      throw StateError('Akun tidak valid.');
    final ids = [uid, otherUid]..sort();
    final matchId = ids.join('_');
    return _db.runTransaction<String?>((transaction) async {
      final ownBlock = await transaction.get(
        _db.collection('blocks').doc('${uid}_$otherUid'),
      );
      final otherBlock = await transaction.get(
        _db.collection('blocks').doc('${otherUid}_$uid'),
      );
      if (ownBlock.exists || otherBlock.exists)
        throw StateError('Akun sudah diblokir.');
      final reciprocal = await transaction.get(
        _db.collection('users').doc(otherUid).collection('swipes').doc(uid),
      );
      final matchRef = _db.collection('matches').doc(matchId);
      // Only read an existing room when mutual likes prove membership.
      final mutual = like && reciprocal.data()?['action'] == 'like';
      final existingMatch = mutual ? await transaction.get(matchRef) : null;
      transaction.set(
        _db.collection('users').doc(uid).collection('swipes').doc(otherUid),
        {
          'action': like ? 'like' : 'pass',
          'timestamp': FieldValue.serverTimestamp(),
        },
      );
      if (like) {
        transaction.set(
          _db.collection('users').doc(otherUid).collection('likes').doc(uid),
          {'fromUserId': uid, 'timestamp': FieldValue.serverTimestamp()},
        );
      }
      if (mutual && existingMatch?.exists != true) {
        transaction.set(matchRef, {
          'userIds': ids,
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessage': '',
          'lastMessageAt': FieldValue.serverTimestamp(),
        });
      }
      return mutual ? matchId : null;
    });
  }

  /// Old archives only recorded outgoing swipes. Each account repairs its own
  /// incoming-like copies after login; blocked pairs are deliberately skipped.
  Future<void> syncLegacyLikes() async {
    final swipes = await _db
        .collection('users')
        .doc(uid)
        .collection('swipes')
        .where('action', isEqualTo: 'like')
        .get();
    for (final doc in swipes.docs) {
      if (await SafetyService().isBlocked(doc.id)) continue;
      final ref = _db
          .collection('users')
          .doc(doc.id)
          .collection('likes')
          .doc(uid);
      if (!(await ref.get()).exists) {
        await ref.set({
          'fromUserId': uid,
          'timestamp': doc.data()['timestamp'] ?? FieldValue.serverTimestamp(),
        });
      }
    }
  }
}
