import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<String?> register({
    required String name,
    required String email,
    required String password,
    required DateTime birthDate,
  }) async {
    if (!isAtLeast18(birthDate)) {
      return 'Anda harus berusia minimal 18 tahun untuk mendaftar.';
    }

    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      UserModel newUser = UserModel(
        uid: result.user!.uid,
        name: name,
        email: email,
        birthDate: birthDate,
      );
      await _firestore
          .collection('users')
          .doc(result.user!.uid)
          .set(newUser.toMap());

      return null;
    } on FirebaseAuthException catch (e) {
      return _mapFirebaseError(e.code);
    } catch (e) {
      return 'Terjadi kesalahan. Coba lagi.';
    }
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapFirebaseError(e.code);
    } catch (e) {
      return 'Terjadi kesalahan. Coba lagi.';
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Email sudah terdaftar. Coba login.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'weak-password':
        return 'Password terlalu lemah (minimal 6 karakter).';
      case 'user-not-found':
        return 'Akun dengan email ini tidak ditemukan.';
      case 'wrong-password':
        return 'Password salah.';
      case 'invalid-credential':
        return 'Email atau password salah.';
      default:
        return 'Gagal: $code';
    }
  }
}
