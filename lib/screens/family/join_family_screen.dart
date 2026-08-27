import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';

class JoinFamilyScreen extends ConsumerStatefulWidget {
  const JoinFamilyScreen({super.key});

  @override
  ConsumerState<JoinFamilyScreen> createState() => _JoinFamilyScreenState();
}

class _JoinFamilyScreenState extends ConsumerState<JoinFamilyScreen> {
  final TextEditingController _familyIdController = TextEditingController();

  final TextEditingController _yourNameController = TextEditingController();

  String _selectedRole = 'parent';
  bool _isLoading = false;

  @override
  void dispose() {
    _familyIdController.dispose();
    _yourNameController.dispose();
    super.dispose();
  }

  Future<void> _joinFamily() async {
    final String familyId = _familyIdController.text.trim();

    final String yourName = _yourNameController.text.trim();

    // ----------------------------------------------------------
    // VALIDATION
    // ----------------------------------------------------------

    if (familyId.isEmpty || yourName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in both fields.')),
      );
      return;
    }

    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // --------------------------------------------------------
      // GET CURRENT USER
      // --------------------------------------------------------

      final user = ref.read(authServiceProvider).currentUser;

      if (user == null) {
        throw Exception('You must be signed in to join a family.');
      }

      // --------------------------------------------------------
      // JOIN FAMILY
      // --------------------------------------------------------

      await ref
          .read(familyServiceProvider)
          .joinFamily(
            familyId: familyId,
            userId: user.uid,
            userName: yourName,
            userEmail: user.email ?? '',
            role: _selectedRole,
          );

      // --------------------------------------------------------
      // REFRESH FAMILY ID
      // --------------------------------------------------------

      ref.invalidate(currentFamilyIdProvider);

      await ref.read(currentFamilyIdProvider.future);

      // --------------------------------------------------------
      // GO TO FAMILY SCREEN
      // --------------------------------------------------------

      if (!mounted) {
        return;
      }

      context.go('/family');
    } catch (e) {
      // --------------------------------------------------------
      // ERROR
      // --------------------------------------------------------

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      // --------------------------------------------------------
      // STOP LOADING
      //
      // IMPORTANT:
      // Do not use "return" inside finally.
      // --------------------------------------------------------

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join a family')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ------------------------------------------------
              // FAMILY CODE
              // ------------------------------------------------
              TextField(
                controller: _familyIdController,
                enabled: !_isLoading,
                decoration: const InputDecoration(
                  labelText: 'Family code',
                  helperText: 'Ask a family member for their family code.',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                autocorrect: false,
              ),

              const SizedBox(height: 16),

              // ------------------------------------------------
              // YOUR NAME
              // ------------------------------------------------
              TextField(
                controller: _yourNameController,
                enabled: !_isLoading,
                decoration: const InputDecoration(
                  labelText: 'Your name',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  if (!_isLoading) {
                    _joinFamily();
                  }
                },
              ),

              const SizedBox(height: 16),

              // ------------------------------------------------
              // ROLE
              // ------------------------------------------------
              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem<String>(
                    value: 'parent',
                    child: Text('Parent'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'child',
                    child: Text('Child'),
                  ),
                ],
                onChanged: _isLoading
                    ? null
                    : (String? value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          _selectedRole = value;
                        });
                      },
              ),

              const SizedBox(height: 24),

              // ------------------------------------------------
              // JOIN BUTTON
              // ------------------------------------------------
              SizedBox(
                width: double.infinity,
                height: 50,
                child: _isLoading
                    ? const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: _joinFamily,
                        child: const Text('Join family'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
