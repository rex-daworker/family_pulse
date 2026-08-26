// A single row from a family's `users` subcollection — one per person who
// has joined that family (via create or the referral-code join flow).
class FamilyMember {
  FamilyMember({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
  });

  final String userId;
  final String name;
  final String email;
  final String role;

  factory FamilyMember.fromMap(Map<String, dynamic> data) {
    return FamilyMember(
      userId: data['user_id'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? '',
    );
  }
}
