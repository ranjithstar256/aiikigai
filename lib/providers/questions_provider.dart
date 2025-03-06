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

// In QuestionsNotifier class
  Future<void> loadSections() async {
    print("⭐ QuestionsNotifier: Starting to load sections");
    state = state.copyWith(isLoading: true);

    try {
      print("⭐ QuestionsNotifier: Attempting to get sections from FirebaseService");
      final sections = await _firebaseService.getSections();
      print("⭐ QuestionsNotifier: Got ${sections.length} sections from FirebaseService");

      // Print each section for debugging
      if (sections.isNotEmpty) {
        sections.forEach((section) => print("⭐ Section: ${section.id} - ${section.title}"));
      } else {
        print("⭐ WARNING: No sections were returned from FirebaseService!");
      }

      state = state.copyWith(
        sections: sections,
        isLoading: false,
      );
      print("⭐ QuestionsNotifier: Sections loaded into state");
    } catch (e) {
      print("❌ QuestionsNotifier: Error loading sections: $e");
      state = state.withError('Failed to load sections: $e');
    }
  }

 /* // Get filterable sections based on user subscription
  // Add print statement to availableSectionsProvider or add this to getAvailableSections method
//b4 deep thinkning code
  List<Section> getAvailableSections() {
    final isPremium = _authState.user?.isPremium ?? false;

    final allSections = state.sections;
    print("📱 getAvailableSections: All sections count: ${allSections.length}");

    if (isPremium) {
      print("📱 User is premium, showing all sections");
      return allSections;
    } else {
      final freeSections = allSections.where((section) => !section.isPremium).toList();
      print("📱 User is NOT premium, showing ${freeSections.length} free sections");
      return freeSections;
    }
  }
*/

  List<Section> getAvailableSections() {
    final isPremium = _authState.user?.isPremium ?? false;
    final allSections = state.sections;

    // Force UI update by ensuring this happens after sections are loaded
    if (allSections.isEmpty) {
      return [];
    }

    print("📱 getAvailableSections: All sections count: ${allSections.length}");

    if (isPremium) {
      print("📱 User is premium, showing all sections");
      return allSections;
    } else {
      final freeSections = allSections.where((section) => !section.isPremium).toList();
      print("📱 User is NOT premium, showing ${freeSections.length} free sections");

      // If no free sections, show all sections but mark them as locked
      if (freeSections.isEmpty) {
        print("📱 No free sections found, will show all sections as locked");
        return allSections;
      }

      return freeSections;
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

// // Simple provider for getting available sections filtered by subscription
// final availableSectionsProvider = Provider<List<Section>>((ref) {
//   final questionsNotifier = ref.watch(questionsProvider.notifier);
//   return questionsNotifier.getAvailableSections();
// });

final availableSectionsProvider = Provider<List<Section>>((ref) {
  // Watch the questions state to get updates when sections are loaded
  final questionsState = ref.watch(questionsProvider);
  // Watch auth state to get premium status
  final authState = ref.watch(authProvider);

  final allSections = questionsState.sections;

  // For debugging
  print("📱 availableSectionsProvider: All sections count: ${allSections.length}");

  // Use your hardcoded premium flag from HomeScreen or get from auth
  final isPremium = true; // You can change this to use authState if needed

  if (isPremium) {
    print("📱 User is premium, showing all sections");
    return allSections;
  } else {
    final freeSections = allSections.where((section) => !section.isPremium).toList();
    print("📱 User is NOT premium, showing ${freeSections.length} free sections");

    // If no free sections, return all sections but they'll be displayed as locked
    if (freeSections.isEmpty && allSections.isNotEmpty) {
      print("📱 No free sections found, showing all sections as locked");
      return allSections;
    }

    return freeSections;
  }
});

// Provider for getting a section by ID
final sectionByIdProvider = Provider.family<Section?, String>((ref, id) {
  final questionsNotifier = ref.watch(questionsProvider.notifier);
  return questionsNotifier.getSectionById(id);
});