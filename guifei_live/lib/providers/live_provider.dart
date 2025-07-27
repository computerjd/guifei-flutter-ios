import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/live_session_model.dart';

// 当前直播会话Provider
final currentLiveSessionProvider = StateNotifierProvider<LiveSessionNotifier, LiveSessionModel?>((ref) {
  return LiveSessionNotifier();
});

class LiveSessionNotifier extends StateNotifier<LiveSessionModel?> {
  LiveSessionNotifier() : super(null);
  
  Timer? _statsTimer;
  Timer? _durationTimer;

  // 开始直播
  void startLiveSession({
    required String title,
    required String description,
    List<String> tags = const [],
  }) {
    final session = LiveSessionModel(
      id: 'live_${DateTime.now().millisecondsSinceEpoch}',
      streamerId: 'user_123456', // 应该从用户Provider获取
      title: title,
      description: description,
      startTime: DateTime.now(),
      status: LiveStatus.live,
      streamUrl: 'rtmp://live.example.com/stream',
      thumbnailUrl: 'https://example.com/thumbnail.jpg',
      tags: tags,
    );
    
    state = session;
    _startTimers();
  }

  // 结束直播
  void endLiveSession() {
    if (state != null) {
      state = state!.copyWith(
        status: LiveStatus.ended,
        endTime: DateTime.now(),
      );
      _stopTimers();
    }
  }

  // 暂停直播
  void pauseLiveSession() {
    if (state != null && state!.status == LiveStatus.live) {
      state = state!.copyWith(status: LiveStatus.paused);
    }
  }

  // 恢复直播
  void resumeLiveSession() {
    if (state != null && state!.status == LiveStatus.paused) {
      state = state!.copyWith(status: LiveStatus.live);
    }
  }

  // 更新观众数量
  void updateViewerCount(int count) {
    if (state != null) {
      state = state!.copyWith(viewerCount: count);
    }
  }

  // 增加点赞数
  void incrementLikeCount() {
    if (state != null) {
      state = state!.copyWith(likeCount: state!.likeCount + 1);
    }
  }

  // 增加评论数
  void incrementCommentCount() {
    if (state != null) {
      state = state!.copyWith(commentCount: state!.commentCount + 1);
    }
  }

  // 增加收益
  void addEarnings(double amount) {
    if (state != null) {
      state = state!.copyWith(earnings: state!.earnings + amount);
    }
  }

  // 启动定时器
  void _startTimers() {
    // 模拟观众数据更新
    _statsTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (state != null && state!.isLive) {
        // 模拟观众数量变化
        final random = DateTime.now().millisecond % 10;
        final change = random > 7 ? 1 : (random < 3 ? -1 : 0);
        final newCount = (state!.viewerCount + change).clamp(0, double.infinity).toInt();
        updateViewerCount(newCount);
        
        // 模拟随机点赞
        if (random == 5) {
          incrementLikeCount();
        }
        
        // 模拟随机收益
        if (random == 8) {
          addEarnings(1.5 + (DateTime.now().millisecond % 50) / 10);
        }
      }
    });
  }

  // 停止定时器
  void _stopTimers() {
    _statsTimer?.cancel();
    _durationTimer?.cancel();
    _statsTimer = null;
    _durationTimer = null;
  }

  @override
  void dispose() {
    _stopTimers();
    super.dispose();
  }
}

// 直播历史记录Provider
final liveHistoryProvider = StateNotifierProvider<LiveHistoryNotifier, List<LiveSessionModel>>((ref) {
  return LiveHistoryNotifier();
});

class LiveHistoryNotifier extends StateNotifier<List<LiveSessionModel>> {
  LiveHistoryNotifier() : super([]) {
    _loadHistory();
  }

