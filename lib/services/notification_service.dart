import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/models.dart';

/// Service for managing local notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Callback for when notification is tapped
  static Function(String? exerciseId)? onNotificationTapped;

  /// Initialize the notification service
  Future<void> init() async {
    if (_initialized) return;

    // Initialize timezone
    tz_data.initializeTimeZones();

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // Initialization settings for all platforms
    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    _initialized = true;
  }

  /// Handle notification tap
  static void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && onNotificationTapped != null) {
      onNotificationTapped!(payload);
    }
  }

  /// Request notification permissions (Android 13+)
  Future<bool> requestPermissions() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }

  /// Schedule all daily exercise notifications at random times within active window
  /// This should be called once per day (on app launch or via WorkManager)
  Future<void> scheduleDailyNotifications({
    required List<Exercise> availableExercises,
    required AppSettings settings,
  }) async {
    if (!settings.notificationsEnabled) return;
    if (availableExercises.isEmpty) return;

    // Cancel existing notifications first
    await cancelAllNotifications();

    final now = DateTime.now();
    final random = Random();

    // Calculate active window bounds for today
    final windowStart = DateTime(
      now.year,
      now.month,
      now.day,
      settings.activeWindowStart.hour,
      settings.activeWindowStart.minute,
    );

    final windowEnd = DateTime(
      now.year,
      now.month,
      now.day,
      settings.activeWindowEnd.hour,
      settings.activeWindowEnd.minute,
    );

    // Generate random times within the active window
    final scheduleTimes = _generateRandomTimes(
      windowStart: windowStart,
      windowEnd: windowEnd,
      count: settings.snacksPerDay,
      random: random,
    );

    // Filter out times that have already passed
    final futureTimes = scheduleTimes.where((time) => time.isAfter(now)).toList();

    // Create a shuffled list of exercises to use (avoids repeats when possible)
    final exercisesToSchedule = _selectExercisesForDay(
      availableExercises: availableExercises,
      count: futureTimes.length,
      random: random,
    );

    // Schedule notifications at each time
    for (var i = 0; i < futureTimes.length; i++) {
      final exercise = exercisesToSchedule[i];
      
      await _scheduleNotification(
        id: i,
        exercise: exercise,
        scheduledTime: futureTimes[i],
      );
    }

    debugPrint('Scheduled ${futureTimes.length} notifications for today');
  }

  /// Select exercises for the day, avoiding repeats when possible
  /// If count > available, exercises will repeat but be evenly distributed
  List<Exercise> _selectExercisesForDay({
    required List<Exercise> availableExercises,
    required int count,
    required Random random,
  }) {
    if (availableExercises.isEmpty) return [];
    
    final result = <Exercise>[];
    
    // Shuffle the available exercises to randomize order
    final shuffled = List<Exercise>.from(availableExercises)..shuffle(random);
    
    // Fill the result list, cycling through shuffled exercises if needed
    for (var i = 0; i < count; i++) {
      result.add(shuffled[i % shuffled.length]);
    }
    
    // Shuffle again so the order isn't predictable
    result.shuffle(random);
    
    return result;
  }

  /// Generate random times within the active window
  List<DateTime> _generateRandomTimes({
    required DateTime windowStart,
    required DateTime windowEnd,
    required int count,
    required Random random,
  }) {
    final times = <DateTime>[];
    final windowDurationMinutes = windowEnd.difference(windowStart).inMinutes;

    // Minimum gap between notifications (in minutes)
    const minGap = 30;

    if (windowDurationMinutes < minGap * count) {
      // Window too small for all notifications, distribute evenly
      final interval = windowDurationMinutes ~/ count;
      for (var i = 0; i < count; i++) {
        times.add(windowStart.add(Duration(minutes: interval * i + interval ~/ 2)));
      }
    } else {
      // Generate random times with minimum gap
      for (var i = 0; i < count; i++) {
        DateTime newTime;
        var attempts = 0;
        const maxAttempts = 100;

        do {
          final randomMinutes = random.nextInt(windowDurationMinutes);
          newTime = windowStart.add(Duration(minutes: randomMinutes));
          attempts++;
        } while (_isTooCloseToExisting(newTime, times, minGap) && 
                 attempts < maxAttempts);

        times.add(newTime);
      }
    }

    // Sort times chronologically
    times.sort();
    return times;
  }

  /// Check if a time is too close to existing scheduled times
  bool _isTooCloseToExisting(DateTime time, List<DateTime> existing, int minGapMinutes) {
    for (final existingTime in existing) {
      final diff = time.difference(existingTime).inMinutes.abs();
      if (diff < minGapMinutes) {
        return true;
      }
    }
    return false;
  }

  /// Schedule a single notification
  Future<void> _scheduleNotification({
    required int id,
    required Exercise exercise,
    required DateTime scheduledTime,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'exercise_snacks',
      'Exercise Snacks',
      channelDescription: 'Notifications for exercise snack reminders',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'Exercise time!',
      icon: '@mipmap/ic_launcher',
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    // Create notification body with exercise info
    final body = '${exercise.currentReps} reps • ${exercise.relatedStretch.split('.').first}';

    await _notifications.zonedSchedule(
      id,
      '🏋️ ${exercise.name}',
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: exercise.id,
    );

    debugPrint('Scheduled: ${exercise.name} at $scheduledTime');
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Show an immediate test notification
  Future<void> showTestNotification(Exercise exercise) async {
    final androidDetails = AndroidNotificationDetails(
      'exercise_snacks',
      'Exercise Snacks',
      channelDescription: 'Notifications for exercise snack reminders',
      importance: Importance.high,
      priority: Priority.high,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      999,
      '🏋️ ${exercise.name}',
      '${exercise.currentReps} reps • Tap to start!',
      notificationDetails,
      payload: exercise.id,
    );
  }

  /// Get pending notifications (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}
