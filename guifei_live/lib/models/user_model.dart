class UserModel {
  final String id;
  final String username;
  final String phone;
  final String? avatar;
  final String nickname;
  final int gender;
  final DateTime birthday;
  final int status;
  final DateTime registerTime;
  final int userType;

  const UserModel({
    required this.id,
    required this.username,
    required this.phone,
    this.avatar,
    required this.nickname,
    required this.gender,
    required this.birthday,
    required this.status,
    required this.registerTime,
    required this.userType,
  });

  UserModel copyWith({
    String? id,
    String? username,
    String? phone,
    String? avatar,
    String? nickname,
    int? gender,
    DateTime? birthday,
    int? status,
    DateTime? registerTime,
    int? userType,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      nickname: nickname ?? this.nickname,
      gender: gender ?? this.gender,
      birthday: birthday ?? this.birthday,
      status: status ?? this.status,
      registerTime: registerTime ?? this.registerTime,
      userType: userType ?? this.userType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'phone': phone,
      'avatar': avatar,
      'nickname': nickname,
      'gender': gender,
      'birthday': birthday.toIso8601String().split('T')[0],
      'status': status,
      'register_time': registerTime.toIso8601String().split('T')[0],
      'user_type': userType,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      phone: json['phone'] ?? '',
      avatar: json['avatar'],
      nickname: json['nickname'] ?? '',
      gender: json['gender'] ?? 1,
      birthday: DateTime.parse(json['birthday'] ?? '2000-01-01'),
      status: json['status'] ?? 0,
      registerTime: DateTime.parse(json['register_time'] ?? json['created_at'] ?? DateTime.now().toIso8601String()),
      userType: json['user_type'] ?? 1,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, username: $username, nickname: $nickname, userType: $userType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}