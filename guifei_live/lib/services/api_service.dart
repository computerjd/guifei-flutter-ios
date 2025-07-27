import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/live_session_model.dart';

class ApiService {
  static const String baseUrl = 'https://api.guifei.live'; // 替换为实际的API地址
  static const Duration timeout = Duration(seconds: 30);
  
  // 单例模式
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

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

  // 通用GET请求
  Future<Map<String, dynamic>> _get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
      ).timeout(timeout);
      
      return _handleResponse(response);
    } catch (e) {
      throw ApiException('网络请求失败: $e');
    }
  }

  // 通用POST请求
  Future<Map<String, dynamic>> _post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
        body: json.encode(data),
      ).timeout(timeout);
      
      return _handleResponse(response);
    } catch (e) {
      throw ApiException('网络请求失败: $e');
    }
  }

  // 通用PUT请求
  Future<Map<String, dynamic>> _put(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
        body: json.encode(data),
      ).timeout(timeout);
      
      return _handleResponse(response);
    } catch (e) {
      throw ApiException('网络请求失败: $e');
    }
  }

  // 通用DELETE请求
  Future<Map<String, dynamic>> _delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
      ).timeout(timeout);
      
      return _handleResponse(response);
    } catch (e) {
      throw ApiException('网络请求失败: $e');
    }
  }

  // 处理响应
  Map<String, dynamic> _handleResponse(http.Response response) {
    final data = json.decode(response.body) as Map<String, dynamic>;
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      throw ApiException(
        data['message'] ?? '请求失败',
        statusCode: response.statusCode,
      );
    }
  }

  // 用户相关API
  
  // 用户登录
  Future<Map<String, dynamic>> login(String email, String password) async {
    return await _post('/auth/login', {
      'email': email,
      'password': password,
    });
  }

  // 用户注册
  Future<Map<String, dynamic>> register(String email, String password, String nickname) async {
    return await _post('/auth/register', {
      'email': email,
      'password': password,
      'nickname': nickname,
    });
  }

  // 获取用户信息
  Future<UserModel> getUserInfo() async {
    final data = await _get('/user/profile');
    return UserModel.fromJson(data['user']);
  }

  // 更新用户信息
  Future<UserModel> updateUserInfo(UserModel user) async {
    final data = await _put('/user/profile', user.toJson());
    return UserModel.fromJson(data['user']);
  }

  // 直播相关API
  
  // 创建直播间
  Future<Map<String, dynamic>> createLiveRoom({
    required String title,
    required String description,
    List<String> tags = const [],
  }) async {
    return await _post('/live/create', {
      'title': title,
      'description': description,
      'tags': tags,
    });
  }

  // 开始直播
  Future<Map<String, dynamic>> startLiveStream(String roomId) async {
    return await _post('/live/$roomId/start', {});
  }

  // 结束直播
  Future<Map<String, dynamic>> endLiveStream(String roomId) async {
    return await _post('/live/$roomId/end', {});
  }

  // 获取直播统计
  Future<Map<String, dynamic>> getLiveStats(String roomId) async {
    return await _get('/live/$roomId/stats');
  }

  // 获取直播历史
  Future<List<LiveSessionModel>> getLiveHistory({
    int page = 1,
    int limit = 20,
  }) async {
    final data = await _get('/live/history?page=$page&limit=$limit');
    final sessions = data['sessions'] as List;
    return sessions.map((session) => LiveSessionModel.fromJson(session)).toList();
  }

  // 上传直播封面
  Future<String> uploadThumbnail(String filePath) async {
    // 这里应该实现文件上传逻辑
    // 返回上传后的图片URL
    throw UnimplementedError('文件上传功能待实现');
  }

  // 获取推流地址
  Future<Map<String, dynamic>> getStreamUrl(String roomId) async {
    return await _get('/live/$roomId/stream-url');
  }

  // 更新直播间信息
  Future<Map<String, dynamic>> updateLiveRoom(String roomId, {
    String? title,
    String? description,
    List<String>? tags,
  }) async {
    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (description != null) data['description'] = description;
    if (tags != null) data['tags'] = tags;
    
    return await _put('/live/$roomId', data);
  }

  // 获取观众列表
  Future<List<Map<String, dynamic>>> getViewers(String roomId) async {
    final data = await _get('/live/$roomId/viewers');
    return List<Map<String, dynamic>>.from(data['viewers']);
  }

  // 发送系统消息
  Future<void> sendSystemMessage(String roomId, String message) async {
    await _post('/live/$roomId/system-message', {
      'message': message,
    });
  }

  // 禁言用户
  Future<void> muteUser(String roomId, String userId, int duration) async {
    await _post('/live/$roomId/mute', {
      'userId': userId,
      'duration': duration, // 禁言时长（秒）
    });
  }

  // 踢出用户
  Future<void> kickUser(String roomId, String userId) async {
    await _post('/live/$roomId/kick', {
      'userId': userId,
    });
  }

  // 数据统计相关API
  
  // 获取收益统计
  Future<Map<String, dynamic>> getEarningsStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String endpoint = '/stats/earnings';
    if (startDate != null && endDate != null) {
      endpoint += '?start=${startDate.toIso8601String()}&end=${endDate.toIso8601String()}';
    }
    return await _get(endpoint);
  }

  // 获取观众统计
  Future<Map<String, dynamic>> getViewerStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    String endpoint = '/stats/viewers';
    if (startDate != null && endDate != null) {
      endpoint += '?start=${startDate.toIso8601String()}&end=${endDate.toIso8601String()}';
    }
    return await _get(endpoint);
  }

  // 获取粉丝增长统计
  Future<Map<String, dynamic>> getFollowerStats() async {
    return await _get('/stats/followers');
  }

  // 粉丝管理相关API
  
  // 获取粉丝列表
  Future<Map<String, dynamic>> getFansList({
    int page = 1,
    int limit = 50,
    String? search,
    String? filter,
  }) async {
    String endpoint = '/fans?page=$page&limit=$limit';
    if (search != null && search.isNotEmpty) {
      endpoint += '&search=$search';
    }
    if (filter != null && filter.isNotEmpty) {
      endpoint += '&filter=$filter';
    }
    return await _get(endpoint);
  }

  // 获取VIP粉丝列表
  Future<Map<String, dynamic>> getVipFans() async {
    return await _get('/fans/vip');
  }

  // 获取黑名单
  Future<Map<String, dynamic>> getBlacklist() async {
    return await _get('/fans/blacklist');
  }

  // 拉黑用户
  Future<void> blockUser(String userId, String reason) async {
    await _post('/fans/$userId/block', {
      'reason': reason,
    });
  }

  // 解除拉黑
  Future<void> unblockUser(String userId) async {
    await _delete('/fans/$userId/block');
  }

  // 设置VIP
  Future<void> setVipStatus(String userId, bool isVip) async {
    await _put('/fans/$userId/vip', {
      'isVip': isVip,
    });
  }

  // 发送私信
  Future<void> sendPrivateMessage(String userId, String message) async {
    await _post('/fans/$userId/message', {
      'message': message,
    });
  }

  // 获取粉丝详情
  Future<Map<String, dynamic>> getFanDetails(String userId) async {
    return await _get('/fans/$userId');
  }

  // 收益分析相关API
  
  // 获取收益统计
  Future<Map<String, dynamic>> getRevenueStats() async {
    return await _get('/revenue/stats');
  }

  // 获取礼物统计
  Future<Map<String, dynamic>> getGiftStats() async {
    return await _get('/revenue/gifts');
  }

  // 获取顶级粉丝贡献
  Future<Map<String, dynamic>> getTopFans() async {
    return await _get('/revenue/top-fans');
  }

  // 导出收益报告
  Future<Map<String, dynamic>> exportRevenueReport({
    required String startDate,
    required String endDate,
    String format = 'excel',
  }) async {
    return await _post('/revenue/export', {
      'startDate': startDate,
      'endDate': endDate,
      'format': format,
    });
  }

  // 直播管理相关API
  
  // 获取直播观众列表
  Future<Map<String, dynamic>> getLiveViewers() async {
    return await _get('/live/viewers');
  }



  // 获取直播评论
  Future<Map<String, dynamic>> getLiveComments() async {
    return await _get('/live/comments');
  }

  // 删除评论
  Future<void> deleteComment(String commentId) async {
    await _delete('/live/comments/$commentId');
  }



  // 取消禁言
  Future<void> unmuteUser(String userId) async {
    await _delete('/live/mute/$userId');
  }



  // 发送系统公告
  Future<void> sendAnnouncement(String message) async {
    await _post('/live/announcement', {
      'message': message,
    });
  }

  // 更新直播设置
  Future<void> updateLiveSettings(Map<String, dynamic> settings) async {
    await _put('/live/settings', settings);
  }
}

// API异常类
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  
  const ApiException(this.message, {this.statusCode});
  
  @override
  String toString() {
    if (statusCode != null) {
      return 'ApiException($statusCode): $message';
    }
    return 'ApiException: $message';
  }
}

// API响应状态
enum ApiStatus {
  loading,
  success,
  error,
}

// API响应包装类
class ApiResponse<T> {
  final ApiStatus status;
  final T? data;
  final String? error;
  
  const ApiResponse.loading() : status = ApiStatus.loading, data = null, error = null;
  const ApiResponse.success(this.data) : status = ApiStatus.success, error = null;
  const ApiResponse.error(this.error) : status = ApiStatus.error, data = null;
  
  bool get isLoading => status == ApiStatus.loading;
  bool get isSuccess => status == ApiStatus.success;
  bool get isError => status == ApiStatus.error;
}