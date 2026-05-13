class UserModel {
  final String id;
  final String fullName;
  final String? phone;
  final String? email;
  final String role;
  final String? avatarUrl;
  final bool isVerified;
  final DateTime? bannedAt;
  final String? banReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.fullName,
    this.phone,
    this.email,
    required this.role,
    this.avatarUrl,
    this.isVerified = false,
    this.bannedAt,
    this.banReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        id: map['id'] as String,
        fullName: map['full_name'] as String? ?? '',
        phone: map['phone_number'] as String?,
        email: map['email'] as String?,
        role: map['role'] as String? ?? 'customer',
        avatarUrl: map['avatar_url'] as String?,
        isVerified: map['is_verified'] as bool? ?? false,
        bannedAt: map['banned_at'] != null ? DateTime.parse(map['banned_at'] as String) : null,
        banReason: map['ban_reason'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'full_name': fullName,
        'phone_number': phone,
        'email': email,
        'role': role,
        'avatar_url': avatarUrl,
        'is_verified': isVerified,
        'banned_at': bannedAt?.toIso8601String(),
        'ban_reason': banReason,
      };

  String get roleLabel {
    switch (role) {
      case 'customer': return 'عميل';
      case 'restaurant': return 'مطعم';
      case 'rider': return 'Rider';
      case 'admin': return 'مشرف';
      default: return role;
    }
  }
}
