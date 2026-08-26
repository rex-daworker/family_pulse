import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/error_messages.dart';
import '../../core/family_roles.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/auth_provider.dart';

class JoinFamilyScreen extends ConsumerStatefulWidget {
  const JoinFamilyScreen({super.key});

  @override
  ConsumerState<JoinFamilyScreen> createState() => _JoinFamilyScreenState();
}

class _JoinFamilyScreenState extends ConsumerState<JoinFamilyScreen> {
  final _familyIdController = TextEditingController();
  final _yourNameController = TextEditingController();
  final _labelController = TextEditingController();
  String _selectedRole = 'parent';
  bool _isLoading = false;

  @override
  void dispose() {
    _familyIdController.dispose();
    _yourNameController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _joinFamily() async {
    final l10n = AppLocalizations.of(context);
    final familyId = _familyIdController.text.trim();
    final yourName = _yourNameController.text.trim();
    if (familyId.isEmpty || yourName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.fillBothFieldsError)));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = ref.read(authServiceProvider).currentUser!;
      await ref
          .read(familyServiceProvider)
          .joinFamily(
            familyId: familyId,
            userId: user.uid,
            userName: yourName,
            userEmail: user.email ?? '',
            role: _selectedRole,
            label: _labelController.text.trim(),
          );
      ref.invalidate(currentFamilyIdProvider);
      await ref.read(currentFamilyIdProvider.future);
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
      appBar: AppBar(title: Text(l10n.joinFamilyTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _familyIdController,
              decoration: InputDecoration(
                labelText: l10n.familyCodeLabel,
                helperText: l10n.familyCodeHelper,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _yourNameController,
              decoration: InputDecoration(labelText: l10n.yourNameLabel),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedRole,
              decoration: InputDecoration(labelText: l10n.roleLabel),
              items: kFamilyRoles
                  .map(
                    (role) => DropdownMenuItem(
                      value: role,
                      child: Text(roleDisplayName(context, role)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedRole = value);
              },
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
                    onPressed: _joinFamily,
                    child: Text(l10n.joinFamilyAction),
                  ),
          ],
        ),
      ),
    );
  }
}
