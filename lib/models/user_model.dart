class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // 'parent' or 'child'

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  /// Builds a UserModel from a Firestore document snapshot's data map.
  /// `id` is passed separately since it comes from the document ID,
  /// not a field inside the document.
  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    return UserModel(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'child',
    );
  }

  /// Converts this object back into a map, ready to write to Firestore.
  Map<String, dynamic> toMap() {
    return {'name': name, 'email': email, 'role': role};
  }
}
