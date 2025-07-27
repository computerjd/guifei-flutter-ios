// 贵妃直播应用共享数据模型
// 根据新数据库设计重新构建

import 'dart:convert';

/// 直播间状态枚举
enum LiveRoomStatus {
  offline(0, '离线'),
  live(1, '直播中'),
  pause(2, '暂停');

  const LiveRoomStatus(this.value, this.label);
  final int value;
  final String label;

  static LiveRoomStatus fromValue(int value) {
    return LiveRoomStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => LiveRoomStatus.offline,
    );
  }
}

/// 直播间模型
class LiveRoom {
  final String id;
  final String anchorId;
  final String title;
  final String? cover;
  final String? description;
  final LiveRoomStatus status;
  final int viewerCount;
  final DateTime? startTime;
  final DateTime? endTime;
  final List<String>? tags;
  final int categoryId;
  final String? streamUrl;
  final String? playUrl;
  final DateTime createTime;
  final DateTime updateTime;

  LiveRoom({
    required this.id,
    required this.anchorId,
    required this.title,
    this.cover,
    this.description,
    required this.status,
    required this.viewerCount,
    this.startTime,
    this.endTime,
    this.tags,
    required this.categoryId,
    this.streamUrl,
    this.playUrl,
    required this.createTime,
    required this.updateTime,
  });

  factory LiveRoom.fromJson(Map<String, dynamic> json) {
    return LiveRoom(
      id: json['id'] ?? '',
      anchorId: json['user_id'] ?? json['anchor_id'] ?? '',
      title: json['title'] ?? '',
      cover: json['cover_url'] ?? json['cover'],
      description: json['description'],
      status: LiveRoomStatus.fromValue(json['status'] ?? 0),
      viewerCount: json['online_count'] ?? json['viewer_count'] ?? 0,
      startTime: json['start_time'] != null ? DateTime.parse(json['start_time']) : null,
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      tags: json['tags'] != null ? (json['tags'] is String ? List<String>.from(jsonDecode(json['tags'])) : List<String>.from(json['tags'])) : null,
      categoryId: json['category_id'] ?? 0,
      streamUrl: json['live_url'] ?? json['stream_url'],
      playUrl: json['play_url'],
      createTime: DateTime.parse(json['created_at'] ?? json['create_time'] ?? DateTime.now().toIso8601String()),
      updateTime: DateTime.parse(json['updated_at'] ?? json['update_time'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'anchor_id': anchorId,
      'title': title,
      'cover': cover,
      'description': description,
      'status': status.value,
      'viewer_count': viewerCount,
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'tags': tags != null ? jsonEncode(tags) : null,
      'category_id': categoryId,
      'stream_url': streamUrl,
      'play_url': playUrl,
      'create_time': createTime.toIso8601String(),
      'update_time': updateTime.toIso8601String(),
    };
  }

  LiveRoom copyWith({
    String? id,
    String? anchorId,
    String? title,
    String? cover,
    String? description,
    LiveRoomStatus? status,
    int? viewerCount,
    DateTime? startTime,
    DateTime? endTime,
    List<String>? tags,
    int? categoryId,
    String? streamUrl,
    String? playUrl,
    DateTime? createTime,
    DateTime? updateTime,
  }) {
    return LiveRoom(
      id: id ?? this.id,
      anchorId: anchorId ?? this.anchorId,
      title: title ?? this.title,
      cover: cover ?? this.cover,
      description: description ?? this.description,
      status: status ?? this.status,
      viewerCount: viewerCount ?? this.viewerCount,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      tags: tags ?? this.tags,
      categoryId: categoryId ?? this.categoryId,
      streamUrl: streamUrl ?? this.streamUrl,
      playUrl: playUrl ?? this.playUrl,
      createTime: createTime ?? this.createTime,
      updateTime: updateTime ?? this.updateTime,
    );
  }
}

/// 视频模型
class Video {
  final String id;
  final String title;
  final String? cover;
  final String? url;
  final String? description;
  final int duration; // 秒
  final int viewCount;
  final int likeCount;
  final int categoryId;
  final String uploaderId;
  final DateTime uploadTime;
  final List<String>? tags;
  final int status; // 0待审核 1已发布 2已下架

  Video({
    required this.id,
    required this.title,
    this.cover,
    this.url,
    this.description,
    required this.duration,
    required this.viewCount,
    required this.likeCount,
    required this.categoryId,
    required this.uploaderId,
    required this.uploadTime,
    this.tags,
    required this.status,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      cover: json['cover'] ?? json['video'], // 兼容cover和video字段
      url: json['url'] ?? json['video'], // 兼容url和video字段
      description: json['description'],
      duration: json['duration'] ?? 0,
      viewCount: json['view_count'] ?? 0,
      likeCount: json['like_count'] ?? 0,
      categoryId: json['category_id'] ?? 0,
      uploaderId: json['uploader_id'] ?? json['user_id'] ?? '', // 兼容两种字段名
      uploadTime: DateTime.parse(json['upload_time'] ?? json['create_time'] ?? json['created_at'] ?? DateTime.now().toIso8601String()),
      tags: json['tags'] != null ? (json['tags'] is String ? List<String>.from(jsonDecode(json['tags'])) : List<String>.from(json['tags'])) : null,
      status: json['status'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'cover': cover,
      'video': url, // 数据库中使用video字段
      'description': description,
      'duration': duration,
      'view_count': viewCount,
      'like_count': likeCount,
      'category_id': categoryId,
      'user_id': uploaderId, // 数据库中使用user_id字段
      'create_time': uploadTime.toIso8601String(), // 数据库中使用create_time字段
      'tags': tags != null ? jsonEncode(tags) : null,
      'status': status,
    };
  }

  /// 格式化时长
  String get formattedDuration {
    final hours = duration ~/ 3600;
    final minutes = (duration % 3600) ~/ 60;
    final seconds = duration % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }
}

/// 消息类型枚举
enum MessageType {
  text(1, '文本'),
  image(2, '图片'),
  gift(3, '礼物'),
  system(4, '系统'),
  join(5, '进入'),
  leave(6, '离开');

  const MessageType(this.value, this.label);
  final int value;
  final String label;

  static MessageType fromValue(int value) {
    return MessageType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => MessageType.text,
    );
  }
}

/// 聊天类型枚举
enum ChatType {
  live(1, '直播间'),
  private(2, '私聊'),
  system(3, '系统');

  const ChatType(this.value, this.label);
  final int value;
  final String label;

  static ChatType fromValue(int value) {
    return ChatType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ChatType.live,
    );
  }
}

/// 聊天消息模型
class ChatMessage {
  final String id;
  final String senderId;
  final String? receiverId;
  final String? roomId;
  final MessageType messageType;
  final ChatType chatType;
  final String content;
  final DateTime sendTime;
  final int status; // 0正常 1已删除
  final Map<String, dynamic>? extra; // 额外数据，如礼物信息

