// A single row from a family's `users` subcollection — one per person who
// has joined that family (via create or the referral-code join flow).
class FamilyMember {
  FamilyMember({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    this.label = '',
  });

  final String userId;
  final String name;
  final String email;
  final String role;

  // Optional free-text label ("Mom", "Dad", "Grandma") — mainly for
  // telling two same-role members (e.g. both parents) apart at a glance,
  // since the role alone reads as identical for both of them.
  final String label;

  factory FamilyMember.fromMap(Map<String, dynamic> data) {
    return FamilyMember(
      userId: data['user_id'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? '',
      label: data['label'] ?? '',
    );
  }
}

/// Small shared lookup — used anywhere a screen has the full member list
/// (from familyMembersProvider) and needs just the current user's own row,
/// e.g. to read their role or label. Returns null while members haven't
/// loaded yet or the user isn't found in the list.
FamilyMember? findMemberById(List<FamilyMember> members, String? userId) {
  if (userId == null) return null;
  for (final member in members) {
    if (member.userId == userId) return member;
  }
  return null;
}
