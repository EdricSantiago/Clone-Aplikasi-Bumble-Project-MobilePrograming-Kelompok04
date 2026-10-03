import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/widgets.dart';

class PresenceService with WidgetsBindingObserver {
  PresenceService._();

  static final PresenceService _instance = PresenceService._();

  factory PresenceService() => _instance;

  static const _requestTimeout = Duration(seconds: 5);

  final _rtdb = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://bumble-clone-project-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  StreamSubscription<DatabaseEvent>? _connectionSubscription;
  Future<void> _pendingUpdate = Future<void>.value();
  String? _currentUid;
  int _generation = 0;
  bool _connected = false;
  bool _appActive = true;
  bool _observingLifecycle = false;

  void initPresence() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      unawaited(goOffline());
      return;
    }

    if (_currentUid == user.uid && _connectionSubscription != null) return;

    final previousSubscription = _connectionSubscription;
    if (previousSubscription != null) {
      unawaited(previousSubscription.cancel());
    }

    final generation = ++_generation;
    _currentUid = user.uid;
    _connected = false;
    _pendingUpdate = Future<void>.value();

    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _appActive = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    if (!_observingLifecycle) {
      WidgetsBinding.instance.addObserver(this);
      _observingLifecycle = true;
    }

    _connectionSubscription = _rtdb
        .ref('.info/connected')
        .onValue
        .listen(
          (event) {
            if (!_isCurrentSession(user.uid, generation)) return;
            _connected = event.snapshot.value == true;
            if (_connected) _queueStatusUpdate(user.uid, generation);
          },
          onError: (Object error) {
            debugPrint('Gagal membaca koneksi presence: $error');
          },
        );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final active = state == AppLifecycleState.resumed;
    if (_appActive == active) return;
    _appActive = active;

    final uid = _currentUid;
    if (uid != null && _connected) {
      _queueStatusUpdate(uid, _generation);
    }
  }

  bool _isCurrentSession(String uid, int generation) {
    return generation == _generation &&
        uid == _currentUid &&
        FirebaseAuth.instance.currentUser?.uid == uid;
  }

  Map<String, Object> _status(bool online) => {
    'online': online,
    'lastSeen': ServerValue.timestamp,
  };

  void _queueStatusUpdate(String uid, int generation) {
    // Serialize writes so a delayed online write cannot overtake an offline one.
    _pendingUpdate = _pendingUpdate
        .then((_) async {
          if (!_isCurrentSession(uid, generation) || !_connected) return;

          final statusRef = _rtdb.ref('status/$uid');
          // The server must acknowledge this fallback before we mark a user online.
          await statusRef
              .onDisconnect()
              .set(_status(false))
              .timeout(_requestTimeout);

          if (!_isCurrentSession(uid, generation) || !_connected) return;
          await statusRef.set(_status(_appActive)).timeout(_requestTimeout);
        })
        .catchError((Object error, StackTrace stackTrace) {
          debugPrint('Gagal memperbarui presence: $error');
        });
  }

  Future<void> goOffline() async {
    final uid = _currentUid;
    final subscription = _connectionSubscription;
    final pendingUpdate = _pendingUpdate;

    // Invalidate callbacks immediately, before waiting for any Firebase request.
    ++_generation;
    _currentUid = null;
    _connected = false;
    _connectionSubscription = null;
    _pendingUpdate = Future<void>.value();

    if (_observingLifecycle) {
      WidgetsBinding.instance.removeObserver(this);
      _observingLifecycle = false;
    }

    try {
      await subscription?.cancel();
      await pendingUpdate;

      if (uid != null && FirebaseAuth.instance.currentUser?.uid == uid) {
        await _rtdb
            .ref('status/$uid')
            .set(_status(false))
            .timeout(_requestTimeout);
      }
    } catch (error) {
      // A lost connection must not prevent logout. The server's onDisconnect
      // handler remains registered as the backup for this case.
      debugPrint('Gagal mengirim status offline: $error');
    }
  }

  Stream<Map<String, dynamic>> watchUserStatus(String uid) {
    return _rtdb.ref('status/$uid').onValue.map((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) return {'online': false, 'lastSeen': null};
      return Map<String, dynamic>.from(data);
    });
  }
}
