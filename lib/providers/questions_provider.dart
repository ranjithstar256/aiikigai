import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/services/firebase_service.dart';
import '../models/section.dart';
import 'auth_provider.dart';

// Questions state class
class QuestionsState {
  final List<Section> sections;
  final bool isLoading;
  final String? errorMessage;

  QuestionsState({
    this.sections = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  List<Section> get freeSections =>
      sections.where((section) => !section.isPremium).toList();

  List<Section> get premiumSections =>
      sections.where((section) => section.isPremium).toList();

  QuestionsState copyWith({
    List<Section>? sections,
    bool? isLoading,
    String? errorMessage,
  }) {
    return QuestionsState(
      sections: sections ?? this.sections,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  QuestionsState withError(String message) {
    return copyWith(
      isLoading: false,
      errorMessage: message,
    );
  }

  QuestionsState clearError() {
    return copyWith(
      errorMessage: null,
    );
  }

  Section? getSectionById(String id) {
    try {
      return sections.firstWhere((section) => section.id == id);
    } catch (e) {
      return null;
    }
  }
}

// Questions notifier class
class QuestionsNotifier extends StateNotifier<QuestionsState> {
  final FirebaseService _firebaseService;
  final AuthState _authState;

  QuestionsNotifier(this._firebaseService, this._authState)
      : super(QuestionsState()) {
    loadSections();
  }

  Future<void> loadSections() async {
    state = state.copyWith(isLoading: true);

    try {
      final sections = await _firebaseService.getSections();
      state = state.copyWith(
        sections: sections,
        isLoading: false,
      );
    } catch (e) {
      state = state.withError('Failed to load sections: $e');
    }
  }

  // Get filterable sections based on user subscription
  List<Section> getAvailableSections() {
    final isPremium = _authState.user?.isPremium ?? false;

    if (isPremium) {
      return state.sections;
    } else {
      return state.freeSections;
    }
  }

  Section? getSectionById(String id) {
    return state.getSectionById(id);
  }

  void clearError() {
    state = state.clearError();
  }
}

// Provider definition
final questionsProvider = StateNotifierProvider<QuestionsNotifier, QuestionsState>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  final authState = ref.watch(authProvider);
  return QuestionsNotifier(firebaseService, authState);
});

// Simple provider for getting available sections filtered by subscription
final availableSectionsProvider = Provider<List<Section>>((ref) {
  final questionsNotifier = ref.watch(questionsProvider.notifier);
  return questionsNotifier.getAvailableSections();
});

// Provider for getting a section by ID
final sectionByIdProvider = Provider.family<Section?, String>((ref, id) {
  final questionsNotifier = ref.watch(questionsProvider.notifier);
  return questionsNotifier.getSectionById(id);
});