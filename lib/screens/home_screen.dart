import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import 'active_session_screen.dart';
import 'settings_screen.dart';

/// Home screen displaying today's schedule and exercise overview
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _exercisePoolExpanded = false;

  @override
  void initState() {
    super.initState();
    _scheduleNotificationsIfNeeded();
  }

  Future<void> _scheduleNotificationsIfNeeded() async {
    final storageService = StorageService();
    final needsScheduling = await storageService.needsSchedulingToday();

    if (needsScheduling && mounted) {
      final exerciseProvider = context.read<ExerciseProvider>();
      final settingsProvider = context.read<SettingsProvider>();

      final availableExercises = exerciseProvider
          .getAvailableExercisesForToday(settingsProvider.settings);

      await NotificationService().scheduleDailyNotifications(
        availableExercises: availableExercises,
        settings: settingsProvider.settings,
      );

      await storageService.saveLastScheduledDate(DateTime.now());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Swole Timer'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Consumer2<ExerciseProvider, SettingsProvider>(
        builder: (context, exerciseProvider, settingsProvider, _) {
          if (exerciseProvider.isLoading || settingsProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: _scheduleNotificationsIfNeeded,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildTodayCard(settingsProvider),
                const SizedBox(height: 16),
                _buildActiveWindowCard(settingsProvider),
                const SizedBox(height: 16),
                _buildQuickStartButton(exerciseProvider, settingsProvider),
                const SizedBox(height: 16),
                _buildTodaysExercisesCard(exerciseProvider, settingsProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTodayCard(SettingsProvider settingsProvider) {
    final isSportDay = settingsProvider.isTodaySportDay;
    final dayName = AppSettings.getWeekdayName(DateTime.now().weekday);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              dayName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSportDay
                    ? Colors.orange.withOpacity(0.2)
                    : Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSportDay ? Icons.sports_gymnastics : Icons.fitness_center,
                    color: isSportDay ? Colors.orange : Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isSportDay ? 'Sport Day' : 'Rest Day',
                    style: TextStyle(
                      color: isSportDay ? Colors.orange : Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSportDay
                  ? 'Focus on Mobility exercises'
                  : 'Focus on Strength exercises',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveWindowCard(SettingsProvider settingsProvider) {
    final settings = settingsProvider.settings;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Active Window',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppSettings.formatTimeOfDay(settings.activeWindowStart),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Icon(Icons.arrow_forward),
                ),
                Text(
                  AppSettings.formatTimeOfDay(settings.activeWindowEnd),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '${settings.snacksPerDay} exercise snacks scheduled',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaysExercisesCard(
    ExerciseProvider exerciseProvider,
    SettingsProvider settingsProvider,
  ) {
    final exercises =
        exerciseProvider.getAvailableExercisesForToday(settingsProvider.settings);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Collapsible header
          InkWell(
            onTap: () {
              setState(() {
                _exercisePoolExpanded = !_exercisePoolExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.list_alt, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Today\'s Exercise Pool',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${exercises.length}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _exercisePoolExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down),
                  ),
                ],
              ),
            ),
          ),
          // Collapsible content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Column(
                children: [
                  if (exercises.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          'All exercises were performed yesterday.\nThey\'ll be available tomorrow!',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    ...exercises.map((exercise) => _buildExerciseTile(exercise)),
                ],
              ),
            ),
            crossFadeState: _exercisePoolExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseTile(Exercise exercise) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: exercise.type == ExerciseType.strength
            ? Colors.blue.withOpacity(0.2)
            : Colors.orange.withOpacity(0.2),
        child: Icon(
          exercise.type == ExerciseType.strength
              ? Icons.fitness_center
              : Icons.self_improvement,
          color: exercise.type == ExerciseType.strength
              ? Colors.blue
              : Colors.orange,
          size: 20,
        ),
      ),
      title: Text(exercise.name),
      subtitle: Text(exercise.isTimed 
          ? '${exercise.currentReps} seconds' 
          : '${exercise.currentReps} reps'),
      trailing: exercise.wasPerformedToday()
          ? const Icon(Icons.check_circle, color: Colors.green)
          : null,
      onTap: () => _startSession(exercise),
    );
  }

  Widget _buildQuickStartButton(
    ExerciseProvider exerciseProvider,
    SettingsProvider settingsProvider,
  ) {
    return ElevatedButton.icon(
      onPressed: () {
        final exercise =
            exerciseProvider.selectRandomExercise(settingsProvider.settings);
        if (exercise != null) {
          _startSession(exercise);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No exercises available for today!'),
            ),
          );
        }
      },
      icon: const Icon(Icons.play_arrow),
      label: const Text('Quick Start Random Exercise'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(16),
        minimumSize: const Size(double.infinity, 56),
      ),
    );
  }

  void _startSession(Exercise exercise) {
    context.read<ExerciseProvider>().setCurrentExerciseObject(exercise);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ActiveSessionScreen()),
    );
  }
}
