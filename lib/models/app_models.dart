// 贵妃直播应用数据模型
// 根据新数据库设计重新构建

import 'dart:convert';

/// 用户类型枚举
enum UserType {
  consumer(1, '普通用户'),
  anchor(2, '主播'),
  service(3, '客服'),
  admin(4, '管理员');

  const UserType(this.value, this.label);
  final int value;
  final String label;

  static UserType fromValue(int value) {
    return UserType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => UserType.consumer,
    );
  }
}

/// 用户状态枚举
enum UserStatus {
  normal(0, '正常'),
  disabled(1, '禁用'),
  frozen(2, '冻结');

  const UserStatus(this.value, this.label);
  final int value;
  final String label;

  static UserStatus fromValue(int value) {
    return UserStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => UserStatus.normal,
    );
  }
}

/// 核心用户模型
class User {
  final String id;
  final String username;
  final String phone;
  final String? avatar;
  final String nickname;
  final int gender; // 1男 2女
  final DateTime birthday;
  final UserStatus status;
  final DateTime registerTime;
  final UserType userType;

  User({
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

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      phone: json['phone'] ?? '',
      avatar: json['avatar'],
      nickname: json['nickname'] ?? '',
      gender: json['gender'] ?? 1,
      birthday: DateTime.parse(json['birthday'] ?? '2000-01-01'),
      status: UserStatus.fromValue(json['status'] ?? 0),
      registerTime: DateTime.parse(json['register_time'] ?? DateTime.now().toIso8601String()),
      userType: UserType.fromValue(json['user_type'] ?? 1),
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
      'status': status.value,
      'register_time': registerTime.toIso8601String().split('T')[0],
      'user_type': userType.value,
    };
  }