  ChatMessage({
    required this.id,
    required this.senderId,
    this.receiverId,
    this.roomId,
    required this.messageType,
    required this.chatType,
    required this.content,
    required this.sendTime,
    required this.status,
    this.extra,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      senderId: json['sender_id'] ?? '',
      receiverId: json['receiver_id'],
      roomId: json['room_id'] ?? json['relation_id'], // 兼容room_id和relation_id字段
      messageType: MessageType.fromValue(json['message_type'] ?? json['type'] ?? 1), // 兼容message_type和type字段
      chatType: ChatType.fromValue(json['chat_type'] ?? 1),
      content: json['content'] ?? '',
      sendTime: DateTime.parse(json['send_time'] ?? json['create_time'] ?? json['created_at'] ?? DateTime.now().toIso8601String()),
      status: json['status'] ?? 0,
      extra: json['extra'] != null ? (json['extra'] is String ? Map<String, dynamic>.from(jsonDecode(json['extra'])) : Map<String, dynamic>.from(json['extra'])) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'relation_id': roomId, // 数据库中使用relation_id字段
      'type': messageType.value, // 数据库中使用type字段
      'chat_type': chatType.value,
      'content': content,
      'create_time': sendTime.toIso8601String(), // 数据库中使用create_time字段
      'status': status,
      'extra': extra != null ? jsonEncode(extra) : null,
    };
  }

  /// 是否为礼物消息
  bool get isGift => messageType == MessageType.gift;

  /// 是否为系统消息
  bool get isSystem => messageType == MessageType.system;

  /// 是否为图片消息
  bool get isImage => messageType == MessageType.image;
}

/// 文件模型
class FileInfo {
  final String id;
  final String filename;
  final String originalName;
  final String path;
  final String url;
  final String mimeType;
  final int size;
  final String uploaderId;
  final DateTime uploadTime;
  final int status; // 0正常 1已删除

  FileInfo({
    required this.id,
    required this.filename,
    required this.originalName,
    required this.path,
    required this.url,
    required this.mimeType,
    required this.size,
    required this.uploaderId,
    required this.uploadTime,
    required this.status,
  });

  factory FileInfo.fromJson(Map<String, dynamic> json) {
    return FileInfo(
      id: json['id'] ?? '',
      filename: json['filename'] ?? '',
      originalName: json['original_name'] ?? '',
      path: json['path'] ?? '',
      url: json['url'] ?? '',
      mimeType: json['mime_type'] ?? '',
      size: json['size'] ?? 0,
      uploaderId: json['uploader_id'] ?? '',
      uploadTime: DateTime.parse(json['upload_time'] ?? DateTime.now().toIso8601String()),
      status: json['status'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filename': filename,
      'original_name': originalName,
      'path': path,
      'url': url,
      'mime_type': mimeType,
      'size': size,
      'uploader_id': uploaderId,
      'upload_time': uploadTime.toIso8601String(),
      'status': status,
    };
  }

  /// 格式化文件大小
  String get formattedSize {
    if (size < 1024) {
      return '${size}B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)}KB';
    } else if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
    } else {
      return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
    }
  }

