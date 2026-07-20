import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knoq_app/core/widgets/knoq_button.dart';
import 'package:knoq_app/core/widgets/knoq_text_field.dart';
import 'package:knoq_app/features/auth/providers/auth_provider.dart';
import 'package:knoq_app/services/analytics_service.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;
  
  // Form Data
  final _nameCtrl = TextEditingController();
  int _age = 18;
  String _battingHand = 'Right';
  final _academyCodeCtrl = TextEditingController();
  bool _isLoading = false;

  bool get _isCoach {
    final user = ref.read(currentUserProvider).valueOrNull;
    return user?.role == 'coach';
  }

  int get _totalPages => _isCoach ? 2 : 3;

  void _nextPage() {
    if (_currentPage == (_isCoach ? 0 : 1) && _nameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name is required')));
      return;
    }
    if (_currentPage < _totalPages - 1) {
      _pageCtrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() async {
    setState(() => _isLoading = true);
    try {
      final userRepo = ref.read(userRepositoryProvider);
      
      if (_isCoach) {
        // Coach onboarding: just name and mark complete
        final fields = {
          'name': _nameCtrl.text,
          'onboarding_complete': true,
        };
        await userRepo.updateProfile(fields);
      } else {
        // Player onboarding: name, age, batting hand
        final fields = {
          'name': _nameCtrl.text,
          'age': _age,
          'batting_hand': _battingHand,
          'onboarding_complete': true,
        };
        await userRepo.updateProfile(fields);

        // If academy code was provided, call the dedicated join endpoint
        if (_academyCodeCtrl.text.trim().isNotEmpty) {
          try {
            await userRepo.joinAcademy(_academyCodeCtrl.text.trim());
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Profile saved. Academy join failed: $e'), backgroundColor: Colors.orange),
              );
            }
          }
        }
      }

      ref.read(analyticsServiceProvider).logOnboardingComplete();
      ref.invalidate(currentUserProvider);
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCoach = _isCoach;
    final totalPages = _totalPages;

    final List<Widget> pages = isCoach
        ? [_buildCoachWelcomePage(context), _buildCoachProfilePage(context)]
        : [_buildPlayerWelcomePage(context), _buildPlayerProfilePage(context), _buildJoinAcademyPage(context)];

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: pages,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(totalPages, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: _currentPage == i ? 24 : 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: _currentPage == i
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                ),
              )),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: KnoqButton(
                text: _currentPage == totalPages - 1 ? 'Finish & Start' : 'Next',
                isLoading: _isLoading,
                onPressed: _nextPage,
              ),
            ),
            if (!isCoach && _currentPage == totalPages - 1) 
              TextButton(
                onPressed: () { _academyCodeCtrl.clear(); _finishOnboarding(); },
                child: const Text('Skip for now'),
              )
          ],
        ),
      ),
    ));
  }

  // ── Player Pages ──

  Widget _buildPlayerWelcomePage(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_graph, size: 100, color: theme.colorScheme.primary),
          const SizedBox(height: 32),
          Text('Analyze Your Swing', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 16),
          const Text('Connect your KnoQ Bat sensor to get real-time feedback on power, swing speed, and sweet-spot analytics.', textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildPlayerProfilePage(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: ListView(
        children: [
          const SizedBox(height: 48),
          Text('About You', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 24),
          KnoqTextField(label: 'Full Name', controller: _nameCtrl),
          const SizedBox(height: 24),
          Text('Age: $_age', style: theme.textTheme.bodyLarge),
          Slider(
            value: _age.toDouble(),
            min: 8, max: 60,
            divisions: 52,
            onChanged: (v) => setState(() => _age = v.toInt()),
          ),
          const SizedBox(height: 24),
          Text('Batting Hand', style: theme.textTheme.bodyLarge),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Right'), value: 'Right', groupValue: _battingHand,
                  onChanged: (v) => setState(() => _battingHand = v!),
                )
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Left'), value: 'Left', groupValue: _battingHand,
                  onChanged: (v) => setState(() => _battingHand = v!),
                )
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildJoinAcademyPage(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: ListView(
        children: [
           const SizedBox(height: 48),
          Text('Join an Academy', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 16),
          const Text('If your coach gave you a code, enter it below to join their roster.'),
          const SizedBox(height: 24),
          KnoqTextField(label: 'Academy Code (Optional)', controller: _academyCodeCtrl),
        ],
      ),
    );
  }

  // ── Coach Pages ──

  Widget _buildCoachWelcomePage(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school, size: 100, color: theme.colorScheme.primary),
          const SizedBox(height: 32),
          Text('Welcome, Coach', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 16),
          const Text(
            'Your dashboard will show your assigned players, their sessions, and performance trends. '
            'You can leave notes and compare players side-by-side.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCoachProfilePage(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: ListView(
        children: [
          const SizedBox(height: 48),
          Text('Your Profile', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 24),
          KnoqTextField(label: 'Full Name', controller: _nameCtrl),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Academy Info', style: theme.textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your academy admin has assigned you as a coach. '
                    'Players from your academy will appear in your dashboard once they join.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