  User copyWith({
    String? id,
    String? username,
    String? phone,
    String? avatar,
    String? nickname,
    int? gender,
    DateTime? birthday,
    UserStatus? status,
    DateTime? registerTime,
    UserType? userType,
  }) {
    return User(
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
}

/// 消费者扩展信息
class ConsumerInfo {
  final String userId;
  final int vipLevel;
  final DateTime? vipExpire;
  final int consumptionLevel;
  final double balance;
  final double totalSpent;
  final List<String>? watchHistory;

  ConsumerInfo({
    required this.userId,
    required this.vipLevel,
    this.vipExpire,
    required this.consumptionLevel,
    required this.balance,
    required this.totalSpent,
    this.watchHistory,
  });

  factory ConsumerInfo.fromJson(Map<String, dynamic> json) {
    return ConsumerInfo(
      userId: json['user_id'] ?? '',
      vipLevel: json['vip_level'] ?? 0,
      vipExpire: json['vip_expire'] != null ? DateTime.parse(json['vip_expire']) : null,
      consumptionLevel: json['consumption_level'] ?? 1,
      balance: (json['balance'] ?? 0.0).toDouble(),
      totalSpent: (json['total_spent'] ?? 0.0).toDouble(),
      watchHistory: json['watch_history'] != null 
          ? List<String>.from(jsonDecode(json['watch_history']))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'vip_level': vipLevel,
      'vip_expire': vipExpire?.toIso8601String().split('T')[0],
      'consumption_level': consumptionLevel,
      'balance': balance,
      'total_spent': totalSpent,
      'watch_history': watchHistory != null ? jsonEncode(watchHistory) : null,
    };
  }

  /// 检查是否可以评论
  bool get canComment => consumptionLevel >= 2;

  /// 检查是否可以连麦
  bool get canConnectMic => consumptionLevel >= 20;
}

/// 主播扩展信息
class AnchorInfo {
  final String userId;
  final int liveLevel;
  final int fansCount;
  final double totalIncome;
  final double withdrawable;
  final double withdrawn;
  final List<String>? liveTags;
  final int verifyStatus;
  final String? liveNotice;

  AnchorInfo({
    required this.userId,
    required this.liveLevel,
    required this.fansCount,
    required this.totalIncome,
    required this.withdrawable,
    required this.withdrawn,
    this.liveTags,
    required this.verifyStatus,
    this.liveNotice,
  });

  factory AnchorInfo.fromJson(Map<String, dynamic> json) {
    return AnchorInfo(
      userId: json['user_id'] ?? '',
      liveLevel: json['live_level'] ?? 1,
      fansCount: json['fans_count'] ?? 0,
      totalIncome: (json['total_income'] ?? 0.0).toDouble(),
      withdrawable: (json['withdrawable'] ?? 0.0).toDouble(),
      withdrawn: (json['withdrawn'] ?? 0.0).toDouble(),
      liveTags: json['live_tags'] != null 
          ? List<String>.from(jsonDecode(json['live_tags']))
          : null,
      verifyStatus: json['verify_status'] ?? 0,
      liveNotice: json['live_notice'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'live_level': liveLevel,
      'fans_count': fansCount,
      'total_income': totalIncome,
      'withdrawable': withdrawable,
      'withdrawn': withdrawn,
      'live_tags': liveTags != null ? jsonEncode(liveTags) : null,
      'verify_status': verifyStatus,
      'live_notice': liveNotice,
    };
  }
}

/// 客服扩展信息
class ServiceInfo {
  final String userId;
  final List<String>? kefuTags;
  final String? kefuAvatar;
  final String? kefuNickname;
  final DateTime? kefuRegisterTime;

  ServiceInfo({
    required this.userId,
    this.kefuTags,
    this.kefuAvatar,
    this.kefuNickname,
    this.kefuRegisterTime,
  });

  factory ServiceInfo.fromJson(Map<String, dynamic> json) {
    return ServiceInfo(
      userId: json['user_id'] ?? '',
      kefuTags: json['kefu_tags'] != null 
          ? List<String>.from(jsonDecode(json['kefu_tags']))
          : null,
      kefuAvatar: json['kefu_avatar'],
      kefuNickname: json['kefu_nickname'],
      kefuRegisterTime: json['kefu_register_time'] != null 
          ? DateTime.parse(json['kefu_register_time'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'kefu_tags': kefuTags != null ? jsonEncode(kefuTags) : null,
      'kefu_avatar': kefuAvatar,
      'kefu_nickname': kefuNickname,
      'kefu_register_time': kefuRegisterTime?.toIso8601String().split('T')[0],
    };
  }
}

/// 管理员扩展信息
class AdminInfo {
  final String userId;
  final List<String>? adminTags;
  final String? adminAvatar;
  final String? adminNickname;
  final DateTime? adminRegisterTime;

  AdminInfo({
    required this.userId,
    this.adminTags,
    this.adminAvatar,
    this.adminNickname,
    this.adminRegisterTime,
  });

  factory AdminInfo.fromJson(Map<String, dynamic> json) {
    return AdminInfo(
      userId: json['user_id'] ?? '',
      adminTags: json['admin_tags'] != null 
          ? List<String>.from(jsonDecode(json['admin_tags']))
          : null,
      adminAvatar: json['admin_avatar'],
      adminNickname: json['admin_nickname'],
      adminRegisterTime: json['admin_register_time'] != null 
          ? DateTime.parse(json['admin_register_time'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'admin_tags': adminTags != null ? jsonEncode(adminTags) : null,
      'admin_avatar': adminAvatar,
      'admin_nickname': adminNickname,
      'admin_register_time': adminRegisterTime?.toIso8601String().split('T')[0],
    };
  }
}

/// 完整用户信息（包含扩展信息）
class FullUserInfo {
  final User user;
  final ConsumerInfo? consumerInfo;
  final AnchorInfo? anchorInfo;
  final ServiceInfo? serviceInfo;
  final AdminInfo? adminInfo;

  FullUserInfo({
    required this.user,
    this.consumerInfo,
    this.anchorInfo,
    this.serviceInfo,
    this.adminInfo,
  });

  factory FullUserInfo.fromJson(Map<String, dynamic> json) {
    return FullUserInfo(
      user: User.fromJson(json),
      consumerInfo: json['consumer_info'] != null 
          ? ConsumerInfo.fromJson(json['consumer_info'])
          : null,
      anchorInfo: json['live_info'] != null 
          ? AnchorInfo.fromJson(json['live_info'])
          : null,
      serviceInfo: json['kefu_info'] != null 
          ? ServiceInfo.fromJson(json['kefu_info'])
          : null,
      adminInfo: json['admin_info'] != null 
          ? AdminInfo.fromJson(json['admin_info'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final json = user.toJson();
    if (consumerInfo != null) json['consumer_info'] = consumerInfo!.toJson();
    if (anchorInfo != null) json['live_info'] = anchorInfo!.toJson();
    if (serviceInfo != null) json['kefu_info'] = serviceInfo!.toJson();
    if (adminInfo != null) json['admin_info'] = adminInfo!.toJson();
    return json;
  }
}

/// 游戏模型
class Game {
  final int id;
  final String name;
  final String? icon;
  final String? cover;
  final String? description;
  final String? version;
  final int? size;
  final String? downloadUrl;
  final double? rating;
  final int? downloadCount;
  final String? categoryName;

  Game({
    required this.id,
    required this.name,
    this.icon,
    this.cover,
    this.description,
    this.version,
    this.size,
    this.downloadUrl,
    this.rating,
    this.downloadCount,
    this.categoryName,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      icon: json['icon'],
      cover: json['cover'],
      description: json['description'],
      version: json['version'],
      size: json['size'],
      downloadUrl: json['download_url'],
      rating: json['rating']?.toDouble(),
      downloadCount: json['download_count'],
      categoryName: json['category_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'cover': cover,
      'description': description,
      'version': version,
      'size': size,
      'download_url': downloadUrl,
      'rating': rating,
      'download_count': downloadCount,
      'category_name': categoryName,
    };
  }
}

/// 礼物类型模型
class GiftType {
  final int id;
  final String name;
  final String? icon;
  final double price;

  GiftType({
    required this.id,
    required this.name,
    this.icon,
    required this.price,
  });

  factory GiftType.fromJson(Map<String, dynamic> json) {
    return GiftType(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      icon: json['icon'],
      price: (json['price'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'price': price,
    };
  }
}

/// 分类类型枚举
enum CategoryType {
  video(1, '视频'),
  live(2, '直播'),
  game(3, '游戏');

  const CategoryType(this.value, this.label);
  final int value;
  final String label;

  static CategoryType fromValue(int value) {
    return CategoryType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => CategoryType.video,
    );
  }
}

/// 分类模型
class Category {
  final int id;
  final String name;
  final CategoryType type;
  final String? icon;
  final int sort;
  final int status;
  final int? parentId;

  Category({
    required this.id,
    required this.name,
    required this.type,
    this.icon,
    required this.sort,
    required this.status,
    this.parentId,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      type: CategoryType.fromValue(json['type'] ?? 1),
      icon: json['icon'],
      sort: json['sort'] ?? 0,
      status: json['status'] ?? 1,
      parentId: json['parent_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.value,
      'icon': icon,
      'sort': sort,
      'status': status,
      'parent_id': parentId,
    };
  }
}

/// 底部导航项枚举
enum BottomNavItem {
  home('首页', '/home'),
  live('直播', '/live'),
  game('游戏', '/game'),
  profile('我的', '/profile');

  const BottomNavItem(this.title, this.route);
  final String title;
  final String route;
}

/// API响应模型
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic)? fromJsonT) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: (json['message'] as String?) ?? '',
      data: json['data'] != null && fromJsonT != null ? fromJsonT(json['data']) : json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data,
    };
  }
}

/// 登录请求模型
class LoginRequest {
  final String username;
  final String password;
  final int userType;

  LoginRequest({
    required this.username,
    required this.password,
    required this.userType,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'user_type': userType,
    };
  }
}

/// 注册请求模型
class RegisterRequest {
  final String username;
  final String phone;
  final String password;
  final String nickname;
  final int gender;
  final String birthday;
  final int userType;

  RegisterRequest({
    required this.username,
    required this.phone,
    required this.password,
    required this.nickname,
    required this.gender,
    required this.birthday,
    required this.userType,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'phone': phone,
      'password': password,
      'nickname': nickname,
      'gender': gender,
      'birthday': birthday,
      'user_type': userType,
    };
  }
}