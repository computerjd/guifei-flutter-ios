import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/live_session_model.dart';
import '../models/shared_models.dart';

/// 数据库服务类
/// 通过HTTP API与后端数据库进行交互
/// 确保Flutter应用和Web管理系统使用同一个数据库
class DatabaseService {
  static const String baseUrl = 'http://localhost:3000/api'; // 数据库API服务器地址
  static const Duration timeout = Duration(seconds: 30);
  
  // 单例模式
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  String? _authToken;
  
  // 设置认证令牌
  void setAuthToken(String token) {
    _authToken = token;
  }

  // 获取请求头
  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    
    return headers;
  }

  // 通用请求方法
  Future<Map<String, dynamic>> _request(String method, String endpoint, [Map<String, dynamic>? data]) async {
    try {
      late http.Response response;
      final uri = Uri.parse('$baseUrl$endpoint');
      
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: _headers).timeout(timeout);
          break;
        case 'POST':
          response = await http.post(
            uri,
            headers: _headers,
            body: data != null ? json.encode(data) : null,
          ).timeout(timeout);
          break;
        case 'PUT':
          response = await http.put(
            uri,
            headers: _headers,
            body: data != null ? json.encode(data) : null,
          ).timeout(timeout);
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: _headers).timeout(timeout);
          break;
        default:
          throw DatabaseException('不支持的HTTP方法: $method');
      }
      
      return _handleResponse(response);
    } catch (e) {
      throw DatabaseException('数据库请求失败: $e');
    }
  }

  // 处理响应
  Map<String, dynamic> _handleResponse(http.Response response) {
    final data = json.decode(response.body) as Map<String, dynamic>;
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      throw DatabaseException(
        data['message'] ?? '请求失败',
        statusCode: response.statusCode,
      );
    }
  }

  // 用户相关操作
  
  /// 创建用户
  Future<String> createUser({
    required String email,
    required String password,
    required String nickname,
  }) async {
    final data = await _request('POST', '/users', {
      'email': email,
      'password': password,
      'nickname': nickname,
    });
    return data['userId'] as String;
  }

  /// 根据邮箱获取用户
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final data = await _request('GET', '/users/email/$email');
      return UserModel.fromJson(data['user']);
    } catch (e) {
      if (e is DatabaseException && e.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  /// 根据ID获取用户
  Future<UserModel?> getUserById(String id) async {
    try {
      final data = await _request('GET', '/users/$id');
      return UserModel.fromJson(data['user']);
    } catch (e) {
      if (e is DatabaseException && e.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  /// 更新用户状态
  Future<void> updateUserStatus(String userId, String status) async {
    await _request('PUT', '/users/$userId/status', {
      'status': status,
    });
  }

  /// 更新用户信息
  Future<UserModel> updateUser(UserModel user) async {
    final data = await _request('PUT', '/users/${user.id}', user.toJson());
    return UserModel.fromJson(data['user']);
  }

  /// 更新用户统计数据
  Future<void> updateUserStats(String userId) async {
    await _request('POST', '/users/$userId/update-stats');
  }

  // 直播间相关操作
  
  /// 创建直播间
  Future<String> createLiveRoom({
    required String streamerId,
    required String title,
    required String description,
    String? thumbnailUrl,
  }) async {
    final data = await _request('POST', '/live-rooms', {
      'streamerId': streamerId,
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
    });
    return data['roomId'] as String;
  }

  /// 获取直播间信息
  Future<LiveRoom?> getLiveRoom(String roomId) async {
    try {
      final data = await _request('GET', '/live-rooms/$roomId');
      return LiveRoom.fromJson(data['room']);
    } catch (e) {
      if (e is DatabaseException && e.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  /// 更新直播间状态
  Future<void> updateLiveRoomStatus(String roomId, bool isLive) async {
    await _request('PUT', '/live-rooms/$roomId/status', {
      'isLive': isLive,
    });
  }

  /// 获取活跃直播间列表
  Future<List<LiveRoom>> getActiveLiveRooms() async {
    final data = await _request('GET', '/live-rooms/active');
    final rooms = data['rooms'] as List;
    return rooms.map((room) => LiveRoom.fromJson(room)).toList();
  }

  // 直播会话相关操作
  
  /// 创建直播会话
  Future<String> createLiveSession({
    required String roomId,
    required String streamerId,
    required String title,
    required String description,
  }) async {
    final data = await _request('POST', '/live-sessions', {
      'roomId': roomId,
      'streamerId': streamerId,
      'title': title,
      'description': description,
    });
    return data['sessionId'] as String;
  }

  /// 更新直播会话
  Future<void> updateLiveSession(String sessionId, Map<String, dynamic> updates) async {
    await _request('PUT', '/live-sessions/$sessionId', updates);
  }

  /// 结束直播会话
  Future<void> endLiveSession(String sessionId) async {
    await _request('POST', '/live-sessions/$sessionId/end');
  }

  /// 获取直播历史
  Future<List<LiveSessionModel>> getLiveHistory(String streamerId, {int page = 1, int limit = 20}) async {
    final data = await _request('GET', '/live-sessions/history/$streamerId?page=$page&limit=$limit');
    final sessions = data['sessions'] as List;
    return sessions.map((session) => LiveSessionModel.fromJson(session)).toList();
  }

  // 聊天消息相关操作
  
  /// 保存聊天消息
  Future<String> saveChatMessage({
    required String roomId,
    String? sessionId,
    required String userId,
    required String userName,
    String? userAvatar,
    required String message,
    String messageType = 'text',
  }) async {
    final data = await _request('POST', '/chat-messages', {
      'roomId': roomId,
      'sessionId': sessionId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'message': message,
      'messageType': messageType,
    });
    return data['messageId'] as String;
  }

  /// 获取聊天消息
  Future<List<ChatMessage>> getChatMessages(String roomId, {int limit = 50}) async {
    final data = await _request('GET', '/chat-messages/$roomId?limit=$limit');
    final messages = data['messages'] as List;
    return messages.map((message) => ChatMessage.fromJson(message)).toList();
  }

  // 礼物相关操作
  
  /// 保存礼物记录
  Future<String> saveGift({
    required String roomId,
    String? sessionId,
    required String senderId,
    required String receiverId,
    required String giftTypeId,
    int giftCount = 1,
    required double totalPrice,
    String? message,
  }) async {
    final data = await _request('POST', '/gifts', {
      'roomId': roomId,
      'sessionId': sessionId,
      'senderId': senderId,
      'receiverId': receiverId,
      'giftTypeId': giftTypeId,
      'giftCount': giftCount,
      'totalPrice': totalPrice,
      'message': message,
    });
    return data['giftId'] as String;
  }

  /// 获取礼物类型列表
  Future<List<Map<String, dynamic>>> getGiftTypes() async {
    final data = await _request('GET', '/gift-types');
    return List<Map<String, dynamic>>.from(data['giftTypes']);
  }

  // 用户会话管理
  
  /// 创建用户会话
  Future<String> createUserSession({
    required String userId,
    required String socketId,
    String? roomId,
    String deviceType = 'mobile',
    Map<String, dynamic>? deviceInfo,
    String? ipAddress,
    String? userAgent,
  }) async {
    final data = await _request('POST', '/user-sessions', {
      'userId': userId,
      'socketId': socketId,
      'roomId': roomId,
      'deviceType': deviceType,
      'deviceInfo': deviceInfo,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
    });
    return data['sessionId'] as String;
  }

  /// 更新用户会话
  Future<void> updateUserSession(String sessionId, Map<String, dynamic> updates) async {
    await _request('PUT', '/user-sessions/$sessionId', updates);
  }

  /// 移除用户会话
  Future<void> removeUserSession(String socketId) async {
    await _request('DELETE', '/user-sessions/socket/$socketId');
  }

  /// 获取用户会话列表
  Future<List<Map<String, dynamic>>> getUserSessions(String userId) async {
    final data = await _request('GET', '/user-sessions/user/$userId');
    return List<Map<String, dynamic>>.from(data['sessions']);
  }

  // 统计数据
  
  /// 获取仪表盘统计数据
  Future<Map<String, dynamic>> getDashboardStats() async {
    final data = await _request('GET', '/stats/dashboard');
    return data['stats'];
  }

  /// 获取用户统计数据
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    final data = await _request('GET', '/stats/user/$userId');
    return data['stats'];
  }

  /// 获取直播间统计数据
  Future<LiveStats> getLiveRoomStats(String roomId) async {
    final data = await _request('GET', '/stats/room/$roomId');
    return LiveStats.fromJson(data['stats']);
  }

  // 系统日志
  
  /// 保存系统日志
  Future<String> saveSystemLog({
    required String level,
    required String category,
    required String message,
    Map<String, dynamic>? details,
    String? userId,
    String? adminId,
    String? ipAddress,
    String? userAgent,
  }) async {
    final data = await _request('POST', '/system-logs', {
      'level': level,
      'category': category,
      'message': message,
      'details': details,
      'userId': userId,
      'adminId': adminId,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
    });
    return data['logId'] as String;
  }

  /// 获取系统日志
  Future<List<Map<String, dynamic>>> getSystemLogs({
    String? level,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    final queryParams = <String, String>{};
    if (level != null) queryParams['level'] = level;
    if (category != null) queryParams['category'] = category;
    if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
    if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();
    if (limit != null) queryParams['limit'] = limit.toString();
    
    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    
    final endpoint = '/system-logs${queryString.isNotEmpty ? '?$queryString' : ''}';
    final data = await _request('GET', endpoint);
    return List<Map<String, dynamic>>.from(data['logs']);
  }

  // 关注关系
  
  /// 关注用户
  Future<void> followUser(String followerId, String followingId) async {
    await _request('POST', '/follows', {
      'followerId': followerId,
      'followingId': followingId,
    });
  }

  /// 取消关注
  Future<void> unfollowUser(String followerId, String followingId) async {
    await _request('DELETE', '/follows/$followerId/$followingId');
  }

  /// 检查是否已关注
  Future<bool> isFollowing(String followerId, String followingId) async {
    try {
      final data = await _request('GET', '/follows/$followerId/$followingId');
      return data['isFollowing'] as bool;
    } catch (e) {
      if (e is DatabaseException && e.statusCode == 404) {
        return false;
      }
      rethrow;
    }
  }

  /// 获取关注列表
  Future<List<UserModel>> getFollowing(String userId) async {
    final data = await _request('GET', '/follows/$userId/following');
    final users = data['users'] as List;
    return users.map((user) => UserModel.fromJson(user)).toList();
  }

  /// 获取粉丝列表
  Future<List<UserModel>> getFollowers(String userId) async {
    final data = await _request('GET', '/follows/$userId/followers');
    final users = data['users'] as List;
    return users.map((user) => UserModel.fromJson(user)).toList();
  }
}

/// 数据库异常类
class DatabaseException implements Exception {
  final String message;
  final int? statusCode;
  
  const DatabaseException(this.message, {this.statusCode});
  
  @override
  String toString() {
    return 'DatabaseException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
  }
}