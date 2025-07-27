import 'dart:convert';

/// 会话状态枚举
enum SessionStatus {
  pending('pending', '待处理'),
  active('active', '进行中'),
  closed('closed', '已关闭');

  const SessionStatus(this.value, this.label);
  final String value;
  final String label;

  static SessionStatus fromValue(String value) {
    return SessionStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => SessionStatus.pending,
    );
  }
}

/// 客服会话模型
class CustomerServiceSession {
  final String id;
  final String userId;
  final String? customerId;
  final String? customerName;
  final String? customerAvatar;
  final String? agentId;
  final SessionStatus status;
  final String subject; // 会话主题
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final Map<String, dynamic>? metadata;

  CustomerServiceSession({
    required this.id,
    required this.userId,
    this.customerId,
    this.customerName,
    this.customerAvatar,
    this.agentId,
    required this.status,
    this.subject = '客服咨询',
    required this.createdAt,
    this.updatedAt,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.metadata,
  });

  factory CustomerServiceSession.fromJson(Map<String, dynamic> json) {
    return CustomerServiceSession(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      customerId: json['customer_id'],
      customerName: json['customer_name'],
      customerAvatar: json['customer_avatar'],
      agentId: json['agent_id'],
      status: SessionStatus.fromValue(json['status'] ?? 'pending'),
      subject: json['subject'] ?? '客服咨询',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      lastMessage: json['last_message'],
      lastMessageTime: json['last_message_time'] != null ? DateTime.parse(json['last_message_time']) : null,
      unreadCount: json['unread_count'] ?? 0,
      metadata: json['metadata'] != null ? Map<String, dynamic>.from(json['metadata']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_avatar': customerAvatar,
      'agent_id': agentId,
      'status': status.value,
      'subject': subject,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'last_message': lastMessage,
      'last_message_time': lastMessageTime?.toIso8601String(),
      'unread_count': unreadCount,
      'metadata': metadata,
    };
  }

  CustomerServiceSession copyWith({
    String? id,
    String? userId,
    String? customerId,
    String? customerName,
    String? customerAvatar,
    String? agentId,
    SessionStatus? status,
    String? subject,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    Map<String, dynamic>? metadata,
  }) {
    return CustomerServiceSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerAvatar: customerAvatar ?? this.customerAvatar,
      agentId: agentId ?? this.agentId,
      status: status ?? this.status,
      subject: subject ?? this.subject,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// 客服消息模型
class CustomerServiceMessage {
  final String id;
  final String sessionId;
  final String senderId;
  final String? senderName;
  final String? senderAvatar;
  final String content;
  final String type; // text, image, file, system
  final DateTime createdAt;
  final bool isRead;
  final bool isFromCustomer;
  final Map<String, dynamic>? extra;

  bool get isFromAgent => !isFromCustomer;

  CustomerServiceMessage({
    required this.id,
    required this.sessionId,
    required this.senderId,
    this.senderName,
    this.senderAvatar,
    required this.content,
    this.type = 'text',
    required this.createdAt,
    this.isRead = false,
    this.isFromCustomer = true,
    this.extra,
  });

  factory CustomerServiceMessage.fromJson(Map<String, dynamic> json) {
    return CustomerServiceMessage(
      id: json['id'] ?? '',
      sessionId: json['session_id'] ?? '',
      senderId: json['sender_id'] ?? '',
      senderName: json['sender_name'],
      senderAvatar: json['sender_avatar'],
      content: json['content'] ?? '',
      type: json['type'] ?? 'text',
      createdAt: DateTime.parse(json['created_at']),
      isRead: json['is_read'] ?? false,
      isFromCustomer: json['is_from_customer'] ?? true,
      extra: json['extra'] != null ? Map<String, dynamic>.from(json['extra']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_avatar': senderAvatar,
      'content': content,
      'type': type,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
      'is_from_customer': isFromCustomer,
      'extra': extra,
    };
  }

  CustomerServiceMessage copyWith({
    String? id,
    String? sessionId,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    String? content,
    String? type,
    DateTime? createdAt,
    bool? isRead,
    bool? isFromCustomer,
    Map<String, dynamic>? extra,
  }) {
    return CustomerServiceMessage(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      content: content ?? this.content,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      isFromCustomer: isFromCustomer ?? this.isFromCustomer,
      extra: extra ?? this.extra,
    );
  }
}

/// 客服信息模型
class CustomerServiceAgent {
  final String id;
  final String userId;
  final String name;
  final String? avatar;
  final String status; // online, offline, busy
  final List<String> tags;
  final int activeSessionCount;
  final double rating;
  final int totalSessions;
  final DateTime? lastActiveTime;

  CustomerServiceAgent({
    required this.id,
    required this.userId,
    required this.name,
    this.avatar,
    this.status = 'offline',
    this.tags = const [],
    this.activeSessionCount = 0,
    this.rating = 5.0,
    this.totalSessions = 0,
    this.lastActiveTime,
  });

  factory CustomerServiceAgent.fromJson(Map<String, dynamic> json) {
    return CustomerServiceAgent(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      name: json['name'] ?? '',
      avatar: json['avatar'],
      status: json['status'] ?? 'offline',
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      activeSessionCount: json['active_session_count'] ?? 0,
      rating: (json['rating'] ?? 5.0).toDouble(),
      totalSessions: json['total_sessions'] ?? 0,
      lastActiveTime: json['last_active_time'] != null ? DateTime.parse(json['last_active_time']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'avatar': avatar,
      'status': status,
      'tags': tags,
      'active_session_count': activeSessionCount,
      'rating': rating,
      'total_sessions': totalSessions,
      'last_active_time': lastActiveTime?.toIso8601String(),
    };
  }
}

/// 快捷回复模板
class QuickReplyTemplate {
  final String id;
  final String title;
  final String content;
  final String category;
  final int sortOrder;
  final bool isActive;

  QuickReplyTemplate({
    required this.id,
    required this.title,
    required this.content,
    this.category = 'general',
    this.sortOrder = 0,
    this.isActive = true,
  });

  factory QuickReplyTemplate.fromJson(Map<String, dynamic> json) {
    return QuickReplyTemplate(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      category: json['category'] ?? 'general',
      sortOrder: json['sort_order'] ?? 0,
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'sort_order': sortOrder,
      'is_active': isActive,
    };
  }
}