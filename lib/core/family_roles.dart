import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';

/// Central place for the family-role vocabulary. Only 'parent' unlocks
/// parent-only actions (renaming other members, managing groups later),
/// so adding a role here does NOT by itself grant those permissions —
/// see firestore.rules and FamilyScreen's `isParentRole` checks.
///
/// These are the language-neutral keys stored in Firestore — never
/// translate the keys themselves, only what roleDisplayName() shows for
/// them.
const List<String> kFamilyRoles = ['parent', 'child', 'guardian', 'other'];

bool isParentRole(String role) => role.toLowerCase() == 'parent';

/// Needs a BuildContext (rather than being a pure lookup) so the label
/// comes back in whatever language the user has picked in Settings.
String roleDisplayName(BuildContext context, String role) {
  final l10n = AppLocalizations.of(context);
  switch (role.toLowerCase()) {
    case 'parent':
      return l10n.roleParent;
    case 'child':
      return l10n.roleChild;
    case 'guardian':
      return l10n.roleGuardian;
    default:
      return l10n.roleOther;
  }
}

IconData roleIcon(String role) {
  switch (role.toLowerCase()) {
    case 'parent':
      return Icons.escalator_warning;
    case 'child':
      return Icons.child_care;
    case 'guardian':
      return Icons.shield_outlined;
    default:
      return Icons.person_outline;
  }
}

/// A member's display label — their custom label ("Mom", "Dad", "Grandma")
/// when they've set one, falling back to their role. This is what makes two
/// parents on the same family distinguishable instead of both just reading
/// "Parent".
String memberSubtitle(BuildContext context, String role, String label) {
  final trimmed = label.trim();
  return trimmed.isNotEmpty ? trimmed : roleDisplayName(context, role);
}
