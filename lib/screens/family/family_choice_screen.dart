import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

class FamilyChoiceScreen extends ConsumerWidget {
  const FamilyChoiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome'),
        actions: [
          IconButton(
            onPressed: () async {
              final confirmed = await _confirmSignOut(context);
              if (!confirmed || !context.mounted) return;

              try {
                await ref.read(authServiceProvider).signOut();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Could not sign out: $e'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'You\'re not part of a family yet.',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.push('/create-family'),
              child: const Text('Create a family'),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => context.push('/join-family'),
              child: const Text('Join a family'),
            ),
          ],
        ),
      ),
    );
  }
}

// This used to sign out the instant you tapped the icon — no confirmation,
// no way to back out of a misclick. Now it's a deliberate two-step action,
// same pattern as the Pulse screen's sign-out.
Future<bool> _confirmSignOut(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Sign out?'),
      content: const Text(
        "You'll need to log back in to see your family's calendar.",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Sign out'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
