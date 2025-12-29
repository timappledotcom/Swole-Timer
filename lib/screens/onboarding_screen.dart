import 'package:flutter/material.dart';

/// Onboarding screen explaining the Greasing the Groove system
class OnboardingScreen extends StatefulWidget {
  final bool isRevisit;
  final VoidCallback onComplete;

  const OnboardingScreen({
    super.key,
    this.isRevisit = false,
    required this.onComplete,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPage> _pages = [
    _OnboardingPage(
      icon: Icons.directions_walk,
      title: 'Walk Every Day',
      subtitle: '30 Minutes for a Healthier You',
      body: '''Walking is the foundation of good health. Just 30 minutes of walking each day can:

• Improve cardiovascular health
• Boost mood and reduce stress
• Aid digestion and metabolism
• Strengthen bones and muscles

Track your daily walk with a simple checkbox. Build a streak and watch your progress grow week by week!''',
    ),
    _OnboardingPage(
      icon: Icons.fitness_center,
      title: 'Greasing the Groove',
      subtitle: 'The Soviet Secret to Strength',
      body: '''This method was popularized by Pavel Tsatsouline, a former Soviet Special Forces instructor.

The idea is simple: practice a movement frequently throughout the day, but never to failure. By staying fresh, you train your nervous system to become more efficient at the movement.

"Strength is a skill. And like any skill, it must be practiced."''',
    ),
    _OnboardingPage(
      icon: Icons.calendar_today,
      title: 'Sport Days vs Rest Days',
      subtitle: 'Balance Strength & Mobility',
      body: '''On SPORT DAYS (default: Tue, Thu, Sat), you'll focus on mobility work—stretches and movements that keep you limber and prevent injury.

On REST DAYS, you'll get strength exercises like push-ups, squats, and planks to build muscle while recovering.

Toggle your sport days in Settings to match your schedule.''',
    ),
    _OnboardingPage(
      icon: Icons.notifications_active,
      title: 'Exercise Snacks',
      subtitle: 'Random Reminders Throughout the Day',
      body: '''Set your "active window" (e.g., 7 AM to 8 PM) and how many "snacks" you want per day.

The app will send you random notifications during that window. Each notification is a mini workout—just a few reps and a quick stretch.

No gym required. Do them wherever you are.''',
    ),
    _OnboardingPage(
      icon: Icons.trending_up,
      title: 'Progressive Overload',
      subtitle: 'Slow & Steady Gains',
      body: '''After each session, you'll be asked: "Was that easy?"

If you say YES (and completed all reps), we'll add +2 reps next time. If not, no worries—you'll stay at the same level until you're ready.

This gentle progression builds real, lasting strength without burnout.''',
    ),
    _OnboardingPage(
      icon: Icons.repeat,
      title: 'Anti-Repetition',
      subtitle: 'Variety Keeps It Fresh',
      body: '''The app won't give you the same exercise two days in a row. This ensures variety and prevents overuse of any single muscle group.

With 30+ exercises in the pool, you'll stay engaged and hit your body from all angles.

Ready to get strong, the old-school way?''',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onComplete();
    }
  }

  void _skip() {
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button (top right)
            if (!isLastPage)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextButton(
                    onPressed: _skip,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ),
                ),
              )
            else
              const SizedBox(height: 56),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),

            // Page indicator dots
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _nextPage,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    isLastPage ? "LET'S GO" : 'NEXT',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),

          const SizedBox(height: 40),

          // Title
          Text(
            page.title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Subtitle
          Text(
            page.subtitle,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Body text
          Text(
            page.body,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String subtitle;
  final String body;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.body,
  });
}
