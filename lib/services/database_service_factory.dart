import 'database_service.dart';
import 'database_service_interface.dart';
import 'supabase_database_service.dart';

/// Factory for creating database service instances.
/// Set [useSupabase] to true to use Supabase (cloud), false for SQLite (local).
class DatabaseServiceFactory {
  static bool _useSupabase = true; // Change to false for local SQLite
  
  static DatabaseServiceInterface? _instance;
  
  static bool get useSupabase => _useSupabase;
  
  static set useSupabase(bool value) {
    _useSupabase = value;
    _instance = null; // Reset instance when switching
  }
  
static DatabaseServiceInterface get instance {
    _instance ??= _useSupabase
        ? SupabaseDatabaseService.instance as DatabaseServiceInterface
        : DatabaseService.instance as DatabaseServiceInterface;
    return _instance!;
  }
  
  static Future<void> initialize() async {
    if (_useSupabase) {
      await SupabaseDatabaseService.initialize();
    }
  }
  
  static void reset() {
    _instance = null;
  }
}