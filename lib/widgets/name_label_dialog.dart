import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';

/// Shared "edit a name + optional label" dialog — used for editing your own
/// profile, editing another member's info (parents only), and used to be
/// three near-identical copies of this same form. Owns its own controllers
/// via initState/dispose, the same lifecycle pattern every dialog in this
/// app uses to avoid disposing mid exit-animation.
///
/// Returns `null` on cancel, otherwise the entered (name, label).
class NameLabelDialog extends StatefulWidget {
  const NameLabelDialog({
    super.key,
    required this.title,
    required this.initialName,
    this.initialLabel = '',
    this.showLabelField = true,
  });

  final String title;
  final String initialName;
  final String initialLabel;

  // Settings' plain "your name" edit doesn't need the label field — only
  // the family-facing screens (Profile, Family roster) do.
  final bool showLabelField;

  @override
  State<NameLabelDialog> createState() => _NameLabelDialogState();
}

class _NameLabelDialogState extends State<NameLabelDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _labelController;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _labelController = TextEditingController(text: widget.initialLabel);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  void _save() {
    final l10n = AppLocalizations.of(context);
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = l10n.nameRequiredError);
      return;
    }
    Navigator.of(
      context,
    ).pop((name: name, label: _labelController.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.nameFieldLabel,
              errorText: _nameError,
            ),
            onChanged: (_) {
              if (_nameError != null) setState(() => _nameError = null);
            },
            onSubmitted: widget.showLabelField ? null : (_) => _save(),
          ),
          if (widget.showLabelField) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _labelController,
              decoration: InputDecoration(
                labelText: l10n.labelOptional,
                hintText: l10n.labelHintGeneric,
              ),
              onSubmitted: (_) => _save(),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _save, child: Text(l10n.save)),
      ],
    );
  }
}
