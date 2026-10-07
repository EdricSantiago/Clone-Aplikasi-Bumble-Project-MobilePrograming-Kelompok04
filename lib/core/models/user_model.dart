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
  final bool isVerified;
  final List<String> photos;

  final String work;
  final String education;
  final String location;
  final String hometown;

  final String lookingFor;
  final String relationship;
  final String haveKids;
  final String smoking;
  final String drinking;
  final String exercise;
  final String interests;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.birthDate,
    this.bio = '',
    this.photoUrl = '',
    this.gender = '',
    this.interestedIn = '',
    this.isVerified = false,
    this.photos = const [],
    this.work = '',
    this.education = '',
    this.location = '',
    this.hometown = '',
    this.lookingFor = '',
    this.relationship = '',
    this.haveKids = '',
    this.smoking = '',
    this.drinking = '',
    this.exercise = '',
    this.interests = '',
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
      'isVerified': isVerified,
      'photos': photos,
      'work': work,
      'education': education,
      'location': location,
      'hometown': hometown,
      'lookingFor': lookingFor,
      'relationship': relationship,
      'haveKids': haveKids,
      'smoking': smoking,
      'drinking': drinking,
      'exercise': exercise,
      'interests': interests,
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
      isVerified: map['isVerified'] ?? false,
      photos: List<String>.from(map['photos'] ?? []),
      work: map['work'] ?? '',
      education: map['education'] ?? '',
      location: map['location'] ?? '',
      hometown: map['hometown'] ?? '',
      lookingFor: map['lookingFor'] ?? '',
      relationship: map['relationship'] ?? '',
      haveKids: map['haveKids'] ?? '',
      smoking: map['smoking'] ?? '',
      drinking: map['drinking'] ?? '',
      exercise: map['exercise'] ?? '',
      interests: map['interests'] ?? '',
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