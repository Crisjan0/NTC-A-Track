import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';

/// Firebase bootstrap using the generated platform options.
class FirebaseConfig {
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } on FirebaseException catch (e) {
      // Hot-restart already initialized — ignore duplicate-app error.
      if (e.code != 'duplicate-app' && Firebase.apps.isEmpty) rethrow;
    }
  }
}
