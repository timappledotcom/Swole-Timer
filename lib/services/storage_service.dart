import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

/// Service for persisting app data using SharedPreferences
class StorageService {
  static const String _exercisesKey = 'exercises';
  static const String _settingsKey = 'app_settings';
  static const String _lastScheduledDateKey = 'last_scheduled_date';

  SharedPreferences? _prefs;

  /// Initialize the storage service
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Ensure prefs are initialized
  Future<SharedPreferences> get prefs async {
    if (_prefs == null) {
      await init();
    }
    return _prefs!;
  }

  // ============ EXERCISES ============

  /// Save exercises list to storage
  Future<void> saveExercises(List<Exercise> exercises) async {
    final p = await prefs;
    final jsonList = exercises.map((e) => e.toJson()).toList();
    await p.setString(_exercisesKey, jsonEncode(jsonList));
  }

  /// Load exercises from storage
  /// Returns null if no exercises are stored (first launch)
  Future<List<Exercise>?> loadExercises() async {
    final p = await prefs;
    final jsonString = p.getString(_exercisesKey);
    
    if (jsonString == null) {
      return null;
    }

    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => Exercise.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // If parsing fails, return null to trigger seed data
      print('Error loading exercises: $e');
      return null;
    }
  }

  /// Update a single exercise in storage
  Future<void> updateExercise(Exercise updatedExercise) async {
    final exercises = await loadExercises();
    if (exercises == null) return;

    final index = exercises.indexWhere((e) => e.id == updatedExercise.id);
    if (index != -1) {
      exercises[index] = updatedExercise;
      await saveExercises(exercises);
    }
  }

  // ============ SETTINGS ============

  /// Save app settings to storage
  Future<void> saveSettings(AppSettings settings) async {
    final p = await prefs;
    await p.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  /// Load app settings from storage
  /// Returns null if no settings are stored (first launch)
  Future<AppSettings?> loadSettings() async {
    final p = await prefs;
    final jsonString = p.getString(_settingsKey);
    
    if (jsonString == null) {
      return null;
    }

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return AppSettings.fromJson(json);
    } catch (e) {
      print('Error loading settings: $e');
      return null;
    }
  }

  // ============ SCHEDULING ============

  /// Save the date when notifications were last scheduled
  Future<void> saveLastScheduledDate(DateTime date) async {
    final p = await prefs;
    await p.setString(_lastScheduledDateKey, date.toIso8601String());
  }

  /// Get the date when notifications were last scheduled
  Future<DateTime?> getLastScheduledDate() async {
    final p = await prefs;
    final dateString = p.getString(_lastScheduledDateKey);
    
    if (dateString == null) {
      return null;
    }

    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// Check if notifications need to be scheduled today
  Future<bool> needsSchedulingToday() async {
    final lastScheduled = await getLastScheduledDate();
    if (lastScheduled == null) return true;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastScheduledDay = DateTime(
      lastScheduled.year,
      lastScheduled.month,
      lastScheduled.day,
    );

    return !today.isAtSameMomentAs(lastScheduledDay);
  }

  // ============ UTILITY ============

  /// Clear all stored data (for testing/reset)
  Future<void> clearAll() async {
    final p = await prefs;
    await p.clear();
  }
}
