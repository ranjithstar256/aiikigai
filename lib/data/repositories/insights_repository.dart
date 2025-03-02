import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../core/services/auth_service.dart';
import '../../core/utils/error_handler.dart';
import '../../data/services/ai_service.dart';
import '../../models/insight.dart';

/// Provider for the Insights Repository
final insightsRepositoryProvider = Provider<InsightsRepository>((ref) {
  final authService = ref.watch(authServiceProvider);
  final aiService = ref.watch(aiServiceProvider);
  return InsightsRepository(authService, aiService);
});

/// Repository for handling insights data
class InsightsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService;
  final AIService _aiService;
  final Uuid _uuid = Uuid();

  InsightsRepository(this._authService, this._aiService);

  // Get collection reference
  CollectionReference get _insightsCollection => _firestore.collection('insights');

  // Generate insights based on user answers
  Future<Insight> generateInsights(Map<String, List<String>> sectionAnswers, {bool isPremium = false}) async {
    try {
      final userId = _authService.currentUser?.uid ?? 'anonymous';

      // Generate insights using AI service
      final insight = await _aiService.generateInsights(
        sectionAnswers: sectionAnswers,
        userId: userId,
        isPremium: isPremium,
      );

      // Save to local storage
      await _saveToLocal(insight);

      // If user is authenticated, save to Firestore
      if (_authService.currentUser != null) {
        await _insightsCollection.add(insight.toFirestore());
      }

      return insight;
    } catch (e) {
      throw AppException('Failed to generate insights: $e', original: e);
    }
  }

  // Get the latest insight for the current user
  Future<Insight?> getLatestInsight() async {
    try {
      // First try to get from Firestore if user is authenticated
      if (_authService.currentUser != null) {
        final snapshot = await _insightsCollection
            .where('userId', isEqualTo: _authService.currentUser!.uid)
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty) {
          return Insight.fromFirestore(snapshot.docs.first);
        }
      }

      // If no Firestore data or not authenticated, try local storage
      return await _getFromLocal();
    } catch (e) {
      throw DatabaseException('Failed to get latest insight: $e', original: e);
    }
  }

  // Get all insights for the current user
  Future<List<Insight>> getAllInsights() async {
    try {
      final List<Insight> insights = [];

      // Get local insight
      final localInsight = await _getFromLocal();
      if (localInsight != null) {
        insights.add(localInsight);
      }

      // If user is authenticated, get from Firestore
      if (_authService.currentUser != null) {
        final snapshot = await _insightsCollection
            .where('userId', isEqualTo: _authService.currentUser!.uid)
            .orderBy('createdAt', descending: true)
            .get();

        // Add Firestore insights, avoid duplicates
        for (var doc in snapshot.docs) {
          final insight = Insight.fromFirestore(doc);
          if (!insights.any((i) => i.id == insight.id)) {
            insights.add(insight);
          }
        }
      }

      return insights;
    } catch (e) {
      throw DatabaseException('Failed to get all insights: $e', original: e);
    }
  }

  // Delete an insight
  Future<void> deleteInsight(String insightId) async {
    try {
      // If user is authenticated, delete from Firestore
      if (_authService.currentUser != null) {
        final snapshot = await _insightsCollection
            .where('userId', isEqualTo: _authService.currentUser!.uid)
            .where(FieldPath.documentId, isEqualTo: insightId)
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty) {
          await _insightsCollection.doc(snapshot.docs.first.id).delete();
        }
      }

      // Delete from local storage if it's the current insight
      final localInsight = await _getFromLocal();
      if (localInsight != null && localInsight.id == insightId) {
        await _clearLocal();
      }
    } catch (e) {
      throw DatabaseException('Failed to delete insight: $e', original: e);
    }
  }

  // Create a manual insight (for testing or backup purposes)
  Future<Insight> createManualInsight(Map<String, dynamic> data, {bool isPremium = false}) async {
    try {
      final userId = _authService.currentUser?.uid ?? 'anonymous';

      final insight = Insight(
        id: _uuid.v4(),
        userId: userId,
        data: data,
        isPremium: isPremium,
      );

      // Save to local storage
      await _saveToLocal(insight);

      // If user is authenticated, save to Firestore
      if (_authService.currentUser != null) {
        await _insightsCollection.add(insight.toFirestore());
      }

      return insight;
    } catch (e) {
      throw DatabaseException('Failed to create manual insight: $e', original: e);
    }
  }

  // Save insight to local storage
  Future<void> _saveToLocal(Insight insight) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('insight', jsonEncode(insight.toMap()));
    } catch (e) {
      throw DatabaseException('Failed to save insight locally: $e', original: e);
    }
  }

  // Get insight from local storage
  Future<Insight?> _getFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString('insight');

      if (data != null) {
        return Insight.fromMap(jsonDecode(data));
      }

      return null;
    } catch (e) {
      throw DatabaseException('Failed to get local insight: $e', original: e);
    }
  }

  // Clear local insight
  Future<void> _clearLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('insight');
    } catch (e) {
      throw DatabaseException('Failed to clear local insight: $e', original: e);
    }
  }
}