import 'package:cloud_firestore/cloud_firestore.dart';

class MassageModel {
  final String id;
  final String senderId;
  final String text;
  final DateTime? timestamp;

  MassageModel({
    required this.id,
    required this.senderId,
    required this.text,
    this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'seenderId': senderId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  factory MassageModel.fromMap(String id, Map<String, dynamic> map) {
    return MassageModel(
      id: id,
      senderId: map['seenderId'] ?? '',
      text: map['text'] ?? '',
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : null,
    );
  }
}
