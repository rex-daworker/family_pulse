import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/family_group_model.dart';
import 'auth_provider.dart';

/// Live list of the current user's family's sub-groups — mirrors the
/// familyMembersProvider pattern: resolve the family ID first, then stream,
/// empty list (not an error) while there's no family yet.
final familyGroupsProvider = StreamProvider<List<FamilyGroupModel>>((
  ref,
) async* {
  final familyId = await ref.watch(currentFamilyIdProvider.future);
  if (familyId == null) {
    yield <FamilyGroupModel>[];
    return;
  }

  final familyService = ref.watch(familyServiceProvider);
  yield* familyService.getGroups(familyId);
});
