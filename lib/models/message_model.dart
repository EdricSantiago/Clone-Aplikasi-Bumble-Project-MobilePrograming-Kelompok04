import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final String? imageUrl;
  final DateTime? timestamp;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    this.imageUrl,
    this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      if (imageUrl != null) 'imageUrl' : imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  factory MessageModel.fromMap(String id, Map<String, dynamic> map) {
    return MessageModel(
      id: id,
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      imageUrl: map['imageUrl'],
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : null,
    );
  }
}
