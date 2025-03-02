import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/app_config.dart';
import '../../core/utils/error_handler.dart';
import '../../models/question.dart';
import '../../models/section.dart';

/// Provider for the Questions Repository
final questionsRepositoryProvider = Provider<QuestionsRepository>((ref) {
  return QuestionsRepository();
});

/// Repository for handling questions and sections data
class QuestionsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get collection reference
  CollectionReference get _sectionsCollection => _firestore.collection('sections');

  // Get all sections with their questions
  Future<List<Section>> getAllSections() async {
    try {
      // First try to get from Firestore
      List<Section> sections = await _getFirestoreSections();

      // If no sections found in Firestore, try local cache
      if (sections.isEmpty) {
        sections = await _getLocalSections();
      }

      // If still no sections, use default ones from app config
      if (sections.isEmpty) {
        sections = _getDefaultSections();
      }

      // Cache the sections locally
      await _cacheLocalSections(sections);

      // Sort sections by order
      sections.sort((a, b) => a.order.compareTo(b.order));

      return sections;
    } catch (e) {
      throw DatabaseException('Failed to get sections: $e', original: e);
    }
  }

  // Get a specific section by ID
  Future<Section?> getSectionById(String sectionId) async {
    try {
      // Get all sections
      final sections = await getAllSections();

      // Find the section with matching ID
      return sections.firstWhere(
            (section) => section.id == sectionId,
        orElse: () => throw DatabaseException('Section not found: $sectionId'),
      );
    } catch (e) {
      throw DatabaseException('Failed to get section: $e', original: e);
    }
  }

  // Get all free sections (non-premium)
  Future<List<Section>> getFreeSections() async {
    try {
      final sections = await getAllSections();
      return sections.where((section) => !section.isPremium).toList();
    } catch (e) {
      throw DatabaseException('Failed to get free sections: $e', original: e);
    }
  }

  // Get all premium sections
  Future<List<Section>> getPremiumSections() async {
    try {
      final sections = await getAllSections();
      return sections.where((section) => section.isPremium).toList();
    } catch (e) {
      throw DatabaseException('Failed to get premium sections: $e', original: e);
    }
  }

  // Get sections from Firestore
  Future<List<Section>> _getFirestoreSections() async {
    try {
      final snapshot = await _sectionsCollection.orderBy('order').get();

      if (snapshot.docs.isEmpty) {
        return [];
      }

      return snapshot.docs.map((doc) {
        return Section.fromFirestore(doc);
      }).toList();
    } catch (e) {
      // If there's an error with Firestore, return empty list and fall back to local cache
      return [];
    }
  }

  // Get sections from local cache
  Future<List<Section>> _getLocalSections() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString('sections');

      if (data != null) {
        final List<dynamic> jsonData = jsonDecode(data);
        return jsonData.map((item) => Section.fromMap(item)).toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  // Cache sections locally
  Future<void> _cacheLocalSections(List<Section> sections) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = sections.map((section) => section.toMap()).toList();
      await prefs.setString('sections', jsonEncode(jsonData));
    } catch (e) {
      // If caching fails, just log and continue
      print('Warning: Failed to cache sections locally: $e');
    }
  }

  // Get default sections from app config
  List<Section> _getDefaultSections() {
    // Convert the default sections from AppConfig
    try {
      return AppConfig.subscriptionPlans.values.map((plan) {
        final Map<String, dynamic> sectionData = plan;
        // Create section and questions based on config data
        return Section(
          id: sectionData['id'] ?? 'section_${plan['name']}',
          title: sectionData['name'] ?? 'Unnamed Section',
          description: sectionData['description'] ?? '',
          iconName: sectionData['iconName'] ?? 'help_outline',
          questions: _getDefaultQuestions(plan['name'] ?? 'Unnamed'),
          isPremium: plan['name'] != 'Free',
          order: 0,
        );
      }).toList();
    } catch (e) {
      // If there's an issue with config data, create a minimal set of sections
      return [
        Section(
          id: 'love',
          title: 'Finding What You Love ❤️',
          description: 'Explore your deepest passions.',
          iconName: 'favorite',
          questions: [
            Question(
              id: 'q1',
              text: 'What activities make you lose track of time?',
            ),
            Question(
              id: 'q2',
              text: 'What would you do if money was not a concern?',
            ),
          ],
          isPremium: false,
          order: 1,
        ),
        Section(
          id: 'strengths',
          title: 'Discovering Your Strengths 💪',
          description: 'Uncover your natural talents.',
          iconName: 'star',
          questions: [
            Question(
              id: 'q1',
              text: 'What skills come naturally to you?',
            ),
            Question(
              id: 'q2',
              text: 'What do others often ask for your help with?',
            ),
          ],
          isPremium: false,
          order: 2,
        ),
      ];
    }
  }

  // Get default questions for a section
  List<Question> _getDefaultQuestions(String sectionName) {
    // These are just placeholder questions
    switch (sectionName.toLowerCase()) {
      case 'love':
      case 'finding what you love':
        return [
          Question(
            id: 'q1',
            text: 'What activities make you lose track of time?',
            order: 1,
          ),
          Question(
            id: 'q2',
            text: 'What would you do if money was not a concern?',
            order: 2,
          ),
          Question(
            id: 'q3',
            text: 'What activities did you enjoy as a child?',
            order: 3,
          ),
        ];
      case 'strengths':
      case 'discovering your strengths':
        return [
          Question(
            id: 'q1',
            text: 'What skills come naturally to you?',
            order: 1,
          ),
          Question(
            id: 'q2',
            text: 'What do others often ask for your help with?',
            order: 2,
          ),
          Question(
            id: 'q3',
            text: 'What have you consistently excelled at?',
            order: 3,
          ),
        ];
      case 'needs':
      case 'what the world needs':
        return [
          Question(
            id: 'q1',
            text: 'What problems in the world do you feel most drawn to solve?',
            order: 1,
          ),
          Question(
            id: 'q2',
            text: 'How could your skills help others?',
            order: 2,
          ),
          Question(
            id: 'q3',
            text: 'What injustice or issue makes you want to take action?',
            order: 3,
          ),
        ];
      case 'paid':
      case 'what you can be paid for':
        return [
          Question(
            id: 'q1',
            text: 'What skills do people typically pay for in your field?',
            order: 1,
          ),
          Question(
            id: 'q2',
            text: 'What value can you provide that others would pay for?',
            order: 2,
          ),
          Question(
            id: 'q3',
            text: 'What unique combination of skills could make you valuable?',
            order: 3,
          ),
        ];
      default:
        return [
          Question(
            id: 'q1',
            text: 'Question 1 for $sectionName',
            order: 1,
          ),
          Question(
            id: 'q2',
            text: 'Question 2 for $sectionName',
            order: 2,
          ),
        ];
    }
  }

  // Refresh sections from Firebase (force update)
  Future<List<Section>> refreshSections() async {
    try {
      // Get fresh data from Firestore
      final sections = await _getFirestoreSections();

      // If no sections found in Firestore, use defaults
      if (sections.isEmpty) {
        return _getDefaultSections();
      }

      // Cache the refreshed sections
      await _cacheLocalSections(sections);

      // Sort and return
      sections.sort((a, b) => a.order.compareTo(b.order));
      return sections;
    } catch (e) {
      throw DatabaseException('Failed to refresh sections: $e', original: e);
    }
  }
}