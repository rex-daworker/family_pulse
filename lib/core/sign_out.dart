import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';

/// Shared "are you sure?" sign-out flow. Originally copy-pasted across
/// Pulse, Family Choice, and Settings — centralized here once the nav
/// drawer became a fourth call site, since four copies of the same dialog
/// is the point where keeping them in sync by hand stops being reasonable.
Future<void> confirmAndSignOut(BuildContext context, WidgetRef ref) async {
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
  if (confirmed != true || !context.mounted) return;

  try {
    await ref.read(authServiceProvider).signOut();
    // Firebase auth state changes also make GoRouter redirect on its own;
    // this is a belt-and-suspenders nudge in case that hasn't fired yet.
    if (context.mounted) context.go('/welcome');
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
}
