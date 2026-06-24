class User {
  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.partnerName,
    this.region,
  });

  final int id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? partnerName;
  final String? region;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      phone: json['phone'] as String?,
      partnerName: json['partner_name'] as String?,
      region: json['region'] as String?,
    );
  }
}
