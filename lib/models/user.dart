import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

enum SubscriptionTier {
  free,
  basic,
  premium,
  premiumYearly,
}

extension SubscriptionTierExtension on SubscriptionTier {
  String get name {
    switch (this) {
      case SubscriptionTier.free:
        return 'Free';
      case SubscriptionTier.basic:
        return 'Basic';
      case SubscriptionTier.premium:
        return 'Premium';
      case SubscriptionTier.premiumYearly:
        return 'Premium Yearly';
    }
  }

  String get price {
    switch (this) {
      case SubscriptionTier.free:
        return '₹0';
      case SubscriptionTier.basic:
        return '₹299/month';
      case SubscriptionTier.premium:
        return '₹499/month';
      case SubscriptionTier.premiumYearly:
        return '₹3,999/year';
    }
  }

  List<String> get features {
    switch (this) {
      case SubscriptionTier.free:
        return [
          'Access to 4 basic sections',
          'Generate basic insights',
          'Download PDF report',
        ];
      case SubscriptionTier.basic:
        return [
          'Access to all sections',
          'Generate detailed insights',
          'Download PDF report',
          'Chat with AI assistant',
        ];
      case SubscriptionTier.premium:
      case SubscriptionTier.premiumYearly:
        return [
          'All Basic plan features',
          'Advanced analytics',
          'Personalized recommendations',
          'Exclusive premium sections',
          'Priority support',
        ];
    }
  }
}

class AppUser {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final SubscriptionTier subscriptionTier;
  final DateTime? subscriptionExpiry;
  final bool emailVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    this.subscriptionTier = SubscriptionTier.free,
    this.subscriptionExpiry,
    this.emailVerified = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Check if user has premium access
  bool get isPremium =>
      subscriptionTier != SubscriptionTier.free &&
          (subscriptionExpiry == null || subscriptionExpiry!.isAfter(DateTime.now()));

  // Convert to map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'subscriptionTier': subscriptionTier.index,
      'subscriptionExpiry': subscriptionExpiry?.toIso8601String(),
      'emailVerified': emailVerified,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from map
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      photoUrl: map['photoUrl'],
      subscriptionTier: SubscriptionTier.values[map['subscriptionTier'] ?? 0],
      subscriptionExpiry: map['subscriptionExpiry'] != null
          ? DateTime.parse(map['subscriptionExpiry'])
          : null,
      emailVerified: map['emailVerified'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  // Create from Firestore document
  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'],
      subscriptionTier: SubscriptionTier.values[data['subscriptionTier'] ?? 0],
      subscriptionExpiry: data['subscriptionExpiry'] != null
          ? (data['subscriptionExpiry'] as Timestamp).toDate()
          : null,
      emailVerified: data['emailVerified'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Create from Firebase user
  factory AppUser.fromFirebaseUser(firebase_auth.User user) {
    return AppUser(
      id: user.uid,
      name: user.displayName ?? 'User',
      email: user.email ?? '',
      photoUrl: user.photoURL,
      emailVerified: user.emailVerified,
    );
  }

  // Convert to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'subscriptionTier': subscriptionTier.index,
      'subscriptionExpiry': subscriptionExpiry,
      'emailVerified': emailVerified,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // Copy with
  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    SubscriptionTier? subscriptionTier,
    DateTime? subscriptionExpiry,
    bool? emailVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      subscriptionExpiry: subscriptionExpiry ?? this.subscriptionExpiry,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}