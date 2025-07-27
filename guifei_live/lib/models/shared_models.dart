/// 共享数据模型 - 用于观众端和主播端的数据互通

/// 直播间模型
class LiveRoom {
  final String id;
  final String title;
  final String description;
  final String streamerName;
  final String streamerAvatar;
  final String thumbnailUrl;
  final int viewerCount;
  final bool isLive;
  final List<String> tags;
  final DateTime startTime;
  final String? streamUrl;
  final String? rtmpUrl;

  LiveRoom({
    required this.id,
    required this.title,
    required this.description,
    required this.streamerName,
    required this.streamerAvatar,
    required this.thumbnailUrl,
    required this.viewerCount,
    required this.isLive,
    required this.tags,
    required this.startTime,
    this.streamUrl,
    this.rtmpUrl,
  });

  factory LiveRoom.fromJson(Map<String, dynamic> json) {
    return LiveRoom(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      streamerName: json['streamer_name'] ?? json['anchor_name'] ?? '',
      streamerAvatar: json['streamer_avatar'] ?? json['anchor_avatar'] ?? '',
      thumbnailUrl: json['thumbnail_url'] ?? json['cover_url'] ?? '',
      viewerCount: json['online_count'] ?? json['viewer_count'] ?? 0,
      isLive: json['status'] == 1 || json['is_live'] == true,
      tags: json['tags'] != null ? (json['tags'] is String ? [] : List<String>.from(json['tags'])) : [],
      startTime: DateTime.parse(json['start_time'] ?? DateTime.now().toIso8601String()),
      streamUrl: json['live_url'] ?? json['stream_url'],
      rtmpUrl: json['rtmp_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'streamer_name': streamerName,
      'streamer_avatar': streamerAvatar,
      'thumbnail_url': thumbnailUrl,
      'viewer_count': viewerCount,
      'is_live': isLive,
      'tags': tags,
      'start_time': startTime.toIso8601String(),
      'stream_url': streamUrl,
      'rtmp_url': rtmpUrl,
    };
  }

  LiveRoom copyWith({
    String? id,
    String? title,
    String? description,
    String? streamerName,
    String? streamerAvatar,
    String? thumbnailUrl,
    int? viewerCount,
    bool? isLive,
    List<String>? tags,
    DateTime? startTime,
    String? streamUrl,
    String? rtmpUrl,
  }) {
    return LiveRoom(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      streamerName: streamerName ?? this.streamerName,
      streamerAvatar: streamerAvatar ?? this.streamerAvatar,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      viewerCount: viewerCount ?? this.viewerCount,
      isLive: isLive ?? this.isLive,
      tags: tags ?? this.tags,
      startTime: startTime ?? this.startTime,
      streamUrl: streamUrl ?? this.streamUrl,
      rtmpUrl: rtmpUrl ?? this.rtmpUrl,
    );
  }
}

/// 直播统计数据模型
class LiveStats {
  final int viewerCount;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final Duration duration;
  final int peakViewers;
  final double revenue;
  final int giftCount;

  LiveStats({
    required this.viewerCount,
    required this.likeCount,
    required this.commentCount,
    required this.shareCount,
    required this.duration,
    required this.peakViewers,
    this.revenue = 0.0,
    this.giftCount = 0,
  });

  factory LiveStats.fromJson(Map<String, dynamic> json) {
    return LiveStats(
      viewerCount: json['viewer_count'] ?? 0,
      likeCount: json['like_count'] ?? 0,
      commentCount: json['comment_count'] ?? 0,
      shareCount: json['share_count'] ?? 0,
      duration: Duration(seconds: json['duration_seconds'] ?? 0),
      peakViewers: json['peak_viewers'] ?? 0,
      revenue: (json['revenue'] ?? 0.0).toDouble(),
      giftCount: json['gift_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'viewer_count': viewerCount,
      'like_count': likeCount,
      'comment_count': commentCount,
      'share_count': shareCount,
      'duration_seconds': duration.inSeconds,
      'peak_viewers': peakViewers,
      'revenue': revenue,
      'gift_count': giftCount,
    };
  }
}

/// 聊天消息模型
class ChatMessage {
  final String id;
  final String userId;
  final String userName;
  final String message;
  final DateTime timestamp;
  final String? userAvatar;
  final ChatMessageType type;
  final Map<String, dynamic>? metadata;

