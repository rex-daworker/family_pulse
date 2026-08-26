import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/family_service.dart';
import '../services/storage_service.dart';

/// Turns a caught error into text that's safe (and correctly localized) to
/// show the user. `AuthService`/`FamilyService` throw `AuthError`/
/// `FamilyError` — small language-neutral `code` carriers, since the
/// service layer has no BuildContext/locale of its own to translate with.
/// This is where that code finally gets turned into the active language.
///
/// Anything else (an error type this app didn't throw on purpose) falls
/// back to the error's own `toString()` — better an occasional untranslated
/// message than silently swallowing a real failure.
String localizedErrorMessage(BuildContext context, Object error) {
  final l10n = AppLocalizations.of(context);

  if (error is AuthError) {
    switch (error.code) {
      case 'weak-password':
        return l10n.authErrorWeakPassword;
      case 'email-already-in-use':
        return l10n.authErrorEmailInUse;
      case 'user-not-found':
        return l10n.authErrorUserNotFound;
      case 'wrong-password':
        return l10n.authErrorWrongPassword;
      case 'invalid-email':
        return l10n.authErrorInvalidEmail;
      case 'not-signed-in':
        return l10n.authErrorNotSignedIn;
      default:
        return l10n.authErrorUnknown;
    }
  }

  if (error is FamilyError) {
    switch (error.code) {
      case 'not-found':
        return l10n.familyErrorNotFound;
      default:
        return l10n.authErrorUnknown;
    }
  }

  if (error is StorageError) {
    switch (error.code) {
      case 'unauthorized':
      case 'unauthenticated':
        return l10n.authErrorNotSignedIn;
      case 'canceled':
        return l10n.storageErrorCanceled;
      default:
        return l10n.storageErrorUnknown;
    }
  }

  return error.toString();
}
