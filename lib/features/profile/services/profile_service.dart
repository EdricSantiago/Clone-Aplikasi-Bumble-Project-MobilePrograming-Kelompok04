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

  Future<void> updateGender({
    required String userId,
    required String gender,
    bool showOnProfile = true,
  }) async {
    final uid = userId.isNotEmpty ? userId : currentUserId;
    if (uid == null || uid.isEmpty) return;

    final valueToSave = showOnProfile ? gender : '';

    await _firestore.collection('users').doc(uid).set({
      'gender': valueToSave,
    }, SetOptions(merge: true));
  }

  Future<void> updateLocation({
    required String userId,
    required String location,
  }) async {
    final uid = userId.isNotEmpty ? userId : currentUserId;
    if (uid == null || uid.isEmpty) return;

    await _firestore.collection('users').doc(uid).set({
      'location': location.trim(),
    }, SetOptions(merge: true));
  }

  Future<void> updateHometown({
    required String userId,
    required String hometown,
  }) async {
    final uid = userId.isNotEmpty ? userId : currentUserId;
    if (uid == null || uid.isEmpty) return;

    await _firestore.collection('users').doc(uid).set({
      'hometown': hometown.trim(),
    }, SetOptions(merge: true));
  }

  Future<void> updateHeight({
    required String userId,
    required String height,
  }) async {
    final uid = userId.isNotEmpty ? userId : currentUserId;
    if (uid == null || uid.isEmpty) return;

    await _firestore.collection('users').doc(uid).set({
      'height': height.trim(),
    }, SetOptions(merge: true));
  }

  Future<void> updateExercise({
    required String userId,
    required String exercise,
  }) async {
    final uid = userId.isNotEmpty ? userId : currentUserId;
    if (uid == null || uid.isEmpty) return;

    await _firestore.collection('users').doc(uid).set({
      'exercise': exercise.trim(),
    }, SetOptions(merge: true));
  }

  Future<void> updateEducationLevel({
    required String userId,
    required String educationLevel,
  }) async {
    final uid = userId.isNotEmpty ? userId : currentUserId;
    if (uid == null || uid.isEmpty) return;

    await _firestore.collection('users').doc(uid).set({
      'educationLevel': educationLevel.trim(),
    }, SetOptions(merge: true));
  }

  Future<void> updateDrinking({
    required String userId,
    required String drinking,
  }) async {
    final uid = userId.isNotEmpty ? userId : currentUserId;
    if (uid == null || uid.isEmpty) return;

    await _firestore.collection('users').doc(uid).set({
      'drinking': drinking.trim(),
    }, SetOptions(merge: true));
  }

  Future<void> updateSmoking({
    required String userId,
    required String smoking,
  }) async {
    final uid = userId.isNotEmpty ? userId : currentUserId;
    if (uid == null || uid.isEmpty) return;

    await _firestore.collection('users').doc(uid).set({
      'smoking': smoking.trim(),
    }, SetOptions(merge: true));
  }

  Future<void> updateHaveKids({
    required String userId,
    required String haveKids,
  }) async {
    final uid = userId.isNotEmpty ? userId : currentUserId;
    if (uid == null || uid.isEmpty) return;

    await _firestore.collection('users').doc(uid).set({
      'haveKids': haveKids.trim(),
    }, SetOptions(merge: true));
  }

  Future<void> updateReligion({
    required String userId,
    required String religion,
  }) async {
    final uid = userId.isNotEmpty ? userId : currentUserId;
    if (uid == null || uid.isEmpty) return;

    await _firestore.collection('users').doc(uid).set({
      'religion': religion.trim(),
    }, SetOptions(merge: true));
  }

  Future<void> updateBio({
    required String userId,
    required String bio,
  }) async {
    final uid = userId.isNotEmpty ? userId : currentUserId;
    if (uid == null || uid.isEmpty) return;

    await _firestore.collection('users').doc(uid).set({
      'bio': bio.trim(),
    }, SetOptions(merge: true));
  }

  Future<void> updateSnoozeMode({
    required String userId,
    required bool isSnoozed,
    String? snoozeDurationText,
    String? snoozeReason,
  }) async {
    final uid = userId.isNotEmpty ? userId : currentUserId;
    if (uid == null || uid.isEmpty) return;

    await _firestore.collection('users').doc(uid).set({
      'isSnoozed': isSnoozed,
      'snoozeDurationText': snoozeDurationText ?? '',
      'snoozeReason': snoozeReason ?? '',
    }, SetOptions(merge: true));
  }

  Stream<List<Map<String, dynamic>>> streamUserEducations(String userId) {
    final uid = userId.isNotEmpty ? userId : currentUserId;
    if (uid == null || uid.isEmpty) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return [];
      final data = snapshot.data()!;
      final List<dynamic> rawEducations = data['educations'] ?? [];
      return rawEducations
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    });
  }

  Future<void> addEducation({
    required String userId,
    required String institution,
    required String graduationYear,
  }) async {
    final uid = userId.isNotEmpty ? userId : currentUserId;
    if (uid == null || uid.isEmpty) return;

    final userDoc = _firestore.collection('users').doc(uid);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userDoc);
      final data = snapshot.data() ?? {};
      final List<dynamic> rawEducations = data['educations'] ?? [];
      final educations = rawEducations
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      if (educations.length >= 10) {
        throw Exception('Max institution has reached');
      }

      final newEdu = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'institution': institution.trim(),
        'graduationYear': graduationYear.trim(),
        'isSelected': educations.isEmpty,
      };

      educations.add(newEdu);

      final selectedEdu = educations.firstWhere(
        (e) => e['isSelected'] == true,
        orElse: () => newEdu,
      );
      final educationLabel =
          '${selectedEdu['institution']}, ${selectedEdu['graduationYear']}';

      transaction.set(userDoc, {
        'educations': educations,
        'education': educationLabel,
      }, SetOptions(merge: true));
    });
  }

  Future<void> updateEducation({
    required String userId,
    required String eduId,
    required String newInstitution,
    required String newGraduationYear,
  }) async {
    final uid = userId.isNotEmpty ? userId : currentUserId;
    if (uid == null || uid.isEmpty) return;

    final userDoc = _firestore.collection('users').doc(uid);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userDoc);
      final data = snapshot.data() ?? {};
      final List<dynamic> rawEducations = data['educations'] ?? [];
      final educations = rawEducations
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      final index = educations.indexWhere((e) => e['id'] == eduId);
      if (index != -1) {
        educations[index]['institution'] = newInstitution.trim();
        educations[index]['graduationYear'] = newGraduationYear.trim();

        final selectedEdu = educations.firstWhere(
          (e) => e['isSelected'] == true,
          orElse: () => educations[index],
        );
        final educationLabel =
            '${selectedEdu['institution']}, ${selectedEdu['graduationYear']}';

        transaction.set(userDoc, {
          'educations': educations,
          'education': educationLabel,
        }, SetOptions(merge: true));
      }
    });
  }

  Future<void> selectEducation({
    required String userId,
    required String eduId,
  }) async {
    final uid = userId.isNotEmpty ? userId : currentUserId;
    if (uid == null || uid.isEmpty) return;

    final userDoc = _firestore.collection('users').doc(uid);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userDoc);
      final data = snapshot.data() ?? {};
      final List<dynamic> rawEducations = data['educations'] ?? [];
      final educations = rawEducations
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      String educationLabel = '';
      for (var e in educations) {
        if (e['id'] == eduId) {
          e['isSelected'] = true;
          educationLabel = '${e['institution']}, ${e['graduationYear']}';
        } else {
          e['isSelected'] = false;
        }
      }

      transaction.set(userDoc, {
        'educations': educations,
        'education': educationLabel,
      }, SetOptions(merge: true));
    });
  }

  Future<void> removeEducation({
    required String userId,
    required String eduId,
  }) async {
    final uid = userId.isNotEmpty ? userId : currentUserId;
    if (uid == null || uid.isEmpty) return;

    final userDoc = _firestore.collection('users').doc(uid);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userDoc);
      final data = snapshot.data() ?? {};
      final List<dynamic> rawEducations = data['educations'] ?? [];
      final educations = rawEducations
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      final removedItem =
          educations.firstWhere((e) => e['id'] == eduId, orElse: () => {});
      final wasSelected = removedItem['isSelected'] == true;

      educations.removeWhere((e) => e['id'] == eduId);

      String educationLabel = '';
      if (educations.isNotEmpty) {
        if (wasSelected) {
          educations.first['isSelected'] = true;
        }
        final selectedEdu = educations.firstWhere((e) => e['isSelected'] == true);
        educationLabel =
            '${selectedEdu['institution']}, ${selectedEdu['graduationYear']}';
      }

      transaction.set(userDoc, {
        'educations': educations,
        'education': educationLabel,
      }, SetOptions(merge: true));
    });
  }

  Stream<List<Map<String, dynamic>>> streamUserJobs(String userId) {
    final uid = userId.isNotEmpty ? userId : currentUserId;
    if (uid == null || uid.isEmpty) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return [];
      final data = snapshot.data()!;
      final List<dynamic> rawJobs = data['jobs'] ?? [];
      return rawJobs.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    });
  }

  Future<void> addJob({
    required String userId,
    required String title,
    required String company,
  }) async {
    final uid = userId.isNotEmpty ? userId : currentUserId;
    if (uid == null || uid.isEmpty) return;

    final userDoc = _firestore.collection('users').doc(uid);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userDoc);
      final data = snapshot.data() ?? {};
      final List<dynamic> rawJobs = data['jobs'] ?? [];
      final jobs = rawJobs.map((e) => Map<String, dynamic>.from(e as Map)).toList();

      if (jobs.length >= 12) {
        throw Exception('Batas maksimal pekerjaan adalah 12.');
      }

      final newJob = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': title.trim(),
        'company': company.trim(),
        'isSelected': jobs.isEmpty,
      };

      jobs.add(newJob);

      final selectedJob = jobs.firstWhere(
        (j) => j['isSelected'] == true,
        orElse: () => newJob,
      );
      final workLabel = '${selectedJob['title']} at ${selectedJob['company']}';

      transaction.set(userDoc, {
        'jobs': jobs,
        'work': workLabel,
      }, SetOptions(merge: true));
    });
  }

  Future<void> updateJob({
    required String userId,
    required String jobId,
    required String newTitle,
    required String newCompany,
  }) async {
    final uid = userId.isNotEmpty ? userId : currentUserId;
    if (uid == null || uid.isEmpty) return;

    final userDoc = _firestore.collection('users').doc(uid);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userDoc);
      final data = snapshot.data() ?? {};
      final List<dynamic> rawJobs = data['jobs'] ?? [];
      final jobs = rawJobs.map((e) => Map<String, dynamic>.from(e as Map)).toList();

      final index = jobs.indexWhere((j) => j['id'] == jobId);
      if (index != -1) {
        jobs[index]['title'] = newTitle.trim();
        jobs[index]['company'] = newCompany.trim();

        final selectedJob = jobs.firstWhere(
          (j) => j['isSelected'] == true,
          orElse: () => jobs[index],
        );
        final workLabel = '${selectedJob['title']} at ${selectedJob['company']}';

        transaction.set(userDoc, {
          'jobs': jobs,
          'work': workLabel,
        }, SetOptions(merge: true));
      }
    });
  }

  Future<void> selectJob({
    required String userId,
    required String jobId,
  }) async {
    final uid = userId.isNotEmpty ? userId : currentUserId;
    if (uid == null || uid.isEmpty) return;

    final userDoc = _firestore.collection('users').doc(uid);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userDoc);
      final data = snapshot.data() ?? {};
      final List<dynamic> rawJobs = data['jobs'] ?? [];
      final jobs = rawJobs.map((e) => Map<String, dynamic>.from(e as Map)).toList();

      String workLabel = '';
      for (var j in jobs) {
        if (j['id'] == jobId) {
          j['isSelected'] = true;
          workLabel = '${j['title']} at ${j['company']}';
        } else {
          j['isSelected'] = false;
        }
      }

      transaction.set(userDoc, {
        'jobs': jobs,
        'work': workLabel,
      }, SetOptions(merge: true));
    });
  }

  Future<void> removeJob({
    required String userId,
    required String jobId,
  }) async {
    final uid = userId.isNotEmpty ? userId : currentUserId;
    if (uid == null || uid.isEmpty) return;

    final userDoc = _firestore.collection('users').doc(uid);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userDoc);
      final data = snapshot.data() ?? {};
      final List<dynamic> rawJobs = data['jobs'] ?? [];
      final jobs = rawJobs.map((e) => Map<String, dynamic>.from(e as Map)).toList();

      final removedItem = jobs.firstWhere((j) => j['id'] == jobId, orElse: () => {});
      final wasSelected = removedItem['isSelected'] == true;

      jobs.removeWhere((j) => j['id'] == jobId);

      String workLabel = '';
      if (jobs.isNotEmpty) {
        if (wasSelected) {
          jobs.first['isSelected'] = true;
        }
        final selectedJob = jobs.firstWhere((j) => j['isSelected'] == true);
        workLabel = '${selectedJob['title']} at ${selectedJob['company']}';
      }

      transaction.set(userDoc, {
        'jobs': jobs,
        'work': workLabel,
      }, SetOptions(merge: true));
    });
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
      final processedBytes = _compressImage(imageBytes);
      final uniqueFileName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
      final path = 'profiles/$uid/$uniqueFileName';

      await _supabase.storage
          .from(_bucket)
          .uploadBinary(
            path,
            processedBytes,
            fileOptions: const FileOptions(
              upsert: true,
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
    } catch (_) {
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