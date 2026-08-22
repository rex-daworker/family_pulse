import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/family_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';

class FamilyScreen extends ConsumerWidget {
  const FamilyScreen({super.key});

  // ---------------------------------------------------------------------------
  // COPY FAMILY CODE
  // ---------------------------------------------------------------------------

  Future<void> _copyFamilyCode(BuildContext context, String familyId) async {
    await Clipboard.setData(ClipboardData(text: familyId));

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Family code copied!')));
    }
  }

  // ---------------------------------------------------------------------------
  // SIGN OUT
  // ---------------------------------------------------------------------------

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authServiceProvider).signOut();

      if (context.mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not sign out: $e')));
      }
    }
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyIdAsync = ref.watch(currentFamilyIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Family'),

        actions: [
          IconButton(
            onPressed: () => _signOut(context, ref),
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
          ),
        ],
      ),

      body: familyIdAsync.when(
        // ---------------------------------------------------------------
        // LOADING
        // ---------------------------------------------------------------
        loading: () {
          return const Center(child: CircularProgressIndicator());
        },

        // ---------------------------------------------------------------
        // ERROR
        // ---------------------------------------------------------------
        error: (error, stack) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Could not load your family.\n\n$error',
                textAlign: TextAlign.center,
              ),
            ),
          );
        },

        // ---------------------------------------------------------------
        // DATA
        // ---------------------------------------------------------------
        data: (familyId) {
          if (familyId == null) {
            return const Center(
              child: Text('You are not part of a family yet.'),
            );
          }

          return _FamilyContent(
            familyId: familyId,
            copyFamilyCode: _copyFamilyCode,
          );
        },
      ),
    );
  }
}

// =============================================================================
// FAMILY CONTENT
// =============================================================================

class _FamilyContent extends ConsumerWidget {
  const _FamilyContent({required this.familyId, required this.copyFamilyCode});

  final String familyId;

  final Future<void> Function(BuildContext context, String familyId)
  copyFamilyCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyService = ref.watch(familyServiceProvider);

    return FutureBuilder<FamilyModel?>(
      future: familyService.getFamily(familyId),

      builder: (context, familySnapshot) {
        // -------------------------------------------------------------
        // LOADING FAMILY
        // -------------------------------------------------------------

        if (familySnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // -------------------------------------------------------------
        // FAMILY ERROR
        // -------------------------------------------------------------

        if (familySnapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Could not load family information.\n\n'
                '${familySnapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        // -------------------------------------------------------------
        // FAMILY NOT FOUND
        // -------------------------------------------------------------

        final family = familySnapshot.data;

        if (family == null) {
          return const Center(child: Text('Family could not be found.'));
        }

        // -------------------------------------------------------------
        // FAMILY PAGE
        // -------------------------------------------------------------

        return ListView(
          padding: const EdgeInsets.all(16),

          children: [
            // =========================================================
            // FAMILY INFORMATION
            // =========================================================
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      family.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Share this code with someone you want '
                      'to add to your family.',
                    ),

                    const SizedBox(height: 20),

                    Text(
                      'Family code',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),

                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),

                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,

                        borderRadius: BorderRadius.circular(12),
                      ),

                      child: Row(
                        children: [
                          Expanded(
                            child: SelectableText(
                              familyId,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),

                          IconButton(
                            onPressed: () {
                              copyFamilyCode(context, familyId);
                            },
                            icon: const Icon(Icons.copy),
                            tooltip: 'Copy family code',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // =========================================================
            // MEMBERS
            // =========================================================
            Text('Members', style: Theme.of(context).textTheme.headlineSmall),

            const SizedBox(height: 8),

            StreamBuilder<List<UserModel>>(
              stream: familyService.watchFamilyMembers(familyId),

              builder: (context, snapshot) {
                // -----------------------------------------------------
                // LOADING MEMBERS
                // -----------------------------------------------------

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }

                // -----------------------------------------------------
                // MEMBER ERROR
                // -----------------------------------------------------

                if (snapshot.hasError) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Could not load members.\n\n'
                        '${snapshot.error}',
                      ),
                    ),
                  );
                }

                final members = snapshot.data ?? [];

                // -----------------------------------------------------
                // NO MEMBERS
                // -----------------------------------------------------

                if (members.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No family members yet.'),
                    ),
                  );
                }

                // -----------------------------------------------------
                // MEMBER LIST
                // -----------------------------------------------------

                return Card(
                  child: Column(
                    children: members.map((member) {
                      final role = member.role.isEmpty
                          ? 'Member'
                          : '${member.role[0].toUpperCase()}'
                                '${member.role.substring(1)}';

                      final subtitle = member.email.isEmpty
                          ? role
                          : '$role • ${member.email}';

                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            member.name.isNotEmpty
                                ? member.name[0].toUpperCase()
                                : '?',
                          ),
                        ),

                        title: Text(
                          member.name.isEmpty ? 'Unnamed member' : member.name,
                        ),

                        subtitle: Text(subtitle),
                      );
                    }).toList(),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // =========================================================
            // SIGN OUT BUTTON
            // =========================================================
            SizedBox(
              width: double.infinity,

              child: OutlinedButton.icon(
                onPressed: () async {
                  try {
                    await ref.read(authServiceProvider).signOut();

                    if (context.mounted) {
                      context.go('/login');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Could not sign out: $e')),
                      );
                    }
                  }
                },

                icon: const Icon(Icons.logout),

                label: const Text('Sign out'),
              ),
            ),

            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}
