class UserModel {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? avatarUrl;
  final Map<String, dynamic>? serviceProfile;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.avatarUrl,
    this.serviceProfile,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as int,
        name: json['name'] as String,
        email: json['email'] as String,
        role: json['role'] as String,
        phone: json['phone'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
        serviceProfile: json['serviceProfile'] as Map<String, dynamic>?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'phone': phone,
        'avatarUrl': avatarUrl,
        'serviceProfile': serviceProfile,
      };

  String get firstName => name.split(' ').first;

  String get redirectPath => switch (role) {
        'provider' => '/provider',
        'admin' => '/admin',
        _ => '/dashboard',
      };
}
