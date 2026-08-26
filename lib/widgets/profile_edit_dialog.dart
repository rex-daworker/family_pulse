import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/gender_options.dart';
import '../l10n/generated/app_localizations.dart';

/// The full "Edit profile" dialog — name, label, an optional avatar photo,
/// age, and gender. Kept separate from NameLabelDialog (which Settings'
/// plain name edit and the Family roster's parent-rename action still use)
/// because those two only ever touch name/label; this one owns the rest of
/// the profile fields that only make sense in the "this is you" context of
/// the Profile tab.
///
/// Returns null on cancel. On save, returns the edited name/label/age/gender
/// plus either a newly-picked photo file to upload, or a flag saying the
/// existing photo should be cleared — the caller (ProfileScreen) does the
/// actual Storage upload and Firestore write, the same way every other
/// dialog in this app hands back plain data rather than reaching into
/// services itself.
class ProfileEditDialog extends StatefulWidget {
  const ProfileEditDialog({
    super.key,
    required this.title,
    required this.initialName,
    this.initialLabel = '',
    this.initialPhotoUrl,
    this.initialAge,
    this.initialGender,
  });

  final String title;
  final String initialName;
  final String initialLabel;
  final String? initialPhotoUrl;
  final int? initialAge;
  final String? initialGender;

  @override
  State<ProfileEditDialog> createState() => _ProfileEditDialogState();
}

typedef ProfileEditResult = ({
  String name,
  String label,
  int? age,
  String? gender,
  File? newPhotoFile,
  bool removePhoto,
});

class _ProfileEditDialogState extends State<ProfileEditDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _labelController;
  late final TextEditingController _ageController;
  String? _nameError;
  String? _ageError;
  String? _gender;

  File? _newPhotoFile;
  bool _removePhoto = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _labelController = TextEditingController(text: widget.initialLabel);
    _ageController = TextEditingController(
      text: widget.initialAge?.toString() ?? '',
    );
    _gender = widget.initialGender;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _labelController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  bool get _hasExistingPhoto =>
      widget.initialPhotoUrl != null && widget.initialPhotoUrl!.isNotEmpty;

  Future<void> _pickPhoto(ImageSource source) async {
    final l10n = AppLocalizations.of(context);
    final picker = ImagePicker();
    try {
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;
      setState(() {
        _newPhotoFile = File(picked.path);
        _removePhoto = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.couldNotPickPhotoError(e.toString()))),
      );
    }
  }

  void _showPhotoSourceSheet() {
    final l10n = AppLocalizations.of(context);
    final canRemove =
        _newPhotoFile != null || (_hasExistingPhoto && !_removePhoto);
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.takePhotoOption),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.chooseFromGalleryOption),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _pickPhoto(ImageSource.gallery);
              },
            ),
            if (canRemove)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text(l10n.removePhotoOption),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  setState(() {
                    _newPhotoFile = null;
                    _removePhoto = true;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final l10n = AppLocalizations.of(context);
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = l10n.nameRequiredError);
      return;
    }

    final ageText = _ageController.text.trim();
    int? age;
    if (ageText.isNotEmpty) {
      age = int.tryParse(ageText);
      if (age == null || age < 0 || age > 120) {
        setState(() => _ageError = l10n.ageInvalidError);
        return;
      }
    }

    Navigator.of(context).pop<ProfileEditResult>((
      name: name,
      label: _labelController.text.trim(),
      age: age,
      gender: _gender,
      newPhotoFile: _newPhotoFile,
      removePhoto: _removePhoto,
    ));
  }

  ImageProvider? _previewImage() {
    if (_newPhotoFile != null) return FileImage(_newPhotoFile!);
    if (!_removePhoto && _hasExistingPhoto) {
      return NetworkImage(widget.initialPhotoUrl!);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final trimmedName = _nameController.text.trim();
    final initial = trimmedName.isNotEmpty ? trimmedName[0].toUpperCase() : '?';
    final preview = _previewImage();

    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: GestureDetector(
                onTap: _showPhotoSourceSheet,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      backgroundImage: preview,
                      child: preview == null
                          ? Text(
                              initial,
                              style: const TextStyle(
                                fontSize: 28,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.secondary,
                        child: const Icon(
                          Icons.camera_alt,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: _showPhotoSourceSheet,
              child: Text(l10n.changePhotoLabel),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.nameFieldLabel,
                errorText: _nameError,
              ),
              onChanged: (_) {
                setState(() {
                  if (_nameError != null) _nameError = null;
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _labelController,
              decoration: InputDecoration(
                labelText: l10n.labelOptional,
                hintText: l10n.labelHintGeneric,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.ageFieldLabel,
                errorText: _ageError,
              ),
              onChanged: (_) {
                if (_ageError != null) setState(() => _ageError = null);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _gender,
              decoration: InputDecoration(labelText: l10n.genderFieldLabel),
              items: [
                DropdownMenuItem(value: null, child: Text(l10n.genderNotSet)),
                for (final option in kGenderOptions)
                  DropdownMenuItem(
                    value: option,
                    child: Text(genderDisplayName(context, option)),
                  ),
              ],
              onChanged: (value) => setState(() => _gender = value),
            ),
          ],
        ),
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
