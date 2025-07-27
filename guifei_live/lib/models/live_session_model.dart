import 'dart:convert';

enum LiveStatus {
  preparing,
  live,
  paused,
  ended,
}

class LiveSessionModel {
  final String id;
  final String streamerId;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime? endTime;
  final LiveStatus status;
  final int viewerCount;
  final int likeCount;
  final int commentCount;
  final double earnings;
  final String streamUrl;
  final String thumbnailUrl;
  final List<String> tags;
  final Map<String, dynamic> settings;

  const LiveSessionModel({
    required this.id,
    required this.streamerId,
    required this.title,
    required this.description,
    required this.startTime,
    this.endTime,
    required this.status,
    this.viewerCount = 0,
    this.likeCount = 0,
    this.commentCount = 0,
    this.earnings = 0.0,
    required this.streamUrl,
    required this.thumbnailUrl,
    this.tags = const [],
    this.settings = const {},
  });

  LiveSessionModel copyWith({
    String? id,
    String? streamerId,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    LiveStatus? status,
    int? viewerCount,
    int? likeCount,
    int? commentCount,
    double? earnings,
    String? streamUrl,
    String? thumbnailUrl,
    List<String>? tags,
    Map<String, dynamic>? settings,
  }) {
    return LiveSessionModel(
      id: id ?? this.id,
      streamerId: streamerId ?? this.streamerId,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      viewerCount: viewerCount ?? this.viewerCount,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      earnings: earnings ?? this.earnings,
      streamUrl: streamUrl ?? this.streamUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      tags: tags ?? this.tags,
      settings: settings ?? this.settings,
    );
  }

  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  bool get isLive => status == LiveStatus.live;
  bool get isEnded => status == LiveStatus.ended;
  bool get isPaused => status == LiveStatus.paused;
  bool get isPreparing => status == LiveStatus.preparing;

  String get formattedDuration {
    final duration = this.duration;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': streamerId, // 数据库中使用user_id字段
      'title': title,
      'description': description,
      'start_time': startTime.toIso8601String(), // 数据库中使用start_time字段
      'end_time': endTime?.toIso8601String(), // 数据库中使用end_time字段
      'status': _statusToInt(status), // 数据库中使用整数状态
      'online_count': viewerCount, // 数据库中使用online_count字段
      'like_count': likeCount, // 数据库中使用like_count字段
      'gift_income': earnings, // 数据库中使用gift_income字段
      'live_url': streamUrl, // 数据库中使用live_url字段
      'cover_url': thumbnailUrl, // 数据库中使用cover_url字段
      'tags': jsonEncode(tags), // 数据库中存储为JSON字符串
    };
  }

  static int _statusToInt(LiveStatus status) {
    switch (status) {
      case LiveStatus.preparing: return 0;
      case LiveStatus.live: return 1;
      case LiveStatus.paused: return 1; // 暂停状态也算直播中
      case LiveStatus.ended: return 2;
    }
  }

  factory LiveSessionModel.fromJson(Map<String, dynamic> json) {
    return LiveSessionModel(
      id: json['id']?.toString() ?? '',
      streamerId: json['streamerId'] ?? json['streamer_id'] ?? json['user_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      startTime: DateTime.parse(json['startTime'] ?? json['start_time'] ?? json['created_at'] ?? DateTime.now().toIso8601String()),
      endTime: json['endTime'] ?? json['end_time'] != null 
          ? DateTime.parse(json['endTime'] ?? json['end_time']) 
          : null,
      status: _parseStatus(json['status']),
      viewerCount: json['viewerCount'] ?? json['viewer_count'] ?? json['online_count'] ?? 0,
      likeCount: json['likeCount'] ?? json['like_count'] ?? 0,
      commentCount: json['commentCount'] ?? json['comment_count'] ?? 0,
      earnings: (json['earnings'] ?? json['gift_income'] ?? 0).toDouble(),
      streamUrl: json['streamUrl'] ?? json['stream_url'] ?? json['live_url'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? json['thumbnail_url'] ?? json['cover_url'] ?? json['cover'] ?? '',
      tags: _parseTags(json['tags']),
      settings: Map<String, dynamic>.from(json['settings'] ?? {}),
    );
  }

  static LiveStatus _parseStatus(dynamic status) {
    if (status is int) {
      switch (status) {
        case 0: return LiveStatus.preparing;
        case 1: return LiveStatus.live;
        case 2: return LiveStatus.ended;
        default: return LiveStatus.preparing;
      }
    } else if (status is String) {
      return LiveStatus.values.firstWhere(
        (e) => e.name == status,
        orElse: () => LiveStatus.preparing,
      );
    }
    return LiveStatus.preparing;
  }

  static List<String> _parseTags(dynamic tags) {
    if (tags == null) return [];
    if (tags is List) return List<String>.from(tags);
    if (tags is String) {
      try {
        final decoded = jsonDecode(tags);
        if (decoded is List) return List<String>.from(decoded);
      } catch (e) {
        // 如果解析失败，返回空列表
      }
    }
    return [];
  }

  @override
  String toString() {
    return 'LiveSessionModel(id: $id, title: $title, status: $status, viewerCount: $viewerCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LiveSessionModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}