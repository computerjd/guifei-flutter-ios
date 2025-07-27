class WebSocketMessage {
  final String type;
  final String? senderId;
  final String? senderName;
  final String? senderAvatar;
  final String? roomId;
  final dynamic data;
  final DateTime timestamp;
  final String? messageId;

  WebSocketMessage({
    required this.type,
    this.senderId,
    this.senderName,
    this.senderAvatar,
    this.roomId,
    this.data,
    required this.timestamp,
    this.messageId,
  });

  factory WebSocketMessage.fromJson(Map<String, dynamic> json) {
    // 处理时间戳解析
    DateTime parsedTimestamp;
    try {
      final timestampValue = json['timestamp'];
      if (timestampValue is String) {
        parsedTimestamp = DateTime.parse(timestampValue);
      } else {
        parsedTimestamp = DateTime.now();
      }
    } catch (e) {
      parsedTimestamp = DateTime.now();
    }

    // 从data字段中提取senderName和senderAvatar（如果存在）
    String? senderName = json['senderName'] as String?;
    String? senderAvatar = json['senderAvatar'] as String?;
    
    if (json['data'] is Map<String, dynamic>) {
      final data = json['data'] as Map<String, dynamic>;
      senderName ??= data['senderName'] as String?;
      senderAvatar ??= data['senderAvatar'] as String?;
    }

    return WebSocketMessage(
      type: json['type'] as String,
      senderId: json['senderId'] as String?,
      senderName: senderName,
      senderAvatar: senderAvatar,
      roomId: json['roomId'] as String?,
      data: json['data'],
      timestamp: parsedTimestamp,
      messageId: json['messageId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'roomId': roomId,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'messageId': messageId,
    };
  }
}

// 消息类型枚举
class MessageType {
  static const String chat = 'chat';
  static const String gift = 'gift';
  static const String like = 'like';
  static const String userJoin = 'user_join';
  static const String userLeave = 'user_leave';
  static const String viewerCount = 'viewer_count';
  static const String streamStart = 'stream_start';
  static const String streamEnd = 'stream_end';
  static const String heartbeat = 'heartbeat';
  static const String error = 'error';
  static const String systemMessage = 'system_message';
}

// 聊天消息数据模型
class ChatMessageData {
  final String message;
  final String? color;
  final bool isVip;

  ChatMessageData({
    required this.message,
    this.color,
    this.isVip = false,
  });

  factory ChatMessageData.fromJson(Map<String, dynamic> json) {
    return ChatMessageData(
      message: json['message'] as String,
      color: json['color'] as String?,
      isVip: json['isVip'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'color': color,
      'isVip': isVip,
    };
  }
}

// 礼物消息数据模型
class GiftMessageData {
  final String giftId;
  final String giftName;
  final String giftIcon;
  final int giftValue;
  final int quantity;
  final String? animation;

  GiftMessageData({
    required this.giftId,
    required this.giftName,
    required this.giftIcon,
    required this.giftValue,
    required this.quantity,
    this.animation,
  });

  factory GiftMessageData.fromJson(Map<String, dynamic> json) {
    return GiftMessageData(
      giftId: json['giftId'] as String,
      giftName: json['giftName'] as String,
      giftIcon: json['giftIcon'] as String,
      giftValue: json['giftValue'] as int,
      quantity: json['quantity'] as int,
      animation: json['animation'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'giftId': giftId,
      'giftName': giftName,
      'giftIcon': giftIcon,
      'giftValue': giftValue,
      'quantity': quantity,
      'animation': animation,
    };
  }
}

// 观众数量数据模型
class ViewerCountData {
  final int count;
  final List<String> recentViewers;

  ViewerCountData({
    required this.count,
    required this.recentViewers,
  });

  factory ViewerCountData.fromJson(Map<String, dynamic> json) {
    return ViewerCountData(
      count: json['count'] as int,
      recentViewers: List<String>.from(json['recentViewers'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'recentViewers': recentViewers,
    };
  }
}

// 用户信息数据模型
class UserInfoData {
  final String userId;
  final String userName;
  final String? userAvatar;
  final bool isVip;
  final int level;

  UserInfoData({
    required this.userId,
    required this.userName,
    this.userAvatar,
    this.isVip = false,
    this.level = 1,
  });

  factory UserInfoData.fromJson(Map<String, dynamic> json) {
    return UserInfoData(
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userAvatar: json['userAvatar'] as String?,
      isVip: json['isVip'] as bool? ?? false,
      level: json['level'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'isVip': isVip,
      'level': level,
    };
  }
}