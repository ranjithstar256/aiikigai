import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'question.dart';

class Section {
  final String id;
  final String title;
  final String description;
  final String iconName;
  final List<Question> questions;
  final bool isPremium;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;

  Section({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    required this.questions,
    this.isPremium = false,
    this.order = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Get icon based on iconName
  IconData get icon {
    switch (iconName) {
      case 'favorite':
        return Icons.favorite;
      case 'star':
        return Icons.star;
      case 'public':
        return Icons.public;
      case 'attach_money':
        return Icons.attach_money;
      case 'psychology':
        return Icons.psychology;
      case 'auto_awesome':
        return Icons.auto_awesome;
      case 'lightbulb':
        return Icons.lightbulb;
      default:
        return Icons.help_outline;
    }
  }

  // Get emoji for the section title
  String get emoji {
    switch (iconName) {
      case 'favorite':
        return '❤️';
      case 'star':
        return '💪';
      case 'public':
        return '🌍';
      case 'attach_money':
        return '💰';
      case 'psychology':
        return '🧠';
      case 'auto_awesome':
        return '🎯';
      case 'lightbulb':
        return '🏆';
      default:
        return '🔍';
    }
  }

  // Get formatted title with emoji
  String get formattedTitle => '$title $emoji';

  // Check if all questions have been answered
  bool isComplete(Map<String, String> answers) {
    return questions.every((question) =>
    answers.containsKey('${id}_${question.id}') &&
        answers['${id}_${question.id}']!.isNotEmpty
    );
  }

  // Convert to map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'iconName': iconName,
      'questions': questions.map((q) => q.toMap()).toList(),
      'isPremium': isPremium,
      'order': order,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from map
  factory Section.fromMap(Map<String, dynamic> map) {
    return Section(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      iconName: map['iconName'],
      questions: (map['questions'] as List)
          .map((q) => Question.fromMap(q))
          .toList(),
      isPremium: map['isPremium'] ?? false,
      order: map['order'] ?? 0,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  // Create from Firestore document
/*  factory Section.fromFirestore(DocumentSnapshot doc) {
    print("🔍 Converting Firestore doc to Section: ${doc.id}");
    try {
      final data = doc.data() as Map<String, dynamic>;

      // Print the raw questions data to check format
      print("🔍 Questions data type: ${data['questions'].runtimeType}");
      print("🔍 Questions data: ${data['questions']}");

      final questions = (data['questions'] as List?)
          ?.map((q) => Question.fromMap(q as Map<String, dynamic>))
          .toList() ?? [];

      print("🔍 Converted ${questions.length} questions");

      return Section(
        id: doc.id,
        title: data['title'] ?? '',
        description: data['description'] ?? '',
        iconName: data['iconName'] ?? 'help_outline',
        questions: questions,
        isPremium: data['isPremium'] ?? false,
        order: data['order'] ?? 0,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    } catch (e) {
      print("❌ Error creating Section from Firestore: $e");
      // Return empty section instead of throwing
      return Section(
        id: doc.id,
        title: "Error loading section",
        description: "There was an error loading this section: $e",
        iconName: 'error',
        questions: [],
        isPremium: false,
        order: 999,
      );
    }
  }*/

/*  //b4 deep thinking code
  factory Section.fromFirestore(DocumentSnapshot doc) {
    print("Converting Firestore doc to Section: ${doc.id}");
    try {
      final data = doc.data() as Map<String, dynamic>;

      // Debug print the raw questions data
      print("Raw questions data: ${data['questions']}");

      // Make sure questions is an actual List before mapping
      List<Question> questions = [];
      if (data['questions'] != null && data['questions'] is List) {
        questions = (data['questions'] as List)
            .map((q) => Question.fromMap(q as Map<String, dynamic>))
            .toList();
      } else {
        print("WARNING: Questions data is missing or not a list: ${data['questions']}");
      }

      return Section(
        id: doc.id,
        title: data['title'] ?? '',
        description: data['description'] ?? '',
        iconName: data['iconName'] ?? 'help_outline',
        questions: questions,
        isPremium: data['isPremium'] ?? false,
        order: data['order'] ?? 0,
      );
    } catch (e) {
      print("Error creating Section from Firestore: $e");
      // Return empty section instead of throwing
      return Section(
        id: doc.id,
        title: "Error loading section",
        description: "There was an error loading this section: $e",
        iconName: 'error',
        questions: [],
        isPremium: false,
        order: 999,
      );
    }
  }*/

  factory Section.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;

      // Handle questions data safely
      List<Question> questions = [];
      if (data['questions'] != null) {
        if (data['questions'] is List) {
          questions = (data['questions'] as List)
              .where((q) => q is Map<String, dynamic>)
              .map((q) => Question.fromMap(q as Map<String, dynamic>))
              .toList();
        } else {
          print("Warning: 'questions' field is not a List: ${data['questions'].runtimeType}");
        }
      } else {
        print("Warning: 'questions' field is missing in section document: ${doc.id}");
      }

      return Section(
        id: doc.id,
        title: data['title'] ?? 'Untitled Section',
        description: data['description'] ?? 'No description provided',
        iconName: data['iconName'] ?? 'help_outline',
        questions: questions,
        isPremium: data['isPremium'] ?? false,
        order: data['order'] ?? 999,
        createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : DateTime.now(),
        updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : DateTime.now(),
      );
    } catch (e) {
      print("Error creating Section from Firestore: $e");
      return Section(
        id: doc.id,
        title: "Error loading section",
        description: "There was an error loading this section. Please try again later.",
        iconName: 'error',
        questions: [],
        isPremium: false,
        order: 999,
      );
    }
  }
  // Copy with
  Section copyWith({
    String? id,
    String? title,
    String? description,
    String? iconName,
    List<Question>? questions,
    bool? isPremium,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Section(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      questions: questions ?? this.questions,
      isPremium: isPremium ?? this.isPremium,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}