import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:knoq_app/core/widgets/knoq_button.dart';
import 'package:knoq_app/core/widgets/knoq_text_field.dart';
import 'package:knoq_app/core/utils/validators.dart';
import 'package:knoq_app/features/auth/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    await ref.read(authNotifierProvider.notifier).login(
      _emailCtrl.text.trim(),
      _passwordCtrl.text.trim(),
    );
    
    final state = ref.read(authNotifierProvider);
    if (state.hasError && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.error.toString()), backgroundColor: Colors.red),
      );
    } else if (!state.hasError && mounted) {
      // Explicit navigation fallback — GoRouter's refreshListenable can
      // swallow rapid successive notifications, so we navigate manually.
      final dbUser = ref.read(currentUserProvider).valueOrNull;
      if (dbUser != null) {
        if (!dbUser.onboardingComplete) {
          context.go('/onboarding');
        } else if (dbUser.role == 'coach') {
          context.go('/coach-home');
        } else {
          context.go('/home');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),
                Icon(Icons.sports_cricket, size: 64, color: theme.colorScheme.primary),
                const SizedBox(height: 24),
                Text(
                  'Welcome to KnoQ',
                  style: theme.textTheme.headlineLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Log in to review your shot insights.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                KnoqTextField(
                  label: 'Email Address',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                ),
                const SizedBox(height: 24),
                KnoqTextField(
                  label: 'Password',
                  controller: _passwordCtrl,
                  isPassword: true,
                  validator: (v) => v!.isEmpty ? 'Enter your password' : null,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    child: Text(
                      'Forgot password?',
                      style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                KnoqButton(
                  text: 'Log In',
                  isLoading: isLoading,
                  onPressed: _handleLogin,
                ),
                const SizedBox(height: 16),
                KnoqButton(
                  text: 'Continue with Google',
                  type: KnoqButtonType.secondary,
                  onPressed: () {
                    // Requires Native Google Sign In Plugin config 
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Google Sign-In coming soon!'))
                    );
                  },
                ),
                const SizedBox(height: 16),
                KnoqButton(
                  text: 'Try Demo Mode',
                  type: KnoqButtonType.secondary,
                  onPressed: () {
                    _emailCtrl.text = 'player1_demo@knoq.in';
                    _passwordCtrl.text = 'demo123';
                    _handleLogin();
                  },
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account?", style: theme.textTheme.bodyMedium),
                    TextButton(
                      onPressed: () => context.push('/register'),
                      child: const Text('Register', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
