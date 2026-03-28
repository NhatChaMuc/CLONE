import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/models.dart';

/// Provides the Firebase Auth instance
final firebaseAuthProvider = Provider((ref) {
  return FirebaseAuth.instance;
});

/// Current authenticated user state provider
final currentUserProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return auth.authStateChanges();
});

/// Current user model provider - loads full user data from Firestore
final currentUserModelProvider = FutureProvider<UserModel?>((ref) async {
  final user = ref.watch(currentUserProvider);

  return user.whenData((authUser) async {
    if (authUser == null) return null;

    // TODO: Fetch user data from Firestore
    // This will be implemented in the repository
    return null;
  }).value;
});

/// Auth state notifier for handling login/logout/registration
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
      return AuthNotifier(ref);
    });

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final Ref ref;

  AuthNotifier(this.ref) : super(const AsyncValue.data(null));

  /// Sign up with email and password
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    state = const AsyncValue.loading();

    try {
      final auth = ref.read(firebaseAuthProvider);

      // Create user account
      final userCred = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCred.user;
      if (user == null) {
        throw AuthException(message: 'Registration failed');
      }

      // TODO: Save user to Firestore
      final userModel = UserModel(
        uid: user.uid,
        email: email,
        fullName: fullName,
        createdAt: DateTime.now(),
      );

      state = AsyncValue.data(userModel);
    } on FirebaseAuthException catch (e) {
      state = AsyncValue.error(
        AuthException(
          message: e.message ?? 'Authentication failed',
          code: e.code,
          originalException: e,
        ),
        StackTrace.current,
      );
    } catch (e) {
      state = AsyncValue.error(
        UnknownException(message: e.toString(), originalException: e),
        StackTrace.current,
      );
    }
  }

  /// Sign in with email and password
  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncValue.loading();

    try {
      final auth = ref.read(firebaseAuthProvider);

      await auth.signInWithEmailAndPassword(email: email, password: password);

      // TODO: Load user data from Firestore
      final user = auth.currentUser;
      if (user == null) {
        throw AuthException(message: 'Sign in failed');
      }

      final userModel = UserModel(
        uid: user.uid,
        email: user.email ?? email,
        fullName: 'User', // TODO: Get from Firestore
        createdAt: DateTime.now(),
      );

      state = AsyncValue.data(userModel);
    } on FirebaseAuthException catch (e) {
      state = AsyncValue.error(
        AuthException(
          message: e.message ?? 'Authentication failed',
          code: e.code,
          originalException: e,
        ),
        StackTrace.current,
      );
    } catch (e) {
      state = AsyncValue.error(
        UnknownException(message: e.toString(), originalException: e),
        StackTrace.current,
      );
    }
  }

  /// Sign out
  Future<void> signOut() async {
    state = const AsyncValue.loading();

    try {
      final auth = ref.read(firebaseAuthProvider);
      await auth.signOut();
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(
        UnknownException(message: e.toString(), originalException: e),
        StackTrace.current,
      );
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      final auth = ref.read(firebaseAuthProvider);
      await auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        message: e.message ?? 'Password reset failed',
        code: e.code,
        originalException: e,
      );
    }
  }
}
