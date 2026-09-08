import 'database_service_interface.dart';
import 'firebase_database_service.dart';
import '../config/firebase_config.dart';

/// Factory for creating database service instances.
/// Uses Firebase Cloud Firestore.
class DatabaseServiceFactory {
  static DatabaseServiceInterface? _instance;
  static bool _initialized = false;

  static DatabaseServiceInterface get instance {
    _instance ??= FirebaseDatabaseService.instance as DatabaseServiceInterface;
    return _instance!;
  }

  static Future<void> initialize() async {
    if (_initialized) return;

    await FirebaseConfig.initialize();
    _initialized = true;
  }

  static void reset() {
    _instance = null;
    _initialized = false;
  }
}
