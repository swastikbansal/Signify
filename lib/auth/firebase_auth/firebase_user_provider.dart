import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';

import '../base_auth_user_provider.dart';

export '../base_auth_user_provider.dart';

class SignifyFirebaseUser extends BaseAuthUser {
  SignifyFirebaseUser(this.user);
  User? user;
  @override
  bool get loggedIn => user != null;

  @override
  AuthUserInfo get authUserInfo => AuthUserInfo(
    uid: user?.uid,
    email: user?.email,
    displayName: user?.displayName,
    photoUrl: user?.photoURL,
    phoneNumber: user?.phoneNumber,
  );

  @override
  Future? delete() => user?.delete();

  @override
  Future? updateEmail(String email) async {
    try {
      // In newer versions of Firebase Auth, updateEmail may not be available
      // Instead, use verifyBeforeUpdateEmail for secure email updates
      await user?.verifyBeforeUpdateEmail(email);
    } catch (e) {
      print('Error updating email: $e');
      rethrow;
    }
  }

  @override
  Future? updatePassword(String newPassword) async {
    await user?.updatePassword(newPassword);
  }

  @override
  Future? sendEmailVerification() => user?.sendEmailVerification();

  @override
  bool get emailVerified {
    // Reloads the user when checking in order to get the most up to date
    // email verified status.
    if (loggedIn && !user!.emailVerified) {
      refreshUser();
    }
    return user?.emailVerified ?? false;
  }

  @override
  Future refreshUser() async {
    await FirebaseAuth.instance.currentUser?.reload().then(
      (_) => user = FirebaseAuth.instance.currentUser,
    );
  }

  static BaseAuthUser fromUserCredential(UserCredential userCredential) =>
      fromFirebaseUser(userCredential.user);
  static BaseAuthUser fromFirebaseUser(User? user) => SignifyFirebaseUser(user);
}

Stream<BaseAuthUser> signifyFirebaseUserStream() => FirebaseAuth.instance
    .authStateChanges()
    .debounce(
      (user) => user == null && !loggedIn
          ? TimerStream(true, const Duration(seconds: 1))
          : Stream.value(user),
    )
    .map<BaseAuthUser>((user) {
      currentUser = SignifyFirebaseUser(user);
      return currentUser!;
    });
