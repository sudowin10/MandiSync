class UserModel {
  final int? id;
  final String username;
  final String? email;
  final String fullName;
  final String role;
  final String? phone;
  final String? state;
  final String? district;
  final String? createdAt;

  UserModel({
    this.id,
    required this.username,
    this.email,
    required this.fullName,
    this.role = 'Farmer',
    this.phone,
    this.state,
    this.district,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : null,
      username: json['username'] ?? '',
      email: json['email'],
      fullName: json['full_name'] ?? json['name'] ?? json['username'] ?? 'Farmer User',
      role: json['role'] ?? 'Farmer',
      phone: json['phone'],
      state: json['state'],
      district: json['district'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'username': username,
      if (email != null) 'email': email,
      'full_name': fullName,
      'role': role,
      if (phone != null) 'phone': phone,
      if (state != null) 'state': state,
      if (district != null) 'district': district,
    };
  }

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}

class AuthResponse {
  final String accessToken;
  final String tokenType;
  final UserModel? user;

  AuthResponse({
    required this.accessToken,
    this.tokenType = 'bearer',
    this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'] ?? json['token'] ?? '',
      tokenType: json['token_type'] ?? 'bearer',
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    );
  }
}
