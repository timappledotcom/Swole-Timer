import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/providers.dart';
import 'services/services.dart';
import 'screens/screens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  final storageService = StorageService();
  await storageService.init();

  final notificationService = NotificationService();
  await notificationService.init();
  await notificationService.requestPermissions();

  runApp(
    SwoleTimerApp(storageService: storageService),
  );
}

class SwoleTimerApp extends StatefulWidget {
  final StorageService storageService;

  const SwoleTimerApp({
    super.key,
    required this.storageService,
  });

  @override
  State<SwoleTimerApp> createState() => _SwoleTimerAppState();
}

class _SwoleTimerAppState extends State<SwoleTimerApp> {
  late final ExerciseProvider _exerciseProvider;
  late final SettingsProvider _settingsProvider;

  @override
  void initState() {
    super.initState();
    _exerciseProvider = ExerciseProvider(storageService: widget.storageService);
    _settingsProvider = SettingsProvider(storageService: widget.storageService);

    // Set up notification tap handler
    NotificationService.onNotificationTapped = _handleNotificationTap;

    // Initialize providers
    _initializeProviders();
  }

  Future<void> _initializeProviders() async {
    await Future.wait([
      _exerciseProvider.init(),
      _settingsProvider.init(),
    ]);
  }

  void _handleNotificationTap(String? exerciseId) {
    if (exerciseId != null) {
      _exerciseProvider.setCurrentExercise(exerciseId);
      // Navigation will be handled by the navigator key
      _navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => const ActiveSessionScreen(),
        ),
      );
    }
  }

  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _exerciseProvider),
        ChangeNotifierProvider.value(value: _settingsProvider),
      ],
      child: MaterialApp(
        title: 'Swole Timer',
        navigatorKey: _navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepOrange,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepOrange,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
        ),
        themeMode: ThemeMode.system,
        home: Consumer<SettingsProvider>(
          builder: (context, settingsProvider, _) {
            if (settingsProvider.isLoading) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!settingsProvider.settings.hasSeenOnboarding) {
              return OnboardingScreen(
                onComplete: () {
                  settingsProvider.completeOnboarding();
                },
              );
            }

            return const HomeScreen();
          },
        ),
      ),
    );
  }
}
