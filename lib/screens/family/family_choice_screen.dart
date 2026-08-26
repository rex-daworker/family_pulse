import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/sign_out.dart';
import '../../l10n/generated/app_localizations.dart';

class FamilyChoiceScreen extends ConsumerWidget {
  const FamilyChoiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.familyChoiceTitle),
        actions: [
          IconButton(
            onPressed: () => confirmAndSignOut(context, ref),
            icon: const Icon(Icons.logout),
            tooltip: l10n.signOut,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.notInFamilyYet,
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.push('/create-family'),
              child: Text(l10n.createFamilyButton),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => context.push('/join-family'),
              child: Text(l10n.joinFamilyButton),
            ),
          ],
        ),
      ),
    );
  }
}
