import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/sign_out.dart';
import '../providers/auth_provider.dart';

/// The app's main navigation surface — a left-side drawer with a profile
/// header up top and every major screen one tap away underneath. Added so
/// "Family", "Free time", "Groups", and "Analytics" aren't only reachable
/// from Pulse's quick-nav row — Calendar, Settings, and anywhere else you
/// might land now all offer the same way back out to everything else.
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final familyAsync = ref.watch(currentFamilyProvider);

    final displayName = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : (user?.email ?? 'Family member');
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            InkWell(
              onTap: () {
                Navigator.of(context).pop();
                context.push('/profile');
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: Theme.of(context).textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (user?.email != null)
                            Text(
                              user!.email!,
                              style: Theme.of(context).textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          familyAsync.when(
                            data: (family) => family == null
                                ? const SizedBox.shrink()
                                : Text(
                                    family.name,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                            loading: () => const SizedBox.shrink(),
                            error: (error, stackTrace) =>
                                const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const _DrawerItem(
                    icon: Icons.home_outlined,
                    label: 'Home',
                    path: '/',
                  ),
                  const _DrawerItem(
                    icon: Icons.calendar_month,
                    label: 'Calendar',
                    path: '/calendar',
                  ),
                  const _DrawerItem(
                    icon: Icons.family_restroom,
                    label: 'Family',
                    path: '/family',
                  ),
                  const _DrawerItem(
                    icon: Icons.groups_outlined,
                    label: 'Groups',
                    path: '/groups',
                  ),
                  const _DrawerItem(
                    icon: Icons.free_breakfast,
                    label: 'Free time',
                    path: '/free-time',
                  ),
                  const _DrawerItem(
                    icon: Icons.bar_chart,
                    label: 'Analytics',
                    path: '/analytics',
                  ),
                  const Divider(),
                  const _DrawerItem(
                    icon: Icons.person_outline,
                    label: 'Profile',
                    path: '/profile',
                  ),
                  const _DrawerItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    path: '/settings',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign out'),
              onTap: () {
                Navigator.of(context).pop();
                confirmAndSignOut(context, ref);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.path,
  });

  final IconData icon;
  final String label;
  final String path;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () {
        Navigator.of(context).pop();
        // Home is already the router's base — go() there to avoid piling
        // up a redundant stack entry; every other destination still pushes,
        // matching how Pulse's own quick-nav buttons already navigate.
        if (path == '/') {
          context.go(path);
        } else {
          context.push(path);
        }
      },
    );
  }
}
