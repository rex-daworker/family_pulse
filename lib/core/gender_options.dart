import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';

/// Central place for the gender vocabulary, mirroring how family_roles.dart
/// handles roles — a small, fixed set of language-neutral keys stored in
/// Firestore, never the keys themselves shown to the user.
///
/// `null` (no key at all) means "not answered" and is handled separately
/// wherever this is displayed — it's distinct from the explicit
/// 'prefer_not_to_say' choice, which means someone was asked and declined.
const List<String> kGenderOptions = [
  'female',
  'male',
  'other',
  'prefer_not_to_say',
];

/// Needs a BuildContext (rather than being a pure lookup) so the label
/// comes back in whatever language the user has picked in Settings.
String genderDisplayName(BuildContext context, String gender) {
  final l10n = AppLocalizations.of(context);
  switch (gender.toLowerCase()) {
    case 'female':
      return l10n.genderFemale;
    case 'male':
      return l10n.genderMale;
    case 'prefer_not_to_say':
      return l10n.genderPreferNotToSay;
    default:
      return l10n.genderOther;
  }
}
