import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:bumble/features/auth/screens/login_screen.dart';
import 'package:bumble/features/chat/services/presence_service.dart';
import 'package:bumble/features/discovery/screens/home_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _lastInitializedUid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
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
          if (_lastInitializedUid != user.uid) {
            _lastInitializedUid = user.uid;
            PresenceService().initPresence();
          }
          return HomeScreen(key: ValueKey(user.uid));
        }

        _lastInitializedUid = null;
        return const LoginScreen();
      },
    );
  }
}