import 'package:cloud_firestore/cloud_firestore.dart';

class MatchModel {
  final String id;
  final List<String> userIds;
  final DateTime? createdAt;
  final String lastMessage;
  final DateTime? lastMessageAt;

  MatchModel({
    required this.id,
    required this.userIds,
    this.createdAt,
    this.lastMessage = '',
    this.lastMessageAt,
  });

  String getOtherUserId(String currentUserId) {
    return userIds.firstWhere((id) => id != currentUserId, orElse: () => '');
  }

  factory MatchModel.fromMap(String id, Map<String, dynamic> map) {
    return MatchModel(
      id: id,
      userIds: List<String>.from(map['userIds'] ?? []),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      lastMessage: map['lastMessage'] ?? '',
      lastMessageAt: map['lastMessageAt'] != null
          ? (map['lastMessageAt'] as Timestamp).toDate()
          : null,
    );
  }
}
