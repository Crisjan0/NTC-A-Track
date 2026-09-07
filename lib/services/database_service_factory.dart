import 'database_service_interface.dart';
import 'supabase_database_service.dart';

/// Factory for creating database service instances.
/// Uses Supabase (cloud) only.
class DatabaseServiceFactory {
  static DatabaseServiceInterface? _instance;
  static bool _initialized = false;
  
  static DatabaseServiceInterface get instance {
    _instance ??= SupabaseDatabaseService.instance as DatabaseServiceInterface;
    return _instance!;
  }
  
  static Future<void> initialize() async {
    if (_initialized) return;
    
    await SupabaseDatabaseService.initialize();
    _initialized = true;
  }
  
  static void reset() {
    _instance = null;
    _initialized = false;
  }
}