  void _loadHistory() {
    // 模拟历史直播数据
    final history = [
      LiveSessionModel(
        id: 'live_001',
        streamerId: 'user_123456',
        title: '晚安直播间',
        description: '和大家聊聊天，分享今天的心情',
        startTime: DateTime.now().subtract(const Duration(days: 1)),
        endTime: DateTime.now().subtract(const Duration(days: 1, hours: -2)),
        status: LiveStatus.ended,
        viewerCount: 1250,
        likeCount: 3420,
        commentCount: 890,
        earnings: 156.80,
        streamUrl: 'rtmp://live.example.com/stream',
        thumbnailUrl: 'https://example.com/thumbnail1.jpg',
        tags: ['聊天', '晚安'],
      ),
      LiveSessionModel(
        id: 'live_002',
        streamerId: 'user_123456',
        title: '美妆教程分享',
        description: '教大家日常妆容的小技巧',
        startTime: DateTime.now().subtract(const Duration(days: 3)),
        endTime: DateTime.now().subtract(const Duration(days: 3, hours: -1, minutes: -30)),
        status: LiveStatus.ended,
        viewerCount: 2100,
        likeCount: 5680,
        commentCount: 1240,
        earnings: 289.50,
        streamUrl: 'rtmp://live.example.com/stream',
        thumbnailUrl: 'https://example.com/thumbnail2.jpg',
        tags: ['美妆', '教程'],
      ),
      LiveSessionModel(
        id: 'live_003',
        streamerId: 'user_123456',
        title: '唱歌时间',
        description: '为大家献上几首好听的歌曲',
        startTime: DateTime.now().subtract(const Duration(days: 5)),
        endTime: DateTime.now().subtract(const Duration(days: 5, hours: -3)),
        status: LiveStatus.ended,
        viewerCount: 3200,
        likeCount: 8900,
        commentCount: 2100,
        earnings: 445.20,
        streamUrl: 'rtmp://live.example.com/stream',
        thumbnailUrl: 'https://example.com/thumbnail3.jpg',
        tags: ['音乐', '唱歌'],
      ),
    ];
    
    state = history;
  }

  void addSession(LiveSessionModel session) {
    state = [session, ...state];
  }

  void removeSession(String sessionId) {
    state = state.where((session) => session.id != sessionId).toList();
  }

  List<LiveSessionModel> getSessionsByDateRange(DateTime start, DateTime end) {
    return state.where((session) {
      return session.startTime.isAfter(start) && session.startTime.isBefore(end);
    }).toList();
  }

  LiveSessionModel? getSessionById(String id) {
    try {
      return state.firstWhere((session) => session.id == id);
    } catch (e) {
      return null;
    }
  }
}

// 直播统计数据Provider
final liveStatsProvider = Provider<LiveStats>((ref) {
  final history = ref.watch(liveHistoryProvider);
  final currentSession = ref.watch(currentLiveSessionProvider);
  
  return LiveStats.fromSessions(history, currentSession);
});

class LiveStats {
  final int totalSessions;
  final int totalViewers;
  final int totalLikes;
  final int totalComments;
  final double totalEarnings;
  final Duration totalDuration;
  final double averageViewers;
  final double averageEarnings;

  const LiveStats({
    required this.totalSessions,
    required this.totalViewers,
    required this.totalLikes,
    required this.totalComments,
    required this.totalEarnings,
    required this.totalDuration,
    required this.averageViewers,
    required this.averageEarnings,
  });

  factory LiveStats.fromSessions(List<LiveSessionModel> sessions, LiveSessionModel? currentSession) {
    final allSessions = [...sessions];
    if (currentSession != null) {
      allSessions.add(currentSession);
    }

    final totalSessions = allSessions.length;
    final totalViewers = allSessions.fold<int>(0, (sum, session) => sum + session.viewerCount);
    final totalLikes = allSessions.fold<int>(0, (sum, session) => sum + session.likeCount);
    final totalComments = allSessions.fold<int>(0, (sum, session) => sum + session.commentCount);
    final totalEarnings = allSessions.fold<double>(0, (sum, session) => sum + session.earnings);
    final totalDuration = allSessions.fold<Duration>(
      Duration.zero,
      (sum, session) => sum + session.duration,
    );

    final averageViewers = totalSessions > 0 ? totalViewers / totalSessions : 0.0;
    final averageEarnings = totalSessions > 0 ? totalEarnings / totalSessions : 0.0;

    return LiveStats(
      totalSessions: totalSessions,
      totalViewers: totalViewers,
      totalLikes: totalLikes,
      totalComments: totalComments,
      totalEarnings: totalEarnings,
      totalDuration: totalDuration,
      averageViewers: averageViewers,
      averageEarnings: averageEarnings,
    );
  }

  String get formattedTotalEarnings => '¥${totalEarnings.toStringAsFixed(2)}';
  String get formattedAverageEarnings => '¥${averageEarnings.toStringAsFixed(2)}';
  String get formattedAverageViewers => averageViewers.toStringAsFixed(0);
  
  String get formattedTotalDuration {
    final hours = totalDuration.inHours;
    final minutes = totalDuration.inMinutes.remainder(60);
    return '${hours}小时${minutes}分钟';
  }
}