  ChatMessage({
    required this.id,
    required this.userId,
    required this.userName,
    required this.message,
    required this.timestamp,
    this.userAvatar,
    this.type = ChatMessageType.text,
    this.metadata,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? '',
      message: json['message'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      userAvatar: json['user_avatar'],
      type: ChatMessageType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => ChatMessageType.text,
      ),
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'user_avatar': userAvatar,
      'type': type.toString().split('.').last,
      'metadata': metadata,
    };
  }
}

/// 聊天消息类型
enum ChatMessageType {
  text,
  gift,
  system,
  emoji,
}

/// 用户模型
class AppUser {
  final String id;
  final String username;
  final String? avatar;
  final String? email;
  final UserRole role;
  final DateTime createdAt;
  final bool isVerified;
  final int followersCount;
  final int followingCount;

  AppUser({
    required this.id,
    required this.username,
    this.avatar,
    this.email,
    required this.role,
    required this.createdAt,
    this.isVerified = false,
    this.followersCount = 0,
    this.followingCount = 0,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      avatar: json['avatar'],
      email: json['email'],
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == json['role'],
        orElse: () => UserRole.viewer,
      ),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      isVerified: json['is_verified'] ?? false,
      followersCount: json['followers_count'] ?? 0,
      followingCount: json['following_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'avatar': avatar,
      'email': email,
      'role': role.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      'is_verified': isVerified,
      'followers_count': followersCount,
      'following_count': followingCount,
    };
  }
}

/// 用户角色
enum UserRole {
  viewer,
  streamer,
  admin,
}

/// 礼物模型
class Gift {
  final String id;
  final String name;
  final String iconUrl;
  final int price;
  final String? animationUrl;
  final GiftType type;

  Gift({
    required this.id,
    required this.name,
    required this.iconUrl,
    required this.price,
    this.animationUrl,
    required this.type,
  });

  factory Gift.fromJson(Map<String, dynamic> json) {
    return Gift(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      iconUrl: json['icon_url'] ?? '',
      price: json['price'] ?? 0,
      animationUrl: json['animation_url'],
      type: GiftType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => GiftType.normal,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon_url': iconUrl,
      'price': price,
      'animation_url': animationUrl,
      'type': type.toString().split('.').last,
    };
  }
}

/// 礼物类型
enum GiftType {
  normal,
  special,
  premium,
}

/// 直播配置模型
class LiveConfig {
  final String quality;
  final int bitrate;
  final int fps;
  final bool enableBeauty;
  final bool enableFilter;
  final String? filterType;
  final bool enableMic;
  final bool enableCamera;

  LiveConfig({
    this.quality = '720p',
    this.bitrate = 2000,
    this.fps = 30,
    this.enableBeauty = false,
    this.enableFilter = false,
    this.filterType,
    this.enableMic = true,
    this.enableCamera = true,
  });

  factory LiveConfig.fromJson(Map<String, dynamic> json) {
    return LiveConfig(
      quality: json['quality'] ?? '720p',
      bitrate: json['bitrate'] ?? 2000,
      fps: json['fps'] ?? 30,
      enableBeauty: json['enable_beauty'] ?? false,
      enableFilter: json['enable_filter'] ?? false,
      filterType: json['filter_type'],
      enableMic: json['enable_mic'] ?? true,
      enableCamera: json['enable_camera'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quality': quality,
      'bitrate': bitrate,
      'fps': fps,
      'enable_beauty': enableBeauty,
      'enable_filter': enableFilter,
      'filter_type': filterType,
      'enable_mic': enableMic,
      'enable_camera': enableCamera,
    };
  }

  LiveConfig copyWith({
    String? quality,
    int? bitrate,
    int? fps,
    bool? enableBeauty,
    bool? enableFilter,
    String? filterType,
    bool? enableMic,
    bool? enableCamera,
  }) {
    return LiveConfig(
      quality: quality ?? this.quality,
      bitrate: bitrate ?? this.bitrate,
      fps: fps ?? this.fps,
      enableBeauty: enableBeauty ?? this.enableBeauty,
      enableFilter: enableFilter ?? this.enableFilter,
      filterType: filterType ?? this.filterType,
      enableMic: enableMic ?? this.enableMic,
      enableCamera: enableCamera ?? this.enableCamera,
    );
  }
}