class UserModel {
  final String id;
  final String? email;
  final String? name;
  final String? profileImage;
  final String? loginProvider;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  UserModel({
    required this.id,
    this.email,
    this.name,
    this.profileImage,
    this.loginProvider,
    this.createdAt,
    this.lastLoginAt,
  });

  // Supabase에서 데이터 가져올 때 사용
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String?,
      name: json['name'] as String?,
      profileImage: json['profile_image'] as String?,
      loginProvider: json['login_provider'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'] as String)
          : null,
    );
  }

  // Supabase에 저장할 때 사용
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'profile_image': profileImage,
      'login_provider': loginProvider,
      'created_at': createdAt?.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, name: $name)';
  }
}