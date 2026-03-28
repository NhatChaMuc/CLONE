import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/models.dart';

/// Repository for handling user-related operations
class UserRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  UserRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  /// Sign up with email and password
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final userCred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCred.user;
      if (user == null) {
        throw AuthException(message: 'Registration failed');
      }

      final userModel = UserModel(
        uid: user.uid,
        email: email,
        fullName: fullName,
        createdAt: DateTime.now(),
      );

      // Save user data to Firestore
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userModel.toFirestore());

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        message: e.message ?? 'Sign up failed',
        code: e.code,
        originalException: e,
      );
    } catch (e) {
      throw UnknownException(
        message: 'Unexpected error during sign up',
        originalException: e,
      );
    }
  }

  /// Sign in with email and password
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCred.user;
      if (user == null) {
        throw AuthException(message: 'Sign in failed');
      }

      // Fetch user data from Firestore
      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (!doc.exists) {
        throw NotFoundException(message: 'User data not found');
      }

      return UserModel.fromFirestore(doc.id, doc.data()!);
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        message: e.message ?? 'Sign in failed',
        code: e.code,
        originalException: e,
      );
    } catch (e) {
      throw UnknownException(
        message: 'Unexpected error during sign in',
        originalException: e,
      );
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw UnknownException(message: 'Sign out failed', originalException: e);
    }
  }

  /// Get user by ID
  Future<UserModel> getUserById(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();

      if (!doc.exists) {
        throw NotFoundException(message: 'User not found');
      }

      return UserModel.fromFirestore(doc.id, doc.data()!);
    } catch (e) {
      throw DataException(
        message: 'Failed to fetch user',
        originalException: e,
      );
    }
  }

  /// Update user profile
  Future<void> updateUserProfile({
    required String uid,
    String? fullName,
    String? email,
  }) async {
    try {
      final updateData = <String, dynamic>{
        if (fullName != null) 'full name': fullName,
        if (email != null) 'email': email,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(uid).update(updateData);
    } catch (e) {
      throw DataException(
        message: 'Failed to update profile',
        originalException: e,
      );
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        message: e.message ?? 'Password reset failed',
        code: e.code,
        originalException: e,
      );
    }
  }
}
