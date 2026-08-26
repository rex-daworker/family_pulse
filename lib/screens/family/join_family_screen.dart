import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/family_roles.dart';
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
    final familyId = _familyIdController.text.trim();
    final yourName = _yourNameController.text.trim();
    if (familyId.isEmpty || yourName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in both fields.')),
      );
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join a family')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _familyIdController,
              decoration: const InputDecoration(
                labelText: 'Family code',
                helperText: 'Ask a family member for their family code.',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _yourNameController,
              decoration: const InputDecoration(labelText: 'Your name'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedRole,
              decoration: const InputDecoration(labelText: 'Role'),
              items: kFamilyRoles
                  .map(
                    (role) => DropdownMenuItem(
                      value: role,
                      child: Text(roleDisplayName(role)),
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
              decoration: const InputDecoration(
                labelText: 'Label (optional)',
                hintText: 'e.g. Mom, Dad — helps tell parents apart',
              ),
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _joinFamily,
                    child: const Text('Join family'),
                  ),
          ],
        ),
      ),
    );
  }
}
