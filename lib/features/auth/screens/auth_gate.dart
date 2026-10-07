import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:bumble/features/discovery/screens/home_screen.dart';
import 'package:bumble/features/auth/screens/login_screen.dart';
import 'package:bumble/features/chat/services/presence_service.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _presence = PresenceService();
  late final Stream<User?> _authStateStream;
  late final StreamSubscription<User?> _presenceSubscription;

  @override
  void initState() {
    super.initState();
    _authStateStream = FirebaseAuth.instance.authStateChanges();
    _presenceSubscription = _authStateStream.listen(
      (user) {
        if (user == null) {
          unawaited(_presence.goOffline());
        } else {
          _presence.initPresence();
        }
      },
      onError: (Object error) {
        debugPrint('Gagal memantau sesi presence: $error');
      },
    );
  }

  @override
  void dispose() {
    unawaited(_presenceSubscription.cancel());
    unawaited(_presence.goOffline());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authStateStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Terjadi kesalahan: ${snapshot.error}')),
          );
        }

        final User? user = snapshot.data;

        if (user != null) {
          return HomeScreen(key: ValueKey(user.uid));
        }

        return const LoginScreen();
      },
    );
  }
}
