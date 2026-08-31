import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class PresenceService {
  final _rtdb = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://bumble-clone-project-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  void initPresence() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userStatusRef = _rtdb.ref('status/${user.uid}');
    final connectedRef = _rtdb.ref('.info/connected');

    connectedRef.onValue.listen((event) {
      final connected = event.snapshot.value as bool? ?? false;
      if (!connected) return;

      userStatusRef.onDisconnect().set({
        'online': false,
        'lastSeen': ServerValue.timestamp,
      });

      userStatusRef.set({'online': true, 'lastSeen': ServerValue.timestamp});
    });
  }

  Stream<Map<String, dynamic>> watchUserStatus(String uid) {
    return _rtdb.ref('status/$uid').onValue.map((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) return {'online': false, 'lastSeen': null};
      return Map<String, dynamic>.from(data);
    });
  }
}
