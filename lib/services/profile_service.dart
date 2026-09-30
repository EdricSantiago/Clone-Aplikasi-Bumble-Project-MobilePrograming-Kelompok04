import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _bucket = 'chat-images';

  String? get currentUserId => _auth.currentUser?.uid;

  /// Mengambil daftar URL foto profil milik pengguna dari Firestore
  Future<List<String>> getUserPhotos(String userId) async {
    final uid = userId.isNotEmpty ? userId : currentUserId;
    if (uid == null || uid.isEmpty) return [];

    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return [];

      final data = doc.data();
      if (data == null || !data.containsKey('photos')) return [];

      final List<dynamic> rawPhotos = data['photos'] ?? [];
      return rawPhotos.map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  /// Mengunggah foto ke Supabase Storage dan memperbarui Firestore
  Future<String?> uploadProfilePhoto({
    required String userId,
    required Uint8List imageBytes,
  }) async {
    final uid = userId.isNotEmpty ? userId : currentUserId;
    if (uid == null || uid.isEmpty) return null;

    try {
      final processedBytes = _compressImage(imageBytes);

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$uid.jpg';
      final path = 'profiles/$uid/$fileName';

      await _supabase.storage.from(_bucket).uploadBinary(
            path,
            processedBytes,
            fileOptions: const FileOptions(
              upsert: false,
              contentType: 'image/jpeg',
            ),
          );

      final publicUrl = _supabase.storage.from(_bucket).getPublicUrl(path);

      // Tambahkan URL foto ke daftar 'photos' di Firestore
      await _firestore.collection('users').doc(uid).set({
        'photos': FieldValue.arrayUnion([publicUrl]),
      }, SetOptions(merge: true));

      // Ambil daftar foto terbaru untuk memastikan foto pertama diset sebagai 'photoUrl' utama
      final doc = await _firestore.collection('users').doc(uid).get();
      final List<dynamic> photos = doc.data()?['photos'] ?? [];
      if (photos.isNotEmpty) {
        await _firestore.collection('users').doc(uid).update({
          'photoUrl': photos.first.toString(),
        });
      }

      return publicUrl;
    } catch (_) {
      return null;
    }
  }

  /// Menghapus foto dari Supabase Storage dan memperbarui Firestore
  Future<void> deleteProfilePhoto({
    required String userId,
    required String photoUrl,
  }) async {
    final uid = userId.isNotEmpty ? userId : currentUserId;
    if (uid == null || uid.isEmpty) return;

    try {
      // Hapus dari array 'photos' di Firestore
      await _firestore.collection('users').doc(uid).update({
        'photos': FieldValue.arrayRemove([photoUrl]),
      });

      // Hapus file fisik dari Supabase Storage
      final uri = Uri.parse(photoUrl);
      final segments = uri.pathSegments;
      final bucketIndex = segments.indexOf(_bucket);
      if (bucketIndex != -1 && bucketIndex + 1 < segments.length) {
        final filePath = segments.sublist(bucketIndex + 1).join('/');
        await _supabase.storage.from(_bucket).remove([filePath]);
      }

      // Perbarui 'photoUrl' utama dengan foto pertama yang tersisa (jika ada)
      final doc = await _firestore.collection('users').doc(uid).get();
      final List<dynamic> photos = doc.data()?['photos'] ?? [];
      final newMainUrl = photos.isNotEmpty ? photos.first.toString() : '';

      await _firestore.collection('users').doc(uid).update({
        'photoUrl': newMainUrl,
      });
    } catch (_) {}
  }

  /// Memperbarui status verifikasi akun di Firestore
  Future<void> verifyProfile(String userId) async {
    final uid = userId.isNotEmpty ? userId : currentUserId;
    if (uid == null || uid.isEmpty) return;

    await _firestore.collection('users').doc(uid).set({
      'isVerified': true,
    }, SetOptions(merge: true));
  }

  Uint8List _compressImage(Uint8List bytes) {
    final image = img.decodeImage(bytes);
    if (image == null) return bytes;

    final resized = image.width > 1080
        ? img.copyResize(image, width: 1080)
        : image;

    return Uint8List.fromList(img.encodeJpg(resized, quality: 75));
  }
}