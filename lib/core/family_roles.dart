import 'package:flutter/material.dart';

/// Central place for the family-role vocabulary. Only 'parent' unlocks
/// parent-only actions (renaming other members, managing groups later),
/// so adding a role here does NOT by itself grant those permissions —
/// see firestore.rules and FamilyScreen's `isParentRole` checks.
const List<String> kFamilyRoles = ['parent', 'child', 'guardian', 'other'];

bool isParentRole(String role) => role.toLowerCase() == 'parent';

String roleDisplayName(String role) {
  switch (role.toLowerCase()) {
    case 'parent':
      return 'Parent';
    case 'child':
      return 'Child';
    case 'guardian':
      return 'Guardian';
    default:
      return 'Other';
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
String memberSubtitle(String role, String label) {
  final trimmed = label.trim();
  return trimmed.isNotEmpty ? trimmed : roleDisplayName(role);
}
