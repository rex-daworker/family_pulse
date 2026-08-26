import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
    final familyName = _familyNameController.text.trim();
    final yourName = _yourNameController.text.trim();
    if (familyName.isEmpty || yourName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in both fields.')),
      );
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
            title: const Text('Family created'),
            content: SelectableText(
              'Share this code so others can join:\n\n$familyId',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: familyId));
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Code copied')));
                },
                child: const Text('Copy code'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Continue'),
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
      appBar: AppBar(title: const Text('Create a family')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _familyNameController,
              decoration: const InputDecoration(labelText: 'Family name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _yourNameController,
              decoration: const InputDecoration(labelText: 'Your name'),
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
                    onPressed: _createFamily,
                    child: const Text('Create family'),
                  ),
          ],
        ),
      ),
    );
  }
}
