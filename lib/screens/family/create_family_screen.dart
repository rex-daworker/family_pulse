import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/error_messages.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/auth_provider.dart';

class CreateFamilyScreen extends ConsumerStatefulWidget {
  const CreateFamilyScreen({super.key});

  @override
  ConsumerState<CreateFamilyScreen> createState() => _CreateFamilyScreenState();
}

class _CreateFamilyScreenState extends ConsumerState<CreateFamilyScreen> {
  final _familyNameController = TextEditingController();
  final _yourNameController = TextEditingController();
  final _labelController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _familyNameController.dispose();
    _yourNameController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _createFamily() async {
    final l10n = AppLocalizations.of(context);
    final familyName = _familyNameController.text.trim();
    final yourName = _yourNameController.text.trim();
    if (familyName.isEmpty || yourName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.fillBothFieldsError)));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = ref.read(authServiceProvider).currentUser!;
      final familyId = await ref
          .read(familyServiceProvider)
          .createFamily(
            familyName: familyName,
            userId: user.uid,
            userName: yourName,
            userEmail: user.email ?? '',
            label: _labelController.text.trim(),
          );

      // Show the code BEFORE touching currentFamilyIdProvider. The router
      // listens for that provider to resolve and auto-redirects away from
      // this screen the instant it does — invalidating it first meant the
      // redirect could fire (and tear down this screen) before the dialog
      // ever had a chance to appear, so the user got bounced straight to
      // the Pulse page with no code shown.
      if (mounted) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text(l10n.familyCreatedTitle),
            content: SelectableText(l10n.shareCodeMessage(familyId)),
            actions: [
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: familyId));
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(l10n.codeCopied)));
                },
                child: Text(l10n.copyCodeTooltip),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.continueButton),
              ),
            ],
          ),
        );
      }

      // Now that the user has seen the code, let the router know the
      // family exists — this is what triggers the redirect to '/'.
      ref.invalidate(currentFamilyIdProvider);
      if (mounted) await ref.read(currentFamilyIdProvider.future);

      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizedErrorMessage(context, e))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.createFamilyTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _familyNameController,
              decoration: InputDecoration(labelText: l10n.familyNameLabel),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _yourNameController,
              decoration: InputDecoration(labelText: l10n.yourNameLabel),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _labelController,
              decoration: InputDecoration(
                labelText: l10n.labelOptional,
                hintText: l10n.labelHint,
              ),
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _createFamily,
                    child: Text(l10n.createFamilyAction),
                  ),
          ],
        ),
      ),
    );
  }
}
