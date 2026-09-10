class UserRegisterRequest {
  final String username;
  final String password;
  final String? fullName;
  final String? email;
  final String role; // 'farmer', 'buyer', 'trader', 'transporter'

  const UserRegisterRequest({
    required this.username,
    required this.password,
    this.fullName,
    this.email,
    this.role = 'farmer',
  });

  Map<String, dynamic> toJson() => {
    'username': username,
    'password': password,
    if (fullName != null) 'full_name': fullName,
    if (email != null) 'email': email,
    'role': role,
  };
}

class UserLoginRequest {
  final String username;
  final String password;

  const UserLoginRequest({
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
    'username': username,
    'password': password,
  };
}

class AuthTokenResponse {
  final String accessToken;
  final String tokenType;

  const AuthTokenResponse({
    required this.accessToken,
    this.tokenType = 'bearer',
  });

  factory AuthTokenResponse.fromJson(Map<String, dynamic> json) {
    return AuthTokenResponse(
      accessToken: json['access_token'] as String? ?? '',
      tokenType: json['token_type'] as String? ?? 'bearer',
    );
  }
}

class UserProfile {
  final String username;
  final String? fullName;
  final String? email;
  final String role;
  final bool disabled;

  const UserProfile({
    required this.username,
    this.fullName,
    this.email,
    required this.role,
    this.disabled = false,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      username: json['username'] as String? ?? '',
      fullName: json['full_name'] as String?,
      email: json['email'] as String?,
      role: json['role'] as String? ?? 'farmer',
      disabled: json['disabled'] as bool? ?? false,
    );
  }
}
