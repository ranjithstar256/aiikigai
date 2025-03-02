/*
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/answer.dart';
import '../../models/insight.dart';
import '../../models/question.dart';
import '../../models/section.dart';
import '../../models/user.dart';

// Provider definition
final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Shared preferences provider must be overridden');
});

class FirebaseService {
  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  late final CollectionReference _usersCollection;
  late final CollectionReference _sectionsCollection;
  late final CollectionReference _answersCollection;
  late final CollectionReference _insightsCollection;

  // Default sections for fallback
  late List<Section> _defaultSections;

  // Initialize services
  Future<void> initialize() async {
    // Initialize collections
    _usersCollection = _firestore.collection('users');
    _sectionsCollection = _firestore.collection('sections');
    _answersCollection = _firestore.collection('answers');
    _insightsCollection = _firestore.collection('insights');

    // Load default sections from json file or hardcoded values
    _defaultSections = _createDefaultSections();
  }

  // Authentication methods
  Future<AppUser?> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    try {
      final userDoc = await _usersCollection.doc(firebaseUser.uid).get();
      if (userDoc.exists) {
        return AppUser.fromFirestore(userDoc as DocumentSnapshot<Map<String, dynamic>>);
      } else {
        // Create user document if it doesn't exist
        final newUser = AppUser.fromFirebaseUser(firebaseUser);
        await _usersCollection.doc(firebaseUser.uid).set(newUser.toFirestore());
        return newUser;
      }
    } catch (e) {
      print('Error getting current user: $e');
      return AppUser.fromFirebaseUser(firebaseUser);
    }
  }

  Future<AppUser?> signIn(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        return getCurrentUser();
      }
      return null;
    } catch (e) {
      print('Error signing in: $e');
      rethrow;
    }
  }

  Future<AppUser?> signUp(String name, String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Update display name
        await userCredential.user!.updateDisplayName(name);

        // Create user in Firestore
        final newUser = AppUser(
          id: userCredential.user!.uid,
          name: name,
          email: email,
          emailVerified: userCredential.user!.emailVerified,
        );

        await _usersCollection.doc(newUser.id).set(newUser.toFirestore());
        return newUser;
      }
      return null;
    } catch (e) {
      print('Error signing up: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Section methods
  Stream<List<Section>> getSectionsStream() {
    return _sectionsCollection
        .orderBy('order')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Section.fromFirestore(doc))
          .toList();
    });
  }

  Future<List<Section>> getSections() async {
    try {
      final snapshot = await _sectionsCollection.orderBy('order').get();
      if (snapshot.docs.isEmpty) {
        // Use default sections if Firebase is empty
        return _defaultSections;
      }

      return snapshot.docs
          .map((doc) => Section.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting sections: $e');
      // Return default sections as fallback
      return _defaultSections;
    }
  }

  // Answer methods
  Future<void> saveAnswer(Answer answer) async {
    try {
      // Save to Firestore if user is authenticated
      if (_auth.currentUser != null) {
        await _answersCollection.add(answer.toFirestore());
      }
    } catch (e) {
      print('Error saving answer: $e');
      // Continue with local storage even if Firebase fails
    }
  }

  Future<Map<String, String>> getUserAnswers() async {
    if (_auth.currentUser == null) return {};

    try {
      final snapshot = await _answersCollection
          .where('userId', isEqualTo: _auth.currentUser!.uid)
          .get();

      final Map<String, String> answers = {};
      for (var doc in snapshot.docs) {
        final answer = Answer.fromFirestore(doc);
        answers['${answer.sectionId}_${answer.questionId}'] = answer.text;
      }

      return answers;
    } catch (e) {
      print('Error getting user answers: $e');
      return {};
    }
  }

  // Insight methods
  Future<Insight?> saveInsight(Insight insight) async {
    try {
      final docRef = await _insightsCollection.add(insight.toFirestore());
      final docSnapshot = await docRef.get();

      return Insight.fromFirestore(docSnapshot);
    } catch (e) {
      print('Error saving insight: $e');
      return null;
    }
  }

  Future<Insight?> getLatestInsight() async {
    if (_auth.currentUser == null) return null;

    try {
      final snapshot = await _insightsCollection
          .where('userId', isEqualTo: _auth.currentUser!.uid)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return Insight.fromFirestore(snapshot.docs.first);
    } catch (e) {
      print('Error getting latest insight: $e');
      return null;
    }
  }

  // Subscription methods
  Future<bool> updateSubscription(SubscriptionTier tier, DateTime? expiryDate) async {
    if (_auth.currentUser == null) return false;

    try {
      await _usersCollection.doc(_auth.currentUser!.uid).update({
        'subscriptionTier': tier.index,
        'subscriptionExpiry': expiryDate,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error updating subscription: $e');
      return false;
    }
  }

  // Private methods
  List<Section> _createDefaultSections() {
    // These are fallback sections in case Firebase data can't be loaded
    return [
      Section(
        id: 'love',
        title: 'Finding What You Love ❤️',
        description: 'Explore your deepest passions.',
        iconName: 'favorite',
        questions: [
          Question(
            id: 'q1',
            text: 'Imagine you wake up tomorrow, and you have unlimited money & time for the next 10 years. What would you spend your days doing?',
          ),
          Question(
            id: 'q2',
            text: 'A genie appears and says, "You can only do one activity for the rest of your life—but it will make you incredibly happy." What do you choose?',
          ),
          Question(
            id: 'q3',
            text: 'You find yourself on a mystical island with unlimited resources. What would you create?',
          ),
          Question(
            id: 'q4',
            text: 'If you had to teach a class that would inspire the world, what topic would you teach?',
          ),
          Question(
            id: 'q5',
            text: 'You get the power to master any skill instantly—no effort, no practice. What skill would you choose?',
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
              text: 'You are in a survival game where each person must contribute a unique skill to win. What skill do you offer?',
          ),
          Question(
            id: 'q2',
            text: 'Your closest friends need urgent help with something—something only YOU can do better than anyone else. What is it?',
          ),
          Question(
              id: 'q3',
              text: 'A mysterious businessman offers you ₹1 Crore per month, but only if you use a skill you are naturally good at. What is it?',
          ),
          Question(
            id: 'q4',
            text: 'You wake up one day and realize one of your strengths has been amplified 100x. What is your new power?',
          ),
          Question(
            id: 'q5',
            text: 'If you had to train someone to become an expert at something in 1 year, what skill would you teach?',
          ),
        ],
        isPremium: false,
        order: 2,
      ),
      Section(
        id: 'world_needs',
        title: 'What the World Needs 🌍',
        description: 'Make a meaningful impact.',
        iconName: 'public',
        questions: [
          Question(
            id: 'q1',
            text: 'You are given the power to solve ONE major global issue instantly. What problem do you fix?',
          ),
          Question(
            id: 'q2',
            text: 'If a billionaire gave you unlimited resources to improve the world in ONE way, what would you do?',
          ),
          Question(
            id: 'q3',
            text: 'An alien race visits Earth and says, "Tell us one thing that humans should improve about the world." What would you tell them?',
          ),
          Question(
            id: 'q4',
            text: 'You meet someone struggling with life. What is one powerful lesson from your own life that you would share to help them?',
          ),
          Question(
            id: 'q5',
            text: 'Imagine you have only one message to leave behind for future generations. What wisdom would you pass down?',
          ),
        ],
        isPremium: false,
        order: 3,
      ),
      Section(
        id: 'paid_for',
        title: 'What You Can Be Paid For 💰',
        description: 'Turn skills into opportunities.',
        iconName: 'attach_money',
        questions: [
          Question(
            id: 'q1',
            text: 'If you were suddenly forced to earn money using ONLY your knowledge & talents, how would you do it?',
          ),
          Question(
            id: 'q2',
            text: 'A new "Talent Auction" is created where companies bid for the best skills. What skill would companies bid the highest amount for in YOU?',
          ),
          Question(
            id: 'q3',
            text: 'You are hired as a consultant for a top company. What problem would you help them solve?',
          ),
          Question(
            id: 'q4',
            text: 'Your younger self travels to the future and asks, "What is the fastest way I can start earning money doing something I love?" What advice would you give them?',
          ),
          Question(
              id: 'q5',
              text: 'A mysterious businessman offers you ₹1 Crore per month, but only if you use a skill you are naturally good at. What is it?',
          ),
        ],
        isPremium: false,
        order: 4,
      ),
    ];
  }
}*/


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart'; // Import this
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/answer.dart';
import '../../models/insight.dart';
import '../../models/question.dart';
import '../../models/section.dart';
import '../../models/user.dart';
// Provider definition
final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Shared preferences provider must be overridden');
});
class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(); // Add GoogleSignIn instance

  late final CollectionReference _usersCollection;
  late final CollectionReference _sectionsCollection;
  late final CollectionReference _answersCollection;
  late final CollectionReference _insightsCollection;
  late List<Section> _defaultSections;

  Future<void> initialize() async {
    _usersCollection = _firestore.collection('users');
    _sectionsCollection = _firestore.collection('sections');
    _answersCollection = _firestore.collection('answers');
    _insightsCollection = _firestore.collection('insights');
    _defaultSections = _createDefaultSections();
  }

  // Add this new method for Google Sign-In
  Future<AppUser?> signInWithGoogle() async {
    try {
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User canceled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential for Firebase
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential =
      await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        // Check if user exists in Firestore, create if not
        final userDoc = await _usersCollection.doc(userCredential.user!.uid).get();
        if (!userDoc.exists) {
          final newUser = AppUser(
            id: userCredential.user!.uid,
            name: userCredential.user!.displayName ?? 'Google User',
            email: userCredential.user!.email ?? '',
            emailVerified: userCredential.user!.emailVerified,
          );
          await _usersCollection.doc(newUser.id).set(newUser.toFirestore());
          return newUser;
        }
        return AppUser.fromFirestore(userDoc as DocumentSnapshot<Map<String, dynamic>>);
      }
      return null;
    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow;
    }
  }

  // Rest of your existing methods remain unchanged
  // Authentication methods
  Future<AppUser?> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    try {
      final userDoc = await _usersCollection.doc(firebaseUser.uid).get();
      if (userDoc.exists) {
        return AppUser.fromFirestore(userDoc as DocumentSnapshot<Map<String, dynamic>>);
      } else {
        // Create user document if it doesn't exist
        final newUser = AppUser.fromFirebaseUser(firebaseUser);
        await _usersCollection.doc(firebaseUser.uid).set(newUser.toFirestore());
        return newUser;
      }
    } catch (e) {
      print('Error getting current user: $e');
      return AppUser.fromFirebaseUser(firebaseUser);
    }
  }

  Future<AppUser?> signIn(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        return getCurrentUser();
      }
      return null;
    } catch (e) {
      print('Error signing in: $e');
      rethrow;
    }
  }

  Future<AppUser?> signUp(String name, String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Update display name
        await userCredential.user!.updateDisplayName(name);

        // Create user in Firestore
        final newUser = AppUser(
          id: userCredential.user!.uid,
          name: name,
          email: email,
          emailVerified: userCredential.user!.emailVerified,
        );

        await _usersCollection.doc(newUser.id).set(newUser.toFirestore());
        return newUser;
      }
      return null;
    } catch (e) {
      print('Error signing up: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
  // Section methods
  Stream<List<Section>> getSectionsStream() {
    return _sectionsCollection
        .orderBy('order')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Section.fromFirestore(doc))
          .toList();
    });
  }

  Future<List<Section>> getSections() async {
    try {
      final snapshot = await _sectionsCollection.orderBy('order').get();
      if (snapshot.docs.isEmpty) {
        // Use default sections if Firebase is empty
        return _defaultSections;
      }

      return snapshot.docs
          .map((doc) => Section.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting sections: $e');
      // Return default sections as fallback
      return _defaultSections;
    }
  }

  // Answer methods
  Future<void> saveAnswer(Answer answer) async {
    try {
      // Save to Firestore if user is authenticated
      if (_auth.currentUser != null) {
        await _answersCollection.add(answer.toFirestore());
      }
    } catch (e) {
      print('Error saving answer: $e');
      // Continue with local storage even if Firebase fails
    }
  }

  Future<Map<String, String>> getUserAnswers() async {
    if (_auth.currentUser == null) return {};

    try {
      final snapshot = await _answersCollection
          .where('userId', isEqualTo: _auth.currentUser!.uid)
          .get();

      final Map<String, String> answers = {};
      for (var doc in snapshot.docs) {
        final answer = Answer.fromFirestore(doc);
        answers['${answer.sectionId}_${answer.questionId}'] = answer.text;
      }

      return answers;
    } catch (e) {
      print('Error getting user answers: $e');
      return {};
    }
  }

  // Insight methods
  Future<Insight?> saveInsight(Insight insight) async {
    try {
      final docRef = await _insightsCollection.add(insight.toFirestore());
      final docSnapshot = await docRef.get();

      return Insight.fromFirestore(docSnapshot);
    } catch (e) {
      print('Error saving insight: $e');
      return null;
    }
  }

  Future<Insight?> getLatestInsight() async {
    if (_auth.currentUser == null) return null;

    try {
      final snapshot = await _insightsCollection
          .where('userId', isEqualTo: _auth.currentUser!.uid)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return Insight.fromFirestore(snapshot.docs.first);
    } catch (e) {
      print('Error getting latest insight: $e');
      return null;
    }
  }

  // Subscription methods
  Future<bool> updateSubscription(SubscriptionTier tier, DateTime? expiryDate) async {
    if (_auth.currentUser == null) return false;

    try {
      await _usersCollection.doc(_auth.currentUser!.uid).update({
        'subscriptionTier': tier.index,
        'subscriptionExpiry': expiryDate,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error updating subscription: $e');
      return false;
    }
  }

  // Private methods
  List<Section> _createDefaultSections() {
    // These are fallback sections in case Firebase data can't be loaded
    return [
      Section(
        id: 'love',
        title: 'Finding What You Love ❤️',
        description: 'Explore your deepest passions.',
        iconName: 'favorite',
        questions: [
          Question(
            id: 'q1',
            text: 'Imagine you wake up tomorrow, and you have unlimited money & time for the next 10 years. What would you spend your days doing?',
          ),
          Question(
            id: 'q2',
            text: 'A genie appears and says, "You can only do one activity for the rest of your life—but it will make you incredibly happy." What do you choose?',
          ),
          Question(
            id: 'q3',
            text: 'You find yourself on a mystical island with unlimited resources. What would you create?',
          ),
          Question(
            id: 'q4',
            text: 'If you had to teach a class that would inspire the world, what topic would you teach?',
          ),
          Question(
            id: 'q5',
            text: 'You get the power to master any skill instantly—no effort, no practice. What skill would you choose?',
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
            text: 'You are in a survival game where each person must contribute a unique skill to win. What skill do you offer?',
          ),
          Question(
            id: 'q2',
            text: 'Your closest friends need urgent help with something—something only YOU can do better than anyone else. What is it?',
          ),
          Question(
            id: 'q3',
            text: 'A mysterious businessman offers you ₹1 Crore per month, but only if you use a skill you are naturally good at. What is it?',
          ),
          Question(
            id: 'q4',
            text: 'You wake up one day and realize one of your strengths has been amplified 100x. What is your new power?',
          ),
          Question(
            id: 'q5',
            text: 'If you had to train someone to become an expert at something in 1 year, what skill would you teach?',
          ),
        ],
        isPremium: false,
        order: 2,
      ),
      Section(
        id: 'world_needs',
        title: 'What the World Needs 🌍',
        description: 'Make a meaningful impact.',
        iconName: 'public',
        questions: [
          Question(
            id: 'q1',
            text: 'You are given the power to solve ONE major global issue instantly. What problem do you fix?',
          ),
          Question(
            id: 'q2',
            text: 'If a billionaire gave you unlimited resources to improve the world in ONE way, what would you do?',
          ),
          Question(
            id: 'q3',
            text: 'An alien race visits Earth and says, "Tell us one thing that humans should improve about the world." What would you tell them?',
          ),
          Question(
            id: 'q4',
            text: 'You meet someone struggling with life. What is one powerful lesson from your own life that you would share to help them?',
          ),
          Question(
            id: 'q5',
            text: 'Imagine you have only one message to leave behind for future generations. What wisdom would you pass down?',
          ),
        ],
        isPremium: false,
        order: 3,
      ),
      Section(
        id: 'paid_for',
        title: 'What You Can Be Paid For 💰',
        description: 'Turn skills into opportunities.',
        iconName: 'attach_money',
        questions: [
          Question(
            id: 'q1',
            text: 'If you were suddenly forced to earn money using ONLY your knowledge & talents, how would you do it?',
          ),
          Question(
            id: 'q2',
            text: 'A new "Talent Auction" is created where companies bid for the best skills. What skill would companies bid the highest amount for in YOU?',
          ),
          Question(
            id: 'q3',
            text: 'You are hired as a consultant for a top company. What problem would you help them solve?',
          ),
          Question(
            id: 'q4',
            text: 'Your younger self travels to the future and asks, "What is the fastest way I can start earning money doing something I love?" What advice would you give them?',
          ),
          Question(
            id: 'q5',
            text: 'A mysterious businessman offers you ₹1 Crore per month, but only if you use a skill you are naturally good at. What is it?',
          ),
        ],
        isPremium: false,
        order: 4,
      ),
    ];
  }
}

