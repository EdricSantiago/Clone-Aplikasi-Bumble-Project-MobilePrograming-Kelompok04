import 'user_model.dart';

class DiscoveryFilter {
  static const genderOptions = ['Semua', 'Man', 'Woman', 'Non-binary'];
  static const relationshipOptions = [
    'Semua',
    'Long-term relationship',
    'Casual dating',
    'Friendship',
    'Still figuring it out',
  ];

  final int minAge;
  final int maxAge;
  final String gender;
  final String location;
  final String lookingFor;
  final bool verifiedOnly;

  const DiscoveryFilter({
    this.minAge = 18,
    this.maxAge = 100,
    this.gender = 'Semua',
    this.location = '',
    this.lookingFor = 'Semua',
    this.verifiedOnly = false,
  });

  bool get isActive =>
      minAge != 18 ||
      maxAge != 100 ||
      gender != 'Semua' ||
      location.trim().isNotEmpty ||
      lookingFor != 'Semua' ||
      verifiedOnly;

  static String normalizeGender(String value) {
    switch (value.trim().toLowerCase()) {
      case 'male':
      case 'man':
      case 'pria':
      case 'laki-laki':
        return 'Man';
      case 'female':
      case 'woman':
      case 'wanita':
      case 'perempuan':
        return 'Woman';
      case 'non-binary':
      case 'nonbinary':
        return 'Non-binary';
      default:
        return value.trim();
    }
  }

  bool matches(UserModel user) =>
      user.age >= minAge &&
      user.age <= maxAge &&
      (gender == 'Semua' || normalizeGender(user.gender) == gender) &&
      (location.trim().isEmpty ||
          user.location.toLowerCase().contains(
            location.trim().toLowerCase(),
          )) &&
      (lookingFor == 'Semua' ||
          user.lookingFor.trim().toLowerCase() == lookingFor.toLowerCase()) &&
      (!verifiedOnly || user.isVerified);

  Map<String, dynamic> toMap() => {
    'minAge': minAge,
    'maxAge': maxAge,
    'gender': gender,
    'location': location.trim(),
    'lookingFor': lookingFor,
    'verifiedOnly': verifiedOnly,
  };

  factory DiscoveryFilter.fromMap(Map<String, dynamic> map) {
    final min = (map['minAge'] as num? ?? 18).toInt().clamp(18, 100).toInt();
    final max = (map['maxAge'] as num? ?? 100).toInt().clamp(min, 100).toInt();
    return DiscoveryFilter(
      minAge: min,
      maxAge: max,
      gender: genderOptions.contains(map['gender'])
          ? map['gender'] as String
          : 'Semua',
      location: map['location'] as String? ?? '',
      lookingFor: relationshipOptions.contains(map['lookingFor'])
          ? map['lookingFor'] as String
          : 'Semua',
      verifiedOnly: map['verifiedOnly'] == true,
    );
  }
}
