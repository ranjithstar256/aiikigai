import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/utils/error_handler.dart';
import '../../models/user.dart';

/// Provider for the User Repository
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

/// Repository for handling user data
class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get collection reference
  CollectionReference get _usersCollection => _firestore.collection('users');

  // Get current user
  Stream<AppUser?> get currentUserStream => _auth.authStateChanges().asyncMap(
        (user) async {
      if (user == null) {
        return null;
      }

      try {
        // Get user from Firestore
        final userDoc = await _usersCollection.doc(user.uid).get();

        if (userDoc.exists) {
          return AppUser.fromFirestore(userDoc);
        } else {
          // Create a new user document if it doesn't exist
          final newUser = AppUser.fromFirebaseUser(user);
          await _usersCollection.doc(user.uid).set(newUser.toFirestore());
          return newUser;
        }
      } catch (e) {
        // If there's an error, return a basic user from Firebase
        return AppUser.fromFirebaseUser(user);
      }
    },
  );

  // Get current user (one-time fetch)
  Future<AppUser?> getCurrentUser() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        return null;
      }

      try {
        // Get user from Firestore
        final userDoc = await _usersCollection.doc(user.uid).get();

        if (userDoc.exists) {
          final appUser = AppUser.fromFirestore(userDoc);

          // Cache user locally
          await _cacheUserLocally(appUser);

          return appUser;
        } else {
          // Create a new user document if it doesn't exist
          final newUser = AppUser.fromFirebaseUser(user);
          await _usersCollection.doc(user.uid).set(newUser.toFirestore());

          // Cache user locally
          await _cacheUserLocally(newUser);

          return newUser;
        }
      } catch (e) {
        // If there's an error, return a basic user from Firebase
        final basicUser = AppUser.fromFirebaseUser(user);

        // Cache user locally
        await _cacheUserLocally(basicUser);

        return basicUser;
      }
    } catch (e) {
      // Try to get from local cache if offline
      return _getCachedUser();
    }
  }

  // Sign up with email and password
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Create user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw AuthException('Failed to create user');
      }

      // Update display name
      await userCredential.user!.updateDisplayName(name);

      // Create user in Firestore
      final newUser = AppUser(
        id: userCredential.user!.uid,
        name: name,
        email: email,
        emailVerified: userCredential.user!.emailVerified,
      );

      await _usersCollection.doc(userCredential.user!.uid).set(newUser.toFirestore());

      // Cache user locally
      await _cacheUserLocally(newUser);

      return newUser;
    } catch (e) {
      throw AuthException.fromFirebaseAuth(e);
    }
  }

  // Sign in with email and password
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Sign in with Firebase Auth
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw AuthException('Failed to sign in');
      }

      // Get user from Firestore
      final userDoc = await _usersCollection.doc(userCredential.user!.uid).get();

      AppUser appUser;

      if (userDoc.exists) {
        appUser = AppUser.fromFirestore(userDoc);
      } else {
        // Create user in Firestore if it doesn't exist
        appUser = AppUser.fromFirebaseUser(userCredential.user!);
        await _usersCollection.doc(userCredential.user!.uid).set(appUser.toFirestore());
      }

      // Cache user locally
      await _cacheUserLocally(appUser);

      return appUser;
    } catch (e) {
      throw AuthException.fromFirebaseAuth(e);
    }
  }

  // Sign in with Google
  Future<AppUser?> signInWithGoogle() async {
    try {
      // Begin Google Sign In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return null; // User canceled the sign-in flow
      }

      // Get Google auth details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create credential
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user == null) {
        throw AuthException('Failed to sign in with Google');
      }

      // Get user from Firestore
      final userDoc = await _usersCollection.doc(userCredential.user!.uid).get();

      AppUser appUser;

      if (userDoc.exists) {
        appUser = AppUser.fromFirestore(userDoc);

        // Update user details if needed
        if (appUser.name != userCredential.user!.displayName ||
            appUser.email != userCredential.user!.email ||
            appUser.photoUrl != userCredential.user!.photoURL) {

          appUser = appUser.copyWith(
            name: userCredential.user!.displayName ?? appUser.name,
            email: userCredential.user!.email ?? appUser.email,
            photoUrl: userCredential.user!.photoURL,
            emailVerified: userCredential.user!.emailVerified,
          );

          await _usersCollection.doc(userCredential.user!.uid).update({
            'name': appUser.name,
            'email': appUser.email,
            'photoUrl': appUser.photoUrl,
            'emailVerified': appUser.emailVerified,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      } else {
        // Create user in Firestore if it doesn't exist
        appUser = AppUser.fromFirebaseUser(userCredential.user!);
        await _usersCollection.doc(userCredential.user!.uid).set(appUser.toFirestore());
      }

      // Cache user locally
      await _cacheUserLocally(appUser);

      return appUser;
    } catch (e) {
      throw AuthException.fromFirebaseAuth(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();

      // Clear cached user
      await _clearCachedUser();
    } catch (e) {
      throw AuthException.fromFirebaseAuth(e);
    }
  }

  // Update user profile
  Future<AppUser> updateUserProfile({
    required String userId,
    String? name,
    String? photoUrl,
  }) async {
    try {
      // Get current user data
      final userDoc = await _usersCollection.doc(userId).get();

      if (!userDoc.exists) {
        throw DatabaseException('User not found');
      }

      AppUser appUser = AppUser.fromFirestore(userDoc);

      // Update fields
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null && name.isNotEmpty) {
        updates['name'] = name;

        // Also update in Firebase Auth
        if (_auth.currentUser != null) {
          await _auth.currentUser!.updateDisplayName(name);
        }
      }

      if (photoUrl != null) {
        updates['photoUrl'] = photoUrl;

        // Also update in Firebase Auth
        if (_auth.currentUser != null) {
          await _auth.currentUser!.updatePhotoURL(photoUrl);
        }
      }

      // Update Firestore
      await _usersCollection.doc(userId).update(updates);

      // Get updated user
      final updatedDoc = await _usersCollection.doc(userId).get();
      final updatedUser = AppUser.fromFirestore(updatedDoc);

      // Cache updated user
      await _cacheUserLocally(updatedUser);

      return updatedUser;
    } catch (e) {
      throw DatabaseException('Failed to update profile: $e', original: e);
    }
  }

  // Update subscription status
  Future<AppUser> updateSubscription({
    required String userId,
    required SubscriptionTier tier,
    DateTime? expiryDate,
  }) async {
    try {
      // Update Firestore
      await _usersCollection.doc(userId).update({
        'subscriptionTier': tier.index,
        'subscriptionExpiry': expiryDate,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Get updated user
      final updatedDoc = await _usersCollection.doc(userId).get();
      final updatedUser = AppUser.fromFirestore(updatedDoc);

      // Cache updated user
      await _cacheUserLocally(updatedUser);

      return updatedUser;
    } catch (e) {
      throw DatabaseException('Failed to update subscription: $e', original: e);
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw AuthException.fromFirebaseAuth(e);
    }
  }

  // Cache user locally
  Future<void> _cacheUserLocally(AppUser user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(user.toMap()));
    } catch (e) {
      print('Warning: Failed to cache user locally: $e');
    }
  }

  // Get cached user
  Future<AppUser?> _getCachedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user');

      if (userData != null) {
        return AppUser.fromMap(jsonDecode(userData));
      }

      return null;
    } catch (e) {
      print('Warning: Failed to get cached user: $e');
      return null;
    }
  }

  // Clear cached user
  Future<void> _clearCachedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user');
    } catch (e) {
      print('Warning: Failed to clear cached user: $e');
    }
  }
}