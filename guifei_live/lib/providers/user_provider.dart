import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';

// 用户状态Provider
final userProvider = StateNotifierProvider<UserNotifier, UserModel?>((ref) {
  return UserNotifier();
});

class UserNotifier extends StateNotifier<UserModel?> {
  UserNotifier() : super(null) {
    // 初始化时加载用户数据
    _loadUser();
  }

  void _loadUser() {
    // 模拟用户数据，实际应用中应该从本地存储或服务器加载
    state = UserModel(
      id: 'user_123456',
      username: 'guifei_streamer',
      phone: '13800138000',
      nickname: '贵妃主播',
      avatar: 'https://example.com/avatar.jpg',
      gender: 2, // 女性
      birthday: DateTime(1995, 6, 15),
      status: 1, // 正常状态
      registerTime: DateTime(2023, 6, 15),
      userType: 2, // 主播
    );
  }

  void updateUser(UserModel user) {
    state = user;
  }

  void updateNickname(String nickname) {
    if (state != null) {
      state = state!.copyWith(nickname: nickname);
    }
  }

  void updateAvatar(String avatar) {
    if (state != null) {
      state = state!.copyWith(avatar: avatar);
    }
  }

  void updateDescription(String description) {
    // UserModel中没有description字段，这里暂时注释
    // if (state != null) {
    //   state = state!.copyWith(description: description);
    // }
  }

  void incrementFollowerCount() {
    // UserModel中没有followerCount字段，这里暂时注释
    // if (state != null) {
    //   state = state!.copyWith(followerCount: state!.followerCount + 1);
    // }
  }

  void addViews(int views) {
    // UserModel中没有totalViews字段，这里暂时注释
    // if (state != null) {
    //   state = state!.copyWith(totalViews: state!.totalViews + views);
    // }
  }

  void addEarnings(double earnings) {
    // UserModel中没有totalEarnings字段，这里暂时注释
    // if (state != null) {
    //   state = state!.copyWith(totalEarnings: state!.totalEarnings + earnings);
    // }
  }

  void logout() {
    state = null;
  }
}

// 用户统计数据Provider
final userStatsProvider = Provider<UserStats>((ref) {
  final user = ref.watch(userProvider);
  if (user == null) {
    return UserStats.empty();
  }
  
  return UserStats(
    followerCount: 0, // 暂时使用默认值
    totalViews: 0, // 暂时使用默认值
    totalEarnings: 0.0, // 暂时使用默认值
    joinDays: DateTime.now().difference(user.registerTime).inDays,
    averageViewsPerDay: 0.0, // 暂时使用默认值
  );
});

class UserStats {
  final int followerCount;
  final int totalViews;
  final double totalEarnings;
  final int joinDays;
  final double averageViewsPerDay;

  const UserStats({
    required this.followerCount,
    required this.totalViews,
    required this.totalEarnings,
    required this.joinDays,
    required this.averageViewsPerDay,
  });

  factory UserStats.empty() {
    return const UserStats(
      followerCount: 0,
      totalViews: 0,
      totalEarnings: 0.0,
      joinDays: 0,
      averageViewsPerDay: 0.0,
    );
  }

  String get formattedFollowerCount {
    if (followerCount >= 1000000) {
      return '${(followerCount / 1000000).toStringAsFixed(1)}M';
    } else if (followerCount >= 1000) {
      return '${(followerCount / 1000).toStringAsFixed(1)}K';
    }
    return followerCount.toString();
  }

  String get formattedTotalViews {
    if (totalViews >= 1000000) {
      return '${(totalViews / 1000000).toStringAsFixed(1)}M';
    } else if (totalViews >= 1000) {
      return '${(totalViews / 1000).toStringAsFixed(1)}K';
    }
    return totalViews.toString();
  }

  String get formattedTotalEarnings {
    return '¥${totalEarnings.toStringAsFixed(2)}';
  }

  String get formattedAverageViews {
    return averageViewsPerDay.toStringAsFixed(0);
  }
}