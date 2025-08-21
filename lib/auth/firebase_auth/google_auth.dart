import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

Future<UserCredential?> googleSignInFunc() async {
  if (kIsWeb) {
    // Once signed in, return the UserCredential
    return await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
  }

  try {
    await signOutWithGoogle().catchError((_) => null);

    // Use the new Google Sign-In API approach
    // Initialize with authentication events
    final GoogleSignIn googleSignIn = GoogleSignIn.instance;

    // Initialize the Google Sign-In
    await googleSignIn.initialize();

    // Authenticate the user
    final GoogleSignInAccount googleUser = await googleSignIn.authenticate();

    // For Firebase Auth, we need access and ID tokens
    // Check if user has required scopes
    const List<String> scopes = ['email', 'profile'];
    final authorization = await googleUser.authorizationClient
        .authorizationForScopes(scopes);

    if (authorization == null) {
      print('User did not grant required scopes');
      return null;
    }

    // Get authorization headers
    final Map<String, String>? authHeaders = await googleUser
        .authorizationClient
        .authorizationHeaders(scopes);

    if (authHeaders == null) {
      print('Failed to get authorization headers');
      return null;
    }

    // Extract access token from Authorization header
    final String? authorizationHeader = authHeaders['Authorization'];
    final String? accessToken = authorizationHeader?.replaceFirst(
      'Bearer ',
      '',
    );

    if (accessToken == null) {
      print('Failed to extract access token');
      return null;
    }

    // For Firebase Auth integration with the new Google Sign-In API,
    // we need to work with just the access token (ID token may not be available)
    // Create credential with just access token
    final credential = GoogleAuthProvider.credential(
      accessToken: accessToken,
      // idToken is not available in the new API
    );

    // Once signed in, return the UserCredential
    return await FirebaseAuth.instance.signInWithCredential(credential);
  } catch (error) {
    print('Google Sign-In Error: $error');
    return null;
  }
}

Future signOutWithGoogle() async {
  try {
    await GoogleSignIn.instance.signOut();
  } catch (error) {
    print('Google Sign-Out Error: $error');
  }
}
