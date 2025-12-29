import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/providers.dart';

/// Minimalist session screen - opens when notification is tapped
class ActiveSessionScreen extends StatefulWidget {
  const ActiveSessionScreen({super.key});

  @override
  State<ActiveSessionScreen> createState() => _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends State<ActiveSessionScreen>
    with TickerProviderStateMixin {
  // Stretch timer
  static const int stretchDurationSeconds = 30;
  int _secondsRemaining = stretchDurationSeconds;
  Timer? _timer;
  bool _timerStarted = false;
  bool _timerComplete = false;

  // Exercise timer (for timed exercises)
  int _exerciseSecondsRemaining = 0;
  Timer? _exerciseTimer;
  bool _exerciseTimerStarted = false;
  bool _exerciseTimerComplete = false;

  // Animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _exerciseTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startTimer() {
    if (_timerStarted) return;
    
    setState(() {
      _timerStarted = true;
      _secondsRemaining = stretchDurationSeconds;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _timer?.cancel();
          _timerComplete = true;
          HapticFeedback.mediumImpact();
        }
      });
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _timerStarted = false;
      _timerComplete = false;
      _secondsRemaining = stretchDurationSeconds;
    });
  }

  void _startExerciseTimer(int targetSeconds) {
    if (_exerciseTimerStarted) {
      // Pause the timer
      _exerciseTimer?.cancel();
      setState(() {
        _exerciseTimerStarted = false;
      });
      return;
    }
    
    setState(() {
      _exerciseTimerStarted = true;
      if (_exerciseSecondsRemaining == 0) {
        _exerciseSecondsRemaining = targetSeconds;
      }
    });

    _exerciseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_exerciseSecondsRemaining > 0) {
          _exerciseSecondsRemaining--;
        } else {
          _exerciseTimer?.cancel();
          _exerciseTimerComplete = true;
          HapticFeedback.heavyImpact();
        }
      });
    });
  }

  void _resetExerciseTimer(int targetSeconds) {
    _exerciseTimer?.cancel();
    setState(() {
      _exerciseTimerStarted = false;
      _exerciseTimerComplete = false;
      _exerciseSecondsRemaining = targetSeconds;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Consumer<ExerciseProvider>(
        builder: (context, provider, _) {
          final exercise = provider.currentExercise;

          if (exercise == null) {
            return const Center(
              child: Text('No exercise selected'),
            );
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Close button
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      onPressed: () {
                        provider.clearCurrentExercise();
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.close),
                    ),
                  ),

                  const Spacer(flex: 1),

                  // Exercise name
                  Text(
                    exercise.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  // Exercise description
                  Text(
                    exercise.description,
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  // Big rep count OR timer for timed exercises
                  if (exercise.isTimed)
                    _buildTimedExerciseDisplay(context, exercise)
                  else
                    _buildRepDisplay(context, exercise),

                  const Spacer(flex: 1),

                  // Stretch section
                  _buildStretchSection(context, exercise),

                  const Spacer(flex: 1),

                  // Complete button
                  _buildCompleteButton(context, exercise),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRepDisplay(BuildContext context, Exercise exercise) {
    return Column(
      children: [
        ScaleTransition(
          scale: _pulseAnimation,
          child: Text(
            '${exercise.currentReps}',
            style: TextStyle(
              fontSize: 120,
              fontWeight: FontWeight.w200,
              height: 1,
              color: exercise.type == ExerciseType.strength
                  ? Colors.blue
                  : Colors.orange,
            ),
          ),
        ),
        Text(
          'REPS',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 4,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ],
    );
  }

  Widget _buildTimedExerciseDisplay(BuildContext context, Exercise exercise) {
    final targetSeconds = exercise.currentReps;
    final displaySeconds = _exerciseTimerStarted || _exerciseTimerComplete
        ? _exerciseSecondsRemaining
        : targetSeconds;
    final color = exercise.type == ExerciseType.strength
        ? Colors.blue
        : Colors.orange;

    return Column(
      children: [
        // Countdown display
        GestureDetector(
          onTap: () => _startExerciseTimer(targetSeconds),
          onLongPress: () => _resetExerciseTimer(targetSeconds),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: _exerciseTimerComplete
                  ? Colors.green.withOpacity(0.15)
                  : _exerciseTimerStarted
                      ? color.withOpacity(0.1)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Text(
                    _formatExerciseTime(displaySeconds),
                    style: TextStyle(
                      fontSize: 80,
                      fontWeight: FontWeight.w200,
                      height: 1,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: _exerciseTimerComplete ? Colors.green : color,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _exerciseTimerComplete
                          ? Icons.check_circle
                          : _exerciseTimerStarted
                              ? Icons.pause_circle_outline
                              : Icons.play_circle_outline,
                      size: 20,
                      color: _exerciseTimerComplete
                          ? Colors.green
                          : Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _exerciseTimerComplete
                          ? 'DONE!'
                          : _exerciseTimerStarted
                              ? 'TAP TO PAUSE'
                              : 'TAP TO START',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 2,
                        color: _exerciseTimerComplete
                            ? Colors.green
                            : Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'SECONDS',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 4,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        Text(
          'Hold long press to reset',
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.outline.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  String _formatExerciseTime(int seconds) {
    if (seconds >= 60) {
      final mins = seconds ~/ 60;
      final secs = seconds % 60;
      return '$mins:${secs.toString().padLeft(2, '0')}';
    }
    return '$seconds';
  }

  Widget _buildStretchSection(BuildContext context, Exercise exercise) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'STRETCH',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              // Timer
              GestureDetector(
                onTap: _timerStarted ? _resetTimer : _startTimer,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _timerComplete
                        ? Colors.green.withOpacity(0.2)
                        : _timerStarted
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _timerComplete
                            ? Icons.check_circle
                            : _timerStarted
                                ? Icons.pause
                                : Icons.play_arrow,
                        size: 18,
                        color: _timerComplete
                            ? Colors.green
                            : Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatTime(_secondsRemaining),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: _timerComplete
                              ? Colors.green
                              : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            exercise.relatedStretch,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Widget _buildCompleteButton(BuildContext context, Exercise exercise) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: FilledButton(
        onPressed: () => _showCompletionDialog(context, exercise),
        style: FilledButton.styleFrom(
          backgroundColor: exercise.type == ExerciseType.strength
              ? Colors.blue
              : Colors.orange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'COMPLETE',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  Future<void> _showCompletionDialog(
    BuildContext context,
    Exercise exercise,
  ) async {
    HapticFeedback.mediumImpact();

    final wasEasy = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _WasEasyBottomSheet(exercise: exercise),
    );

    if (wasEasy == null) return; // Dismissed

    if (context.mounted) {
      final provider = context.read<ExerciseProvider>();

      final updatedExercise = await provider.completeSession(
        exerciseId: exercise.id,
        actualRepsPerformed: exercise.currentReps,
        wasEasy: wasEasy,
      );

      if (context.mounted) {
        final progressed = updatedExercise.currentReps > exercise.currentReps;

        // Show result snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              progressed
                  ? '🔥 Level up! Next time: ${updatedExercise.currentReps} reps'
                  : '✓ Session complete!',
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        Navigator.pop(context);
      }
    }
  }
}

/// Bottom sheet for "Was this easy?" dialog
class _WasEasyBottomSheet extends StatelessWidget {
  final Exercise exercise;

  const _WasEasyBottomSheet({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Was that easy?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),

          const SizedBox(height: 8),

          Text(
            'If yes, we\'ll add +2 reps next time',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),

          const SizedBox(height: 32),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'No, challenging',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Yes, easy! 💪',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
