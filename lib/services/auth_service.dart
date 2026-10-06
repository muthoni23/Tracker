import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Thin wrapper around FirebaseAuth so screens don't talk to the
/// Firebase SDK directly.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Bumped whenever the signed-in user's profile (display name, etc.)
  /// changes, so any screen can listen and refresh without relying on
  /// a full navigation rebuild.
  static final ValueNotifier<int> profileVersion = ValueNotifier<int>(0);

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await cred.user?.updateDisplayName(displayName);
    return cred;
  }

  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Updates the current user's display name in Firebase Authentication
  /// and notifies [profileVersion] listeners so the UI refreshes.
  Future<void> updateDisplayName(String name) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No signed-in user.',
      );
    }
    await user.updateDisplayName(name.trim());
    await user.reload();
    profileVersion.value++;
  }

  /// Reloads the current user from Firebase and returns whether their
  /// email address is verified.
  Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No signed-in user.',
      );
    }
    await user.sendEmailVerification();
  }

  /// Deletes the current user's Firebase Authentication account.
  /// If Firebase requires a recent login, [password] is used to
  /// re-authenticate (only applies to email/password accounts) before
  /// retrying the deletion.
  Future<void> deleteAccount({String? password}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No signed-in user.',
      );
    }
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login' &&
          password != null &&
          password.isNotEmpty &&
          user.email != null) {
        final credential =
            EmailAuthProvider.credential(email: user.email!, password: password);
        await user.reauthenticateWithCredential(credential);
        await user.delete();
      } else {
        rethrow;
      }
    }
  }

  Future<void> signOut() => _auth.signOut();
}
