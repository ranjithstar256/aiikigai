import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/auth_service.dart';
import '../../core/utils/error_handler.dart';
import '../../models/answer.dart';

/// Provider for the Answer Repository
final answersRepositoryProvider = Provider<AnswersRepository>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AnswersRepository(authService);
});

/// Repository for handling answer data
class AnswersRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService;

  AnswersRepository(this._authService);

  // Get collection reference
  CollectionReference get _answersCollection => _firestore.collection('answers');

  // Save answer
  Future<void> saveAnswer({
    required String sectionId,
    required String questionId,
    required String text,
  }) async {
    try {
      // Check if user is authenticated
      final currentUser = _authService.currentUser;
      final userId = currentUser?.uid ?? 'anonymous';

      // Create answer model
      final answerId = Answer.generateId(sectionId, questionId);
      final answer = Answer(
        id: answerId,
        sectionId: sectionId,
        questionId: questionId,
        text: text,
        userId: userId,
      );

      // Save to local storage
      await _saveToLocal(answerId, answer);

      // If user is authenticated, save to Firestore
      if (currentUser != null) {
        // Check if answer already exists
        final existing = await _answersCollection
            .where('userId', isEqualTo: userId)
            .where('sectionId', isEqualTo: sectionId)
            .where('questionId', isEqualTo: questionId)
            .limit(1)
            .get();

        if (existing.docs.isNotEmpty) {
          // Update existing answer
          await _answersCollection.doc(existing.docs.first.id).update({
            'text': text,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          // Create new answer
          await _answersCollection.add(answer.toFirestore());
        }
      }
    } catch (e) {
      throw DatabaseException('Failed to save answer: $e', original: e);
    }
  }

  // Get answers for the current user
  Future<Map<String, String>> getUserAnswers() async {
    try {
      // First, get local answers
      final localAnswers = await _getLocalAnswers();

      // Check if user is authenticated
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        return localAnswers;
      }

      // Get answers from Firestore
      final snapshot = await _answersCollection
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      final Map<String, String> answers = Map.from(localAnswers);

      // Add Firestore answers to the map (overriding local answers if necessary)
      for (var doc in snapshot.docs) {
        final answer = Answer.fromFirestore(doc);
        final key = Answer.generateId(answer.sectionId, answer.questionId);
        answers[key] = answer.text;
      }

      return answers;
    } catch (e) {
      throw DatabaseException('Failed to get user answers: $e', original: e);
    }
  }

  // Get answers for a specific section
  Future<List<Answer>> getSectionAnswers(String sectionId) async {
    try {
      final Map<String, String> allAnswers = await getUserAnswers();
      final List<Answer> sectionAnswers = [];

      // Filter answers for this section
      allAnswers.forEach((key, value) {
        if (key.startsWith('${sectionId}_')) {
          final questionId = key.substring(sectionId.length + 1);
          sectionAnswers.add(Answer(
            id: key,
            sectionId: sectionId,
            questionId: questionId,
            text: value,
            userId: _authService.currentUser?.uid ?? 'anonymous',
          ));
        }
      });

      return sectionAnswers;
    } catch (e) {
      throw DatabaseException('Failed to get section answers: $e', original: e);
    }
  }

  // Delete an answer
  Future<void> deleteAnswer({
    required String sectionId,
    required String questionId,
  }) async {
    try {
      final answerId = Answer.generateId(sectionId, questionId);

      // Remove from local storage
      await _removeFromLocal(answerId);

      // Check if user is authenticated
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        // Find and delete from Firestore
        final snapshot = await _answersCollection
            .where('userId', isEqualTo: currentUser.uid)
            .where('sectionId', isEqualTo: sectionId)
            .where('questionId', isEqualTo: questionId)
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty) {
          await _answersCollection.doc(snapshot.docs.first.id).delete();
        }
      }
    } catch (e) {
      throw DatabaseException('Failed to delete answer: $e', original: e);
    }
  }

  // Clear all answers for the current user
  Future<void> clearAllAnswers() async {
    try {
      // Clear local storage
      await _clearLocalAnswers();

      // Check if user is authenticated
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        // Get all user answers from Firestore
        final snapshot = await _answersCollection
            .where('userId', isEqualTo: currentUser.uid)
            .get();

        // Delete each document
        final batch = _firestore.batch();
        for (var doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    } catch (e) {
      throw DatabaseException('Failed to clear answers: $e', original: e);
    }
  }

  // Save answer to local storage
  Future<void> _saveToLocal(String id, Answer answer) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing answers
      Map<String, String> answers = await _getLocalAnswers();

      // Add or update this answer
      answers[id] = answer.text;

      // Save back to shared preferences
      await prefs.setString('answers', jsonEncode(answers));
    } catch (e) {
      throw DatabaseException('Failed to save answer locally: $e', original: e);
    }
  }

  // Get answers from local storage
  Future<Map<String, String>> _getLocalAnswers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString('answers');

      if (data != null) {
        Map<String, dynamic> jsonData = jsonDecode(data);
        return jsonData.map((key, value) => MapEntry(key, value.toString()));
      }

      return {};
    } catch (e) {
      throw DatabaseException('Failed to get local answers: $e', original: e);
    }
  }

  // Remove answer from local storage
  Future<void> _removeFromLocal(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing answers
      Map<String, String> answers = await _getLocalAnswers();

      // Remove this answer
      answers.remove(id);

      // Save back to shared preferences
      await prefs.setString('answers', jsonEncode(answers));
    } catch (e) {
      throw DatabaseException('Failed to remove answer locally: $e', original: e);
    }
  }

  // Clear all local answers
  Future<void> _clearLocalAnswers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('answers');
    } catch (e) {
      throw DatabaseException('Failed to clear local answers: $e', original: e);
    }
  }
}