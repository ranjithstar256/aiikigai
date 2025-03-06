import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/services/ai_service.dart';
import '../data/services/firebase_service.dart';
import '../models/insight.dart';
import 'answers_provider.dart';
import 'auth_provider.dart';
import 'questions_provider.dart';

// Insights state class
class InsightsState {
  final Insight? insight;
  final bool isLoading;
  final bool isGenerating;
  final String? errorMessage;

  InsightsState({
    this.insight,
    this.isLoading = false,
    this.isGenerating = false,
    this.errorMessage,
  });

  InsightsState copyWith({
    Insight? insight,
    bool? isLoading,
    bool? isGenerating,
    String? errorMessage,
  }) {
    return InsightsState(
      insight: insight ?? this.insight,
      isLoading: isLoading ?? this.isLoading,
      isGenerating: isGenerating ?? this.isGenerating,
      errorMessage: errorMessage,
    );
  }

  InsightsState withError(String message) {
    return copyWith(
      isLoading: false,
      isGenerating: false,
      errorMessage: message,
    );
  }

  InsightsState clearError() {
    return copyWith(
      errorMessage: null,
    );
  }
}

// Insights notifier class
class InsightsNotifier extends StateNotifier<InsightsState> {
  final FirebaseService _firebaseService;
  final AIService _aiService;
  final SharedPreferences _prefs;
  final AuthState _authState;
  final AnswersState _answersState;
  final QuestionsState _questionsState;

  InsightsNotifier(
      this._firebaseService,
      this._aiService,
      this._prefs,
      this._authState,
      this._answersState,
      this._questionsState,
      ) : super(InsightsState()) {
    loadInsight();
  }

  Future<void> loadInsight() async {
    state = state.copyWith(isLoading: true);

    try {
      Insight? insight;

      // Try to load from Firebase if user is logged in
      if (_authState.isLoggedIn) {
        insight = await _firebaseService.getLatestInsight();
      }

      // If no insight from Firebase or user is not logged in, try local storage
      if (insight == null) {
        final localInsight = _prefs.getString('insight');
        if (localInsight != null) {
          final decoded = jsonDecode(localInsight) as Map<String, dynamic>;
          insight = Insight.fromMap(decoded);
        }
      }

      state = state.copyWith(
        insight: insight,
        isLoading: false,
      );
    } catch (e) {
      state = state.withError('Failed to load insight: $e');
    }
  }

  Future<void> generateInsight() async {
    // Check if all required sections are complete
    final sections = _questionsState.sections.where((s) => !s.isPremium).toList();
    final allComplete = sections.every((section) =>
        _answersState.isSectionComplete(section)
    );

    if (!allComplete) {
      state = state.withError('Please complete all required sections first.');
      return;
    }

    state = state.copyWith(isGenerating: true);

    try {
      // Format answers for AI
      final formattedAnswers = _answersState.formatAnswersForAI(_questionsState.sections);

      // Generate insight
      final isPremium = _authState.user?.isPremium ?? false;
      final userId = _authState.user?.id ?? 'local_user';

      final insight = await _aiService.generateInsights(
        sectionAnswers: formattedAnswers,
        userId: userId,
        isPremium: isPremium,
      );

      // Save to local storage
      await _prefs.setString('insight', jsonEncode(insight.toMap()));

      // Save to Firebase if user is logged in
      if (_authState.isLoggedIn) {
        await _firebaseService.saveInsight(insight);
      }

      Future.microtask(() {
        if (mounted) {
          state = state.copyWith(
            insight: insight,
            isGenerating: false,
          );
        }
      });
    } catch (e) {
      Future.microtask(() {
        if (mounted) {
          state = state.withError('Failed to generate insight: $e');
        }
      });
    }
  }

  void clearError() {
    state = state.clearError();
  }
}

// Provider definition
final insightsProvider = StateNotifierProvider<InsightsNotifier, InsightsState>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  final aiService = ref.watch(aiServiceProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  final authState = ref.watch(authProvider);
  final answersState = ref.watch(answersProvider);
  final questionsState = ref.watch(questionsProvider);

  return InsightsNotifier(
    firebaseService,
    aiService,
    prefs,
    authState,
    answersState,
    questionsState,
  );
});