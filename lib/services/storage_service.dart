import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

/// Thrown for photo-upload failures the UI should show a message for. Same
/// shape as AuthError/FamilyError — a stable, language-neutral `code`,
/// translated by localizedErrorMessage() rather than shown raw, since this
/// service layer has no BuildContext/locale of its own.
class StorageError implements Exception {
  const StorageError(this.code);
  final String code;

  @override
  String toString() => 'StorageError($code)';
}

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // One fixed path per member (families/{familyId}/profile_photos/{userId}.jpg)
  // rather than a fresh filename per upload — re-uploading a new photo just
  // overwrites the old file in place, so there's no cleanup step and no
  // orphaned images piling up in Storage every time someone changes their
  // picture.
  //
  // Takes bytes rather than a File on purpose. `putFile()` accepts a dart:io
  // File, which does not exist in a browser — firebase_storage's web
  // implementation throws `UnimplementedError: putFile() is not implemented`,
  // so profile photos were silently broken on web while working on Android.
  // `putData()` is implemented on every platform, so this is one code path
  // rather than a conditional import, and image_picker already hands back an
  // XFile whose bytes can be read anywhere.
  Future<String> uploadProfilePhoto({
    required String familyId,
    required String userId,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) async {
    try {
      final ref = _storage
          .ref()
          .child('families')
          .child(familyId)
          .child('profile_photos')
          .child('$userId.jpg');
      await ref.putData(bytes, SettableMetadata(contentType: contentType));
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw StorageError(e.code);
    }
  }
}
