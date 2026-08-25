import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// The very first thing a signed-out visitor sees — sells the app in one
// screen, then gates everything else behind Sign up / Log in. The router's
// redirect logic (main.dart) sends any unauthenticated request here, so
// there's no way to browse the calendar or dashboard without an account.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            children: [
              const Spacer(flex: 3),

              // -----------------------------------------------------------
              // BRAND MARK
              // -----------------------------------------------------------
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.favorite_rounded,
                  size: 44,
                  color: colors.primary,
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'FamilyPulse',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                "Family life isn't missing another group chat.",
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 12),

              Text(
                "It's missing a heartbeat. FamilyPulse turns scattered "
                'texts, forgotten pickups, and "wait — who\'s free '
                'Saturday?" into one shared rhythm: a live calendar, a '
                "real-time pulse of everyone's day, and zero double-booked "
                'soccer practice.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),

              const Spacer(flex: 4),

              // -----------------------------------------------------------
              // AUTH ENTRY POINTS — the only way into the app
              // -----------------------------------------------------------
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.push('/register'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Create account'),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.push('/login'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Log in'),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
