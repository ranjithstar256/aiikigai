import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/services/firebase_service.dart';
import '../models/user.dart';

// Auth state class
class AuthState {
  final AppUser? user;
  final bool isLoading;
  final String? errorMessage;

  AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isLoggedIn => user != null;

  AuthState copyWith({
    AppUser? user,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  AuthState withError(String message) {
    return copyWith(
      isLoading: false,
      errorMessage: message,
    );
  }

  AuthState clearError() {
    return copyWith(
      errorMessage: null,
    );
  }
}

// Auth notifier class
class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseService _firebaseService;

  AuthNotifier(this._firebaseService) : super(AuthState()) {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    state = state.copyWith(isLoading: true);
    try {
      final user = await _firebaseService.getCurrentUser();
      state = state.copyWith(
        user: user,
        isLoading: false,
      );
    } catch (e) {
      state = state.withError('Failed to initialize authentication: $e');
    }
  }

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      final user = await _firebaseService.signIn(email, password);
      if (user != null) {
        state = state.copyWith(
          user: user,
          isLoading: false,
        );
      } else {
        state = state.withError('Sign in failed: No user returned');
      }
    } catch (e) {
      state = state.withError('Sign in failed: $e');
    }
  }

  Future<void> signUp(String name, String email, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      final user = await _firebaseService.signUp(name, email, password);
      if (user != null) {
        state = state.copyWith(
          user: user,
          isLoading: false,
        );
      } else {
        state = state.withError('Sign up failed: No user returned');
      }
    } catch (e) {
      state = state.withError('Sign up failed: $e');
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    try {
      await _firebaseService.signOut();
      state = state.copyWith(
        user: null,
        isLoading: false,
      );
    } catch (e) {
      state = state.withError('Sign out failed: $e');
    }
  }

  Future<void> updateSubscription(SubscriptionTier tier, DateTime? expiryDate) async {
    state = state.copyWith(isLoading: true);
    try {
      if (state.user == null) {
        throw Exception('No user logged in');
      }
      final success = await _firebaseService.updateSubscription(tier, expiryDate);
      if (success) {
        final updatedUser = state.user!.copyWith(
          subscriptionTier: tier,
          subscriptionExpiry: expiryDate,
          updatedAt: DateTime.now(),
        );
        state = state.copyWith(
          user: updatedUser,
          isLoading: false,
        );
      } else {
        state = state.withError('Failed to update subscription');
      }
    } catch (e) {
      state = state.withError('Subscription update failed: $e');
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true);
    try {
      final user = await _firebaseService.signInWithGoogle();
      state = state.copyWith(
        user: user,
        isLoading: false,
      );
    } catch (e) {
      state = state.withError('Google sign-in failed: $e');
    }
  }

  void clearError() {
    state = state.clearError();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return AuthNotifier(firebaseService);
});