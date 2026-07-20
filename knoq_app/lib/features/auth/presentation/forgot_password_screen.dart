import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:knoq_app/core/widgets/knoq_button.dart';
import 'package:knoq_app/core/widgets/knoq_text_field.dart';
import 'package:knoq_app/core/utils/validators.dart';
import 'package:knoq_app/features/auth/providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;
  bool _sent = false;

  void _sendReset() async {
    final email = _emailCtrl.text.trim();
    if (Validators.validateEmail(email) != null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid email')));
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).resetPassword(email);
      setState(() => _sent = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _sent 
        ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.check_circle_outline, size: 80, color: theme.colorScheme.primary),
              const SizedBox(height: 24),
              Text(
                'Check your email',
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'We sent reset instructions to ${_emailCtrl.text}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              KnoqButton(
                text: 'Back to Login', 
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/login');
                  }
                }
              )
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter the email associated with your account and we will send you a reset link.',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              KnoqTextField(
                label: 'Email Address',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 32),
              KnoqButton(
                text: 'Send Reset Link',
                isLoading: _isLoading,
                onPressed: _sendReset,
              ),
            ],
          ),
      ),
    );
  }
}
