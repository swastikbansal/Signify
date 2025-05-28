import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

Future initFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: "AIzaSyD6lO3UDf10T8ie6dlCIuH_fbPBLUhgmjs",
            authDomain: "signify-ddf70.firebaseapp.com",
            projectId: "signify-ddf70",
            storageBucket: "signify-ddf70.firebasestorage.app",
            messagingSenderId: "608567453337",
            appId: "1:608567453337:web:bfa5afda8366a5ad9dfa08",
            measurementId: "G-M4YPCPDN20"));
  } else {
    await Firebase.initializeApp();
  }
}
