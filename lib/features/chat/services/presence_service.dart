import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

class PresenceService {
  final _rtdb = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://bumble-clone-project-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  StreamSubscription<DatabaseEvent>? _connectionSubscription;
  String? _currentUid;

  void initPresence() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_currentUid == user.uid && _connectionSubscription != null) return;

    _connectionSubscription?.cancel();
    _currentUid = user.uid;

    final userStatusRef = _rtdb.ref('status/${user.uid}');
    final connectedRef = _rtdb.ref('.info/connected');

    _connectionSubscription = connectedRef.onValue.listen((event) {
      final connected = event.snapshot.value as bool? ?? false;
      if (!connected) return;

      userStatusRef.onDisconnect().set({
        'online': false,
        'lastSeen': ServerValue.timestamp,
      });

      userStatusRef.set({'online': true, 'lastSeen': ServerValue.timestamp});
    });
  }

  Future<void> goOffline() async {
    final uid = _currentUid;
    if (uid != null) {
      await _rtdb.ref('status/$uid').set({
        'online': false,
        'lastSeen': ServerValue.timestamp,
      });
    }
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;
    _currentUid = null;
  }

  Stream<Map<String, dynamic>> watchUserStatus(String uid) {
    return _rtdb.ref('status/$uid').onValue.map((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) return {'online': false, 'lastSeen': null};
      return Map<String, dynamic>.from(data);
    });
  }
}