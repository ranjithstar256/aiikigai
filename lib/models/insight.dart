import 'package:cloud_firestore/cloud_firestore.dart';

class Insight {
  final String id;
  final String userId;
  final Map<String, dynamic> data;
  final bool isPremium;
  final DateTime createdAt;

  Insight({
    required this.id,
    required this.userId,
    required this.data,
    this.isPremium = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Getters for common insight fields
  List<String> get topGoodAt =>
      _getListFromField('top_good_at');

  List<String> get topStrengths =>
      _getListFromField('top_strengths');

  List<String> get topPaidFor =>
      _getListFromField('top_paid_for');

  List<String> get topWorldNeeds =>
      _getListFromField('top_world_needs');

  List<String> get getStartedPlan =>
      _getListFromField('get_started_plan');

  List<String> get whatYouAreMissing =>
      _getListFromField('what_you_are_missing');

  Map<String, List<String>> get futureOutlook {
    try {
      final outlook = data['future_outlook'] as Map<String, dynamic>;
      return {
        'next_5_years': _parseStringToList(outlook['next_5_years']),
        'next_30_years': _parseStringToList(outlook['next_30_years']),
      };
    } catch (e) {
      return {
        'next_5_years': [],
        'next_30_years': [],
      };
    }
  }

  // Helper to parse string fields to lists
  List<String> _getListFromField(String field) {
    if (!data.containsKey(field)) return [];
    return _parseStringToList(data[field]);
  }

  // Parse a string with bullet points or newlines into a list
  List<String> _parseStringToList(String text) {
    if (text.isEmpty) return [];

    // Split by bullet points or newlines
    final items = text
        .split(RegExp(r'[\n•]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return items;
  }

  // Convert to map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'data': data,
      'isPremium': isPremium,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create from map
  factory Insight.fromMap(Map<String, dynamic> map) {
    return Insight(
      id: map['id'],
      userId: map['userId'],
      data: map['data'],
      isPremium: map['isPremium'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  // Create from Firestore document
  factory Insight.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Insight(
      id: doc.id,
      userId: data['userId'] ?? '',
      data: data['data'] ?? {},
      isPremium: data['isPremium'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Convert to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'data': data,
      'isPremium': isPremium,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // Copy with
  Insight copyWith({
    String? id,
    String? userId,
    Map<String, dynamic>? data,
    bool? isPremium,
    DateTime? createdAt,
  }) {
    return Insight(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      data: data ?? this.data,
      isPremium: isPremium ?? this.isPremium,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}