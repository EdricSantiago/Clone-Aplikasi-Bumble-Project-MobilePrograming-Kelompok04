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

  Future<void> setMainProfilePhoto({
    required String userId,
    required String photoUrl,
  }) async {
    final uid = userId.isNotEmpty ? userId : currentUserId;
    if (uid == null || uid.isEmpty) return;

    final userDoc = _firestore.collection('users').doc(uid);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userDoc);
      final data = snapshot.data() ?? {};
      final existingPhotos = (data['photos'] as List<dynamic>? ?? [])
          .map((photo) => photo.toString())
          .where((photo) => photo.isNotEmpty)
          .toList();

      final reorderedPhotos = <String>[
        photoUrl,
        ...existingPhotos.where((p) => p != photoUrl),
      ];

      transaction.set(userDoc, {
        'photos': reorderedPhotos,
        'photoUrl': photoUrl,
      }, SetOptions(merge: true));
    });
  }

  Future<String?> uploadProfilePhoto({
    required String userId,
    required Uint8List imageBytes,
    required String fileName,
    bool setAsMain = false,
  }) async {
    final uid = userId.isNotEmpty ? userId : currentUserId;
    if (uid == null || uid.isEmpty) return null;

    try {
      final existingFiles = await _supabase.storage
          .from(_bucket)
          .list(path: 'profiles/$uid');

      final isDuplicate = existingFiles.any(
        (file) => file.name.toLowerCase() == fileName.toLowerCase(),
      );

      if (isDuplicate) {
        throw Exception("Gagal upload. Foto '$fileName' sudah ada");
      }
    } catch (e) {
      if (e.toString().contains('sudah ada')) {
        rethrow;
      }
    }

    try {
      final processedBytes = _compressImage(imageBytes);
      final path = 'profiles/$uid/$fileName';

      await _supabase.storage
          .from(_bucket)
          .uploadBinary(
            path,
            processedBytes,
            fileOptions: const FileOptions(
              upsert: false,
              contentType: 'image/jpeg',
            ),
          );

      final publicUrl = _supabase.storage.from(_bucket).getPublicUrl(path);
      final userDoc = _firestore.collection('users').doc(uid);

      if (setAsMain) {
        await _firestore.runTransaction((transaction) async {
          final snapshot = await transaction.get(userDoc);
          final data = snapshot.data() ?? {};
          final existingPhotos = (data['photos'] as List<dynamic>? ?? [])
              .map((photo) => photo.toString())
              .where((photo) => photo.isNotEmpty)
              .toList();
          final previousMain = data['photoUrl']?.toString() ?? '';

          final reorderedPhotos = <String>[
            publicUrl,
            if (previousMain.isNotEmpty && previousMain != publicUrl)
              previousMain
            else
              ...[],
          ];

          reorderedPhotos.addAll(
            existingPhotos.where(
              (photo) =>
                  photo != publicUrl &&
                  photo != previousMain &&
                  !reorderedPhotos.contains(photo),
            ),
          );

          transaction.set(userDoc, {
            'photos': reorderedPhotos,
            'photoUrl': publicUrl,
          }, SetOptions(merge: true));
        });
      } else {
        await userDoc.set({
          'photos': FieldValue.arrayUnion([publicUrl]),
        }, SetOptions(merge: true));

        final doc = await userDoc.get();
        final List<dynamic> photos = doc.data()?['photos'] ?? [];
        if (photos.isNotEmpty) {
          await userDoc.update({'photoUrl': photos.first.toString()});
        }
      }

      return publicUrl;
    } catch (e) {
      if (e.toString().contains('sudah ada')) {
        rethrow;
      }
      return null;
    }
  }

  Future<void> deleteProfilePhoto({
    required String userId,
    required String photoUrl,
  }) async {
    final uid = userId.isNotEmpty ? userId : currentUserId;
    if (uid == null || uid.isEmpty) return;

    try {
      await _firestore.collection('users').doc(uid).update({
        'photos': FieldValue.arrayRemove([photoUrl]),
      });

      final uri = Uri.parse(photoUrl);
      final segments = uri.pathSegments;
      final bucketIndex = segments.indexOf(_bucket);
      if (bucketIndex != -1 && bucketIndex + 1 < segments.length) {
        final filePath = segments.sublist(bucketIndex + 1).join('/');
        await _supabase.storage.from(_bucket).remove([filePath]);
      }

      final doc = await _firestore.collection('users').doc(uid).get();
      final List<dynamic> photos = doc.data()?['photos'] ?? [];
      final newMainUrl = photos.isNotEmpty ? photos.first.toString() : '';

      await _firestore.collection('users').doc(uid).update({
        'photoUrl': newMainUrl,
      });
    } catch (_) {}
  }

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