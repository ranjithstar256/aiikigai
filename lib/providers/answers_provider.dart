import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../data/services/firebase_service.dart';
import '../models/answer.dart';
import '../models/section.dart';
import 'auth_provider.dart';
import 'questions_provider.dart';

// Answers state class
class AnswersState {
  final Map<String, String> answers;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  AnswersState({
    this.answers = const {},
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
  });

  AnswersState copyWith({
    Map<String, String>? answers,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
  }) {
    return AnswersState(
      answers: answers ?? this.answers,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
    );
  }

  AnswersState withError(String message) {
    return copyWith(
      isLoading: false,
      isSaving: false,
      errorMessage: message,
    );
  }

  AnswersState clearError() {
    return copyWith(
      errorMessage: null,
    );
  }

  // Get answers for a specific section
  List<String> getAnswersForSection(Section section) {
    return section.questions.map((question) {
      final key = '${section.id}_${question.id}';
      return answers[key] ?? '';
    }).toList();
  }

  // Check if a section is complete
  bool isSectionComplete(Section section) {
    return section.questions.every((question) {
      final key = '${section.id}_${question.id}';
      return answers.containsKey(key) && answers[key]!.isNotEmpty;
    });
  }

  // Count completed sections
  int countCompletedSections(List<Section> sections) {
    return sections.where((section) => isSectionComplete(section)).length;
  }

  // Format answers for AI processing
  Map<String, List<String>> formatAnswersForAI(List<Section> sections) {
    final result = <String, List<String>>{};

    for (final section in sections) {
      if (isSectionComplete(section)) {
        result[section.title] = getAnswersForSection(section);
      }
    }

    return result;
  }
}

// Answers notifier class
class AnswersNotifier extends StateNotifier<AnswersState> {
  final FirebaseService _firebaseService;
  final SharedPreferences _prefs;
  final AuthState _authState;
  final Uuid _uuid = Uuid();

  AnswersNotifier(this._firebaseService, this._prefs, this._authState)
      : super(AnswersState()) {
    loadAnswers();
  }

  Future<void> loadAnswers() async {
    state = state.copyWith(isLoading: true);

    try {
      // Try to load from Firebase if user is logged in
      Map<String, String> answers = {};

      if (_authState.isLoggedIn) {
        answers = await _firebaseService.getUserAnswers();
      }

      // If no answers from Firebase or user is not logged in, try local storage
      if (answers.isEmpty) {
        final localAnswers = _prefs.getString('answers');
        if (localAnswers != null) {
          final decoded = jsonDecode(localAnswers) as Map<String, dynamic>;
          answers = decoded.map((key, value) => MapEntry(key, value.toString()));
        }
      }

      state = state.copyWith(
        answers: answers,
        isLoading: false,
      );
    } catch (e) {
      state = state.withError('Failed to load answers: $e');
    }
  }

  Future<void> saveAnswer(String sectionId, String questionId, String text) async {
    final key = '${sectionId}_$questionId';

    // Update state
    final updatedAnswers = Map<String, String>.from(state.answers);
    updatedAnswers[key] = text;

    state = state.copyWith(
      answers: updatedAnswers,
      isSaving: true,
    );

    try {
      // Save to local storage
      await _prefs.setString('answers', jsonEncode(updatedAnswers));

      // Save to Firebase if user is logged in
      if (_authState.isLoggedIn) {
        final answer = Answer(
          id: _uuid.v4(),
          sectionId: sectionId,
          questionId: questionId,
          text: text,
          userId: _authState.user!.id,
        );

        await _firebaseService.saveAnswer(answer);
      }

      state = state.copyWith(isSaving: false);
    } catch (e) {
      state = state.withError('Failed to save answer: $e');
    }
  }

  List<String> getAnswersForSection(Section section) {
    return state.getAnswersForSection(section);
  }

  bool isSectionComplete(Section section) {
    return state.isSectionComplete(section);
  }

  int countCompletedSections(List<Section> sections) {
    return state.countCompletedSections(sections);
  }

  Map<String, List<String>> formatAnswersForAI(List<Section> sections) {
    return state.formatAnswersForAI(sections);
  }

  void clearError() {
    state = state.clearError();
  }
}

// Provider definition
final answersProvider = StateNotifierProvider<AnswersNotifier, AnswersState>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  final authState = ref.watch(authProvider);
  return AnswersNotifier(firebaseService, prefs, authState);
});

// Provider for checking if a section is complete
final sectionCompleteProvider = Provider.family<bool, Section>((ref, section) {
  return ref.watch(answersProvider).isSectionComplete(section);
});

// Provider for getting the count of completed sections
final completedSectionsCountProvider = Provider((ref) {
  final sections = ref.watch(availableSectionsProvider);
  return ref.watch(answersProvider).countCompletedSections(sections);
});

// Provider for checking if all required sections are complete
final allRequiredSectionsCompleteProvider = Provider((ref) {
  final sections = ref.watch(availableSectionsProvider);
  final requiredSections = sections.where((s) => !s.isPremium).toList();
  final answersState = ref.watch(answersProvider);

  return requiredSections.every((section) =>
      answersState.isSectionComplete(section)
  );
});