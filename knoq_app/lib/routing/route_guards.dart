import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:knoq_app/features/auth/providers/auth_provider.dart';

/// Helper defining protected vs public paths for simple referencing
const List<String> authPaths = ['/login', '/register', '/forgot-password'];

/// The global redirect logic for GoRouter.
/// Called by the GoRouter redirect callback passing a Ref (from the routerProvider scope).
String? globalRouteGuard(BuildContext context, GoRouterState state, Ref ref) {
  final firebaseUserAsync = ref.read(authStateProvider);
  final dbUserAsync = ref.read(currentUserProvider);
  final isGoingToAuthPaths = authPaths.contains(state.matchedLocation);

  // 1. Firebase auth stream not loaded yet — let them stay wherever
  if (firebaseUserAsync.isLoading) {
    return null;
  }

  final firebaseUser = firebaseUserAsync.valueOrNull;

  // 2. Not Logged In via Firebase
  if (firebaseUser == null) {
    if (isGoingToAuthPaths) return null;
    return '/login';
  }

  // 3. Check email verification from Firebase User object (NOT from DB)
  // TEMPORARILY BYPASSED FOR TESTING
  // if (!firebaseUser.emailVerified && state.matchedLocation != '/verify-email') {
  //   if (isGoingToAuthPaths) return null;
  //   return '/verify-email';
  // }

  // 4. DB profile not loaded yet
  if (dbUserAsync.isLoading) {
    return null; // Still fetching user profile from API
  }

  final dbUser = dbUserAsync.valueOrNull;

  // 5. Firebase exists but no DB profile yet (mid-registration or API down)
  if (dbUser == null) {
    return isGoingToAuthPaths ? null : '/login';
  }

  // 6. Onboarding Lock — authenticated user with incomplete onboarding
  //    ALWAYS redirect to /onboarding, even from auth paths like /register.
  //    The only exception is /onboarding itself (to avoid infinite loop).
  if (!dbUser.onboardingComplete) {
    return state.matchedLocation == '/onboarding' ? null : '/onboarding';
  }

  // 7. Redirect authenticated users away from Auth pathways
  if (isGoingToAuthPaths || state.matchedLocation == '/onboarding' || state.matchedLocation == '/verify-email') {
    if (dbUser.role == 'coach') return '/coach-home';
    if (dbUser.role == 'super_admin') return '/admin-error';
    return '/home';
  }

  // 8. Role-based route protection
  final isCoachRoute = state.matchedLocation.startsWith('/coach');
  if (dbUser.role == 'player' && isCoachRoute) {
    return '/home';
  }

  // Coaches hitting /home should go to /coach-home
  if (dbUser.role == 'coach' && state.matchedLocation == '/home') {
    return '/coach-home';
  }

  return null;
}