  /// 是否为图片
  bool get isImage => mimeType.startsWith('image/');

  /// 是否为视频
  bool get isVideo => mimeType.startsWith('video/');

  /// 是否为音频
  bool get isAudio => mimeType.startsWith('audio/');
}

/// 系统配置模型
class SystemConfig {
  final String key;
  final String value;
  final String? description;
  final DateTime updateTime;

  SystemConfig({
    required this.key,
    required this.value,
    this.description,
    required this.updateTime,
  });

  factory SystemConfig.fromJson(Map<String, dynamic> json) {
    return SystemConfig(
      key: json['key'] ?? '',
      value: json['value'] ?? '',
      description: json['description'],
      updateTime: DateTime.parse(json['update_time'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'value': value,
      'description': description,
      'update_time': updateTime.toIso8601String(),
    };
  }
}

/// 直播统计数据模型
class LiveStats {
  final String roomId;
  final int totalViewers;
  final int peakViewers;
  final int totalMessages;
  final int totalGifts;
  final double totalIncome;
  final Duration totalDuration;
  final DateTime date;

  LiveStats({
    required this.roomId,
    required this.totalViewers,
    required this.peakViewers,
    required this.totalMessages,
    required this.totalGifts,
    required this.totalIncome,
    required this.totalDuration,
    required this.date,
  });

  factory LiveStats.fromJson(Map<String, dynamic> json) {
    return LiveStats(
      roomId: json['room_id'] ?? '',
      totalViewers: json['total_viewers'] ?? 0,
      peakViewers: json['peak_viewers'] ?? 0,
      totalMessages: json['total_messages'] ?? 0,
      totalGifts: json['total_gifts'] ?? 0,
      totalIncome: (json['total_income'] ?? 0.0).toDouble(),
      totalDuration: Duration(seconds: json['total_duration'] ?? 0),
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String().split('T')[0]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'room_id': roomId,
      'total_viewers': totalViewers,
      'peak_viewers': peakViewers,
      'total_messages': totalMessages,
      'total_gifts': totalGifts,
      'total_income': totalIncome,
      'total_duration': totalDuration.inSeconds,
      'date': date.toIso8601String().split('T')[0],
    };
  }
}

/// 礼物发送记录模型
class GiftRecord {
  final String id;
  final String senderId;
  final String receiverId;
  final String? roomId;
  final int giftId;
  final int quantity;
  final double totalPrice;
  final DateTime sendTime;

  GiftRecord({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.roomId,
    required this.giftId,
    required this.quantity,
    required this.totalPrice,
    required this.sendTime,
  });

  factory GiftRecord.fromJson(Map<String, dynamic> json) {
    return GiftRecord(
      id: json['id'] ?? '',
      senderId: json['sender_id'] ?? '',
      receiverId: json['receiver_id'] ?? '',
      roomId: json['room_id'],
      giftId: json['gift_id'] ?? 0,
      quantity: json['quantity'] ?? 1,
      totalPrice: (json['total_price'] ?? 0.0).toDouble(),
      sendTime: DateTime.parse(json['send_time'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'room_id': roomId,
      'gift_id': giftId,
      'quantity': quantity,
      'total_price': totalPrice,
      'send_time': sendTime.toIso8601String(),
    };
  }
}

/// 分页数据模型
class PageData<T> {
  final List<T> data;
  final int total;
  final int page;
  final int pageSize;
  final bool hasMore;

  PageData({
    required this.data,
    required this.total,
    required this.page,
    required this.pageSize,
  }) : hasMore = (page * pageSize) < total;

  factory PageData.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PageData<T>(
      data: (json['data'] as List? ?? [])
          .map((item) => fromJsonT(item as Map<String, dynamic>))
          .toList(),
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      pageSize: json['page_size'] ?? 10,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'total': total,
      'page': page,
      'page_size': pageSize,
      'has_more': hasMore,
    };
  }
}

/// 搜索结果模型
class SearchResult<T> {
  final List<T> results;
  final String keyword;
  final int total;
  final Duration searchTime;

  SearchResult({
    required this.results,
    required this.keyword,
    required this.total,
    required this.searchTime,
  });

  factory SearchResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return SearchResult<T>(
      results: (json['results'] as List? ?? [])
          .map((item) => fromJsonT(item as Map<String, dynamic>))
          .toList(),
      keyword: json['keyword'] ?? '',
      total: json['total'] ?? 0,
      searchTime: Duration(milliseconds: json['search_time'] ?? 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'results': results,
      'keyword': keyword,
      'total': total,
      'search_time': searchTime.inMilliseconds,
    };
  }
}