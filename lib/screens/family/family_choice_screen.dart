import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/sign_out.dart';

class FamilyChoiceScreen extends ConsumerWidget {
  const FamilyChoiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome'),
        actions: [
          IconButton(
            onPressed: () => confirmAndSignOut(context, ref),
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
