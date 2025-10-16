import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'src/providers/providers.dart';
import 'src/features/auth/login_screen.dart';
import 'src/features/dashboard/dashboard_screen.dart';
import 'src/features/coach_dashboard/coach_dashboard_screen.dart';
import 'src/services/error_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: CoachesEyeApp()));
}

class CoachesEyeApp extends ConsumerStatefulWidget {
  const CoachesEyeApp({super.key});

  @override
  ConsumerState<CoachesEyeApp> createState() => _CoachesEyeAppState();
}

class _CoachesEyeAppState extends ConsumerState<CoachesEyeApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Handle app lifecycle changes for BLE service
    try {
      final bleService = ref.read(bleServiceProvider);
      bleService.handleAppLifecycle(state);
    } catch (e) {
      ErrorHandler().handleError(e, context: 'App Lifecycle');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coach\'s Eye AI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Wrapper widget that handles authentication state
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final currentUserProfile = ref.watch(currentUserProfileProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          // User is signed in, show appropriate dashboard based on role
          return currentUserProfile.when(
            data: (userModel) {
              if (userModel?.role == 'coach') {
                return const CoachDashboardScreen();
              } else {
                return const DashboardScreen();
              }
            },
            loading: () => const SplashScreen(),
            error: (error, stack) => ErrorScreen(error: error.toString()),
          );
        } else {
          // User is not signed in, show login screen
          return const LoginScreen();
        }
      },
      loading: () => const SplashScreen(),
      error: (error, stack) => ErrorScreen(error: error.toString()),
    );
  }
}

/// Splash screen shown while checking authentication state
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sports_cricket, size: 120, color: Colors.white),
            const SizedBox(height: 24),
            const Text(
              'Coach\'s Eye AI',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Smart Cricket Training',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

/// Error screen shown when authentication check fails
class ErrorScreen extends StatelessWidget {
  final String error;

  const ErrorScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[50],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 80, color: Colors.red),
              const SizedBox(height: 24),
              const Text(
                'Something went wrong',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                error,
                style: const TextStyle(fontSize: 16, color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  // Restart the app
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const AuthWrapper(),
                    ),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
