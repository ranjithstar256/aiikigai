import 'package:cloud_firestore/cloud_firestore.dart';

class Answer {
  final String id;
  final String sectionId;
  final String questionId;
  final String text;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Answer({
    required this.id,
    required this.sectionId,
    required this.questionId,
    required this.text,
    required this.userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Generate ID for local storage
  static String generateId(String sectionId, String questionId) {
    return '${sectionId}_$questionId';
  }

  // Convert to map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sectionId': sectionId,
      'questionId': questionId,
      'text': text,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from map
  factory Answer.fromMap(Map<String, dynamic> map) {
    return Answer(
      id: map['id'],
      sectionId: map['sectionId'],
      questionId: map['questionId'],
      text: map['text'],
      userId: map['userId'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  // Create from Firestore document
  factory Answer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Answer(
      id: doc.id,
      sectionId: data['sectionId'] ?? '',
      questionId: data['questionId'] ?? '',
      text: data['text'] ?? '',
      userId: data['userId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Convert to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'sectionId': sectionId,
      'questionId': questionId,
      'text': text,
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // Copy with
  Answer copyWith({
    String? id,
    String? sectionId,
    String? questionId,
    String? text,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Answer(
      id: id ?? this.id,
      sectionId: sectionId ?? this.sectionId,
      questionId: questionId ?? this.questionId,
      text: text ?? this.text,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}