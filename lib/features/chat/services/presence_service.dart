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
  Timer? _retryTimer;
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
    _retryTimer?.cancel();
    _retryTimer = null;
    _currentUid = user.uid;
    _connected = false;
    _pendingUpdate = Future<void>.value();

    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _appActive = _isVisible(lifecycle);
    debugPrint('PRESENCE: mulai status/${user.uid}, visible=$_appActive');
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
            debugPrint('PRESENCE: connected=$_connected, visible=$_appActive');
            if (_connected) {
              _queueStatusUpdate(user.uid, generation);
            } else {
              _retryTimer?.cancel();
              _retryTimer = null;
            }
          },
          onError: (Object error) {
            _logFailure('membaca koneksi', error);
          },
        );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final active = _isVisible(state);
    if (_appActive == active) return;
    _appActive = active;

    final uid = _currentUid;
    if (uid != null && _connected) {
      _queueStatusUpdate(uid, _generation);
    }
  }

  bool _isVisible(AppLifecycleState? state) {
    return state == null ||
        state == AppLifecycleState.resumed ||
        state == AppLifecycleState.inactive;
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
    _retryTimer?.cancel();
    _retryTimer = null;
    _pendingUpdate = _pendingUpdate
        .then((_) async {
          if (!_isCurrentSession(uid, generation) || !_connected) return;

          final statusRef = _rtdb.ref('status/$uid');
          await statusRef
              .onDisconnect()
              .set(_status(false))
              .timeout(_requestTimeout);

          if (!_isCurrentSession(uid, generation) || !_connected) return;
          final online = _appActive;
          await statusRef.set(_status(online)).timeout(_requestTimeout);
          debugPrint('PRESENCE: tersimpan status/$uid online=$online');
        })
        .catchError((Object error, StackTrace stackTrace) {
          _logFailure('memperbarui status', error);
          if (_isCurrentSession(uid, generation) &&
              _connected &&
              !_isPermissionDenied(error)) {
            _retryTimer?.cancel();
            _retryTimer = Timer(const Duration(seconds: 2), () {
              if (_isCurrentSession(uid, generation) && _connected) {
                _queueStatusUpdate(uid, generation);
              }
            });
          }
        });
  }

  bool _isPermissionDenied(Object error) {
    return error is FirebaseException &&
        error.code.toLowerCase().replaceAll('_', '-') == 'permission-denied';
  }

  void _logFailure(String action, Object error) {
    debugPrint('PRESENCE gagal $action: $error');
    if (_isPermissionDenied(error)) {
      debugPrint(
        'PRESENCE: akses ditolak. Periksa Realtime Database > Rules '
        'untuk path status/{uid}.',
      );
    }
  }

  Future<void> goOffline() async {
    final uid = _currentUid;
    final subscription = _connectionSubscription;
    final pendingUpdate = _pendingUpdate;

    ++_generation;
    _retryTimer?.cancel();
    _retryTimer = null;
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
      _logFailure('mengirim status offline', error);
    }
  }

  Stream<Map<String, dynamic>> watchUserStatus(String uid) {
    return _rtdb
        .ref('status/$uid')
        .onValue
        .map((event) {
          final data = event.snapshot.value as Map?;
          if (data == null) return {'online': false, 'lastSeen': null};
          return Map<String, dynamic>.from(data);
        })
        .handleError((Object error, StackTrace stackTrace) {
          _logFailure('membaca status/$uid', error);
          Error.throwWithStackTrace(error, stackTrace);
        });
  }
}
