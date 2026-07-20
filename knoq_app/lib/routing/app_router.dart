import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import 'package:knoq_app/routing/route_guards.dart';
import 'package:knoq_app/routing/main_scaffold.dart';
import 'package:knoq_app/routing/coach_scaffold.dart';
import 'package:knoq_app/features/auth/providers/auth_provider.dart';

import 'package:knoq_app/features/auth/presentation/login_screen.dart';
import 'package:knoq_app/features/auth/presentation/register_screen.dart';
import 'package:knoq_app/features/auth/presentation/forgot_password_screen.dart';
import 'package:knoq_app/features/auth/presentation/email_verification_screen.dart';
import 'package:knoq_app/features/auth/presentation/onboarding_screen.dart';

import 'package:knoq_app/features/home/presentation/player_home_screen.dart';
import 'package:knoq_app/features/session/presentation/permission_check_screen.dart';
import 'package:knoq_app/features/session/presentation/ble_scan_screen.dart';
import 'package:knoq_app/features/session/presentation/live_session_screen.dart';
import 'package:knoq_app/features/session/presentation/session_summary_screen.dart';
import 'package:knoq_app/features/session/presentation/clip_verification_screen.dart';

import 'package:knoq_app/features/session/presentation/note_replies_screen.dart';
import 'package:knoq_app/features/session/presentation/session_list_screen.dart';
import 'package:knoq_app/features/session/presentation/shot_history_screen.dart';

import 'package:knoq_app/features/insights/presentation/coaching_insights_screen.dart';
import 'package:knoq_app/features/analytics/presentation/analytics_dashboard_screen.dart';
import 'package:knoq_app/features/profile/presentation/profile_screen.dart';
import 'package:knoq_app/features/profile/presentation/settings_screen.dart';

import 'package:knoq_app/features/coach/presentation/coach_dashboard_screen.dart';
import 'package:knoq_app/features/coach/presentation/player_detail_screen.dart';
import 'package:knoq_app/features/coach/presentation/session_detail_coach_screen.dart';
import 'package:knoq_app/features/coach/presentation/compare_players_screen.dart';
import 'package:knoq_app/features/auth/domain/user_model.dart';
import 'package:knoq_app/features/session/domain/session_model.dart';

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
    ref.listen(currentUserProvider, (_, __) => notifyListeners());
  }
}

final routerNotifierProvider = Provider((ref) => RouterNotifier(ref));

/// App Router instance initialized securely via Riverpod.
final routerProvider = Provider<GoRouter>((ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  final sectionNavigatorKeyHome = GlobalKey<NavigatorState>(debugLabel: 'sectionHome');
  final sectionNavigatorKeyAnalytics = GlobalKey<NavigatorState>(debugLabel: 'sectionAnalytics');
  final sectionNavigatorKeyInsights = GlobalKey<NavigatorState>(debugLabel: 'sectionInsights');
  final sectionNavigatorKeyProfile = GlobalKey<NavigatorState>(debugLabel: 'sectionProfile');

  // Coach navigation keys
  final coachNavKeyDashboard = GlobalKey<NavigatorState>(debugLabel: 'coachDashboard');
  final coachNavKeyCompare = GlobalKey<NavigatorState>(debugLabel: 'coachCompare');
  final coachNavKeyProfile = GlobalKey<NavigatorState>(debugLabel: 'coachProfile');

  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/home',
    refreshListenable: notifier,
    redirect: (context, state) => globalRouteGuard(context, state, ref),
    routes: [
      // ----------------------------------------
      // Auth & Unprotected Core
      // ----------------------------------------
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(path: '/verify-email', builder: (context, state) => const EmailVerificationScreen()),
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),

      // ----------------------------------------
      // Role: Config Error States
      // ----------------------------------------
      GoRoute(
        path: '/admin-error', 
        builder: (context, state) => Scaffold(
          body: Center(child: Text('Super Admin portal is Web Only.', style: Theme.of(context).textTheme.headlineSmall)),
        ),
      ),

      // ----------------------------------------
      // Coach Shell with Bottom Navigation
      // ----------------------------------------
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return CoachScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: coachNavKeyDashboard,
            routes: [
              GoRoute(
                path: '/coach-home',
                builder: (context, state) => const CoachDashboardScreen(),
                routes: [

                  GoRoute(
                    path: 'player/:id',
                    builder: (context, state) {
                      final player = state.extra as UserModel;
                      return PlayerDetailScreen(player: player);
                    },
                  ),
                  GoRoute(
                    path: 'session/:id',
                    builder: (context, state) {
                      final session = state.extra as SessionModel;
                      return SessionDetailCoachScreen(session: session);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: coachNavKeyCompare,
            routes: [
              GoRoute(
                path: '/coach-compare',
                builder: (context, state) => const ComparePlayersScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: coachNavKeyProfile,
            routes: [
              GoRoute(
                path: '/coach-profile',
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'settings',
                    builder: (context, state) => const SettingsScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // ----------------------------------------
      // Live Session Sub-Flow (Modals/Fullscreen essentially)
      // ----------------------------------------
      GoRoute(path: '/permission-check', builder: (context, state) => const PermissionCheckScreen()),
      GoRoute(path: '/ble-scan', builder: (context, state) => const BleScanScreen()),
      GoRoute(path: '/live-session', builder: (context, state) => const LiveSessionScreen()),
      GoRoute(path: '/session-summary', builder: (context, state) => const SessionSummaryScreen()),
      GoRoute(
        path: '/clip-verification/:sessionId',
        builder: (context, state) {
          final sessionId = state.pathParameters['sessionId']!;
          return ClipVerificationScreen(sessionId: sessionId);
        },
      ),

      // Deep linked history isolated from bottom nav stack limits
      GoRoute(path: '/session-list', builder: (context, state) => const SessionListScreen()),
      GoRoute(
        path: '/session-history/:id', 
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ShotHistoryScreen(sessionId: id);
        }
      ),
      GoRoute(
        path: '/note-replies/:id',
        builder: (context, state) {
          final note = state.extra as Map<String, dynamic>;
          return NoteRepliesScreen(note: note);
        }
      ),

      // ----------------------------------------
      // Player Persistent Bottom Navigation Area
      // ----------------------------------------
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
           return MainScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: sectionNavigatorKeyHome,
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const PlayerHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: sectionNavigatorKeyAnalytics,
            routes: [
              GoRoute(
                path: '/analytics',
                builder: (context, state) => const AnalyticsDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: sectionNavigatorKeyInsights,
            routes: [
              GoRoute(
                path: '/insights',
                builder: (context, state) => const CoachingInsightsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: sectionNavigatorKeyProfile,
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'settings',
                    builder: (context, state) => const SettingsScreen(),
                  )
                ]
              ),
            ],
          ),
        ]
      )

    ],
  );
});
