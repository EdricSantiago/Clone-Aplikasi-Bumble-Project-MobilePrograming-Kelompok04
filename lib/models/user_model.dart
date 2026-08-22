import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final DateTime? birthDate;
  final String bio;
  final String photoUrl;
  final String gender;
  final String interestedIn;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.birthDate,
    this.bio = '',
    this.photoUrl = '',
    this.gender = '',
    this.interestedIn = '',
  });

  int get age {
    if (birthDate == null) return 0;
    final today = DateTime.now();
    int calculatedAge = today.year - birthDate!.year;
    if (today.month < birthDate!.month ||
        (today.month == birthDate!.month && today.day < birthDate!.day)) {
      calculatedAge--;
    }
    return calculatedAge;
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
      'bio': bio,
      'photoUrl': photoUrl,
      'gender': gender,
      'interestedIn': interestedIn,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      birthDate: map['birthDate'] != null
          ? (map['birthDate'] as Timestamp).toDate()
          : null,
      bio: map['bio'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      gender: map['gender'] ?? '',
      interestedIn: map['interestedIn'] ?? '',
    );
  }
}

bool isAtLeast18(DateTime birthDate) {
  final today = DateTime.now();
  int age = today.year - birthDate.year;
  if (today.month < birthDate.month ||
      (today.month == birthDate.month && today.day < birthDate.day)) {
    age--;
  }
  return age >= 18;
}
