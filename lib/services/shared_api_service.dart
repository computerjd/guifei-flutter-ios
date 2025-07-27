import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/app_models.dart';
import '../models/shared_models.dart';

/// 贵妃直播应用API服务
/// 根据新数据库设计重新构建
class SharedApiService {
  static const String baseUrl = 'http://localhost:3000'; // 数据库API服务器地址
  static String? _authToken;
  
  static final Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  /// 设置认证令牌
  static void setAuthToken(String? token) {
    _authToken = token;
    if (token != null) {
      _headers['Authorization'] = 'Bearer $token';
    } else {
      _headers.remove('Authorization');
    }
  }

  /// 处理API响应
  static T _handleResponse<T>(http.Response response, T Function(Map<String, dynamic>) fromJson) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return fromJson(data['data']);
      } else {
        throw Exception(data['message'] ?? 'API请求失败');
      }
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
    }
  }

  /// 处理API列表响应
  static List<T> _handleListResponse<T>(http.Response response, T Function(Map<String, dynamic>) fromJson) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        final List<dynamic> list = data['data'] ?? [];
        return list.map((item) => fromJson(item as Map<String, dynamic>)).toList();
      } else {
        throw Exception(data['message'] ?? 'API请求失败');
      }
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
    }
  }

  // ==================== 用户相关API ====================

  /// 用户登录
  static Future<ApiResponse<Map<String, dynamic>>> login({
    required String phone,
    required String password,
    required int userType,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/login'),
        headers: _headers,
        body: json.encode({
          'phone': phone,
          'password': password,
          'user_type': userType,
        }),
      );

      final data = json.decode(response.body);
      return ApiResponse.fromJson(data, (data) => data as Map<String, dynamic>);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: '网络连接失败: $e',
      );
    }
  }

  /// 用户注册
  static Future<ApiResponse<Map<String, dynamic>>> register({
    required String username,
    required String phone,
    required String password,
    required String nickname,
    required int gender,
    required String birthday,
    required int userType,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/register'),
        headers: _headers,
        body: json.encode({
          'username': username,
          'phone': phone,
          'password': password,
          'nickname': nickname,
          'gender': gender,
          'birthday': birthday,
          'user_type': userType,
        }),
      );

      final data = json.decode(response.body);
      return ApiResponse.fromJson(data, (data) => data as Map<String, dynamic>);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: '网络连接失败: $e',
      );
    }
  }

  /// 获取用户信息
  static Future<FullUserInfo?> getUserInfo(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/$userId'),
        headers: _headers,
      );

      return _handleResponse(response, (data) => FullUserInfo.fromJson(data));
    } catch (e) {
      print('获取用户信息失败: $e');
      return null;
    }
  }

  /// 更新用户信息
  static Future<bool> updateUserInfo(String userId, Map<String, dynamic> updateData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/users/$userId'),
        headers: _headers,
        body: json.encode(updateData),
      );

      final data = json.decode(response.body);
      return data['success'] == true;
    } catch (e) {
      print('更新用户信息失败: $e');
      return false;
    }
  }

  // ==================== 直播间相关API ====================

  /// 获取直播间列表
  static Future<List<LiveRoom>> getLiveRooms({int page = 1, int pageSize = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/live-rooms?page=$page&page_size=$pageSize'),
        headers: _headers,
      );

      return _handleListResponse(response, (data) => LiveRoom.fromJson(data));
    } catch (e) {
      print('获取直播间列表失败: $e');
      return _getMockLiveRooms();
    }
  }

  /// 获取特定直播间信息
  static Future<LiveRoom?> getLiveRoom(String roomId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/live-rooms/$roomId'),
        headers: _headers,
      );

      return _handleResponse(response, (data) => LiveRoom.fromJson(data));
    } catch (e) {
      print('获取直播间信息失败: $e');
      final mockRooms = _getMockLiveRooms();
      return mockRooms.isNotEmpty ? mockRooms.first : null;
    }
  }

  /// 创建直播间
  static Future<LiveRoom?> createLiveRoom({
    required String title,
    String? cover,
    String? description,
    required int categoryId,
    List<String>? tags,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/live-rooms'),
        headers: _headers,
        body: json.encode({
          'title': title,
          'cover': cover,
          'description': description,
          'category_id': categoryId,
          'tags': tags,
        }),
      );

      return _handleResponse(response, (data) => LiveRoom.fromJson(data));
    } catch (e) {
      print('创建直播间失败: $e');
      return null;
    }
  }

  /// 更新直播间状态
  static Future<bool> updateLiveRoomStatus(String roomId, LiveRoomStatus status) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/live-rooms/$roomId/status'),
        headers: _headers,
        body: json.encode({'status': status.value}),
      );

      final data = json.decode(response.body);
      return data['success'] == true;
    } catch (e) {
      print('更新直播间状态失败: $e');
      return false;
    }
  }

  /// 点赞视频
  static Future<bool> likeVideo(String videoId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/videos/$videoId/like'),
        headers: _headers,
      );

      final data = json.decode(response.body);
      return data['success'] == true;
    } catch (e) {
      print('点赞视频失败: $e');
      return false;
    }
  }

  /// 取消点赞视频
  static Future<bool> unlikeVideo(String videoId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/videos/$videoId/like'),
        headers: _headers,
      );

      final data = json.decode(response.body);
      return data['success'] == true;
    } catch (e) {
      print('取消点赞视频失败: $e');
      return false;
    }
  }

  /// 收藏视频
  static Future<bool> favoriteVideo(String videoId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/videos/$videoId/favorite'),
        headers: _headers,
      );

      final data = json.decode(response.body);
      return data['success'] == true;
    } catch (e) {
      print('收藏视频失败: $e');
      return false;
    }
  }

  /// 取消收藏视频
  static Future<bool> unfavoriteVideo(String videoId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/videos/$videoId/favorite'),
        headers: _headers,
      );

      final data = json.decode(response.body);
      return data['success'] == true;
    } catch (e) {
      print('取消收藏视频失败: $e');
      return false;
    }
  }

  // ==================== 视频相关API ====================

  /// 获取视频列表
  static Future<List<Video>> getVideos({int page = 1, int pageSize = 20, int? categoryId}) async {
    try {
      String url = '$baseUrl/api/videos?page=$page&page_size=$pageSize';
      if (categoryId != null) {
        url += '&category_id=$categoryId';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      return _handleListResponse(response, (data) => Video.fromJson(data));
    } catch (e) {
      print('获取视频列表失败: $e');
      return _getMockVideos();
    }
  }

  /// 获取特定视频信息
  static Future<Video?> getVideo(String videoId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/videos/$videoId'),
        headers: _headers,
      );

      return _handleResponse(response, (data) => Video.fromJson(data));
    } catch (e) {
      print('获取视频信息失败: $e');
      return null;
    }
  }

  // ==================== 游戏相关API ====================

  /// 获取游戏列表
  static Future<List<Game>> getGames() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/games'),
        headers: _headers,
      );

      return _handleListResponse(response, (data) => Game.fromJson(data));
    } catch (e) {
      print('获取游戏列表失败: $e');
      return _getMockGames();
    }
  }

  // ==================== 礼物相关API ====================

  /// 获取礼物类型列表
  static Future<List<GiftType>> getGiftTypes() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/gift-types'),
        headers: _headers,
      );

      return _handleListResponse(response, (data) => GiftType.fromJson(data));
    } catch (e) {
      print('获取礼物列表失败: $e');
      return _getMockGiftTypes();
    }
  }

  /// 发送礼物
  static Future<bool> sendGift({
    required String receiverId,
    String? roomId,
    required int giftId,
    required int quantity,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/gifts/send'),
        headers: _headers,
        body: json.encode({
          'receiver_id': receiverId,
          'room_id': roomId,
          'gift_id': giftId,
          'quantity': quantity,
        }),
      );

      final data = json.decode(response.body);
      return data['success'] == true;
    } catch (e) {
      print('发送礼物失败: $e');
      return false;
    }
  }

  // ==================== 分类相关API ====================

  /// 获取分类列表
  static Future<List<Category>> getCategories({CategoryType? type}) async {
    try {
      String url = '$baseUrl/api/categories';
      if (type != null) {
        url += '?type=${type.value}';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      return _handleListResponse(response, (data) => Category.fromJson(data));
    } catch (e) {
      print('获取分类列表失败: $e');
      return _getMockCategories();
    }
  }

  // ==================== 消息相关API ====================

  /// 发送聊天消息
  static Future<bool> sendChatMessage({
    String? receiverId,
    String? roomId,
    required MessageType messageType,
    required ChatType chatType,
    required String content,
    Map<String, dynamic>? extra,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/messages'),
        headers: _headers,
        body: json.encode({
          'receiver_id': receiverId,
          'room_id': roomId,
          'message_type': messageType.value,
          'chat_type': chatType.value,
          'content': content,
          'extra': extra,
        }),
      );

      final data = json.decode(response.body);
      return data['success'] == true;
    } catch (e) {
      print('发送消息失败: $e');
      return false;
    }
  }

  /// 获取聊天消息
  static Future<List<ChatMessage>> getChatMessages({
    String? roomId,
    String? receiverId,
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      String url = '$baseUrl/api/messages?page=$page&page_size=$pageSize';
      if (roomId != null) {
        url += '&room_id=$roomId';
      }
      if (receiverId != null) {
        url += '&receiver_id=$receiverId';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      return _handleListResponse(response, (data) => ChatMessage.fromJson(data));
    } catch (e) {
      print('获取聊天消息失败: $e');
      return _getMockChatMessages();
    }
  }

  // ==================== 文件上传API ====================

  /// 上传文件
  static Future<FileInfo?> uploadFile(String filePath, String fileName) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/files/upload'),
      );
      
      request.headers.addAll(_headers);
      request.files.add(await http.MultipartFile.fromPath('file', filePath, filename: fileName));
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      return _handleResponse(response, (data) => FileInfo.fromJson(data));
    } catch (e) {
      print('文件上传失败: $e');
      return null;
    }
  }

  // ==================== 模拟数据 ====================

  /// 模拟直播间数据
  static List<LiveRoom> _getMockLiveRooms() {
    final now = DateTime.now();
    return [
      LiveRoom(
        id: 'room_001',
        anchorId: 'anchor_001',
        title: '美女主播唱歌',
        cover: 'https://via.placeholder.com/300x200',
        description: '今晚为大家带来好听的歌曲',
        status: LiveRoomStatus.live,
        viewerCount: 1234,
        startTime: now.subtract(const Duration(hours: 1)),
        tags: ['唱歌', '美女', '才艺'],
        categoryId: 1,
        createTime: now.subtract(const Duration(days: 30)),
        updateTime: now,
      ),
      LiveRoom(
        id: 'room_002',
        anchorId: 'anchor_002',
        title: '游戏直播间',
        cover: 'https://via.placeholder.com/300x200',
        description: '一起来玩游戏吧',
        status: LiveRoomStatus.live,
        viewerCount: 567,
        startTime: now.subtract(const Duration(minutes: 30)),
        tags: ['游戏', '娱乐'],
        categoryId: 2,
        createTime: now.subtract(const Duration(days: 15)),
        updateTime: now,
      ),
    ];
  }

  /// 模拟视频数据
  static List<Video> _getMockVideos() {
    final now = DateTime.now();
    return [
      Video(
        id: 'video_001',
        title: '精彩视频1',
        cover: 'https://via.placeholder.com/300x200',
        url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
        description: '这是一个精彩的视频',
        duration: 300,
        viewCount: 1000,
        likeCount: 100,
        categoryId: 1,
        uploaderId: 'user_001',
        uploadTime: now.subtract(const Duration(days: 1)),
        tags: ['精彩', '推荐'],
        status: 1,
      ),
    ];
  }

  /// 模拟游戏数据
  static List<Game> _getMockGames() {
    return [
      Game(
        id: 1,
        name: '一分快三',
        icon: 'https://via.placeholder.com/100',
        cover: 'https://via.placeholder.com/300x200',
        description: '经典快三游戏',
      ),
      Game(
        id: 2,
        name: '时时彩',
        icon: 'https://via.placeholder.com/100',
        cover: 'https://via.placeholder.com/300x200',
        description: '时时彩游戏',
      ),
    ];
  }

  /// 模拟礼物数据
  static List<GiftType> _getMockGiftTypes() {
    return [
      GiftType(
        id: 1,
        name: '玫瑰花',
        icon: 'https://via.placeholder.com/100',
        price: 1.0,
      ),
      GiftType(
        id: 2,
        name: '跑车',
        icon: 'https://via.placeholder.com/100',
        price: 100.0,
      ),
    ];
  }

  /// 模拟分类数据
  static List<Category> _getMockCategories() {
    return [
      Category(
        id: 1,
        name: '娱乐',
        type: CategoryType.live,
        sort: 1,
        status: 1,
      ),
      Category(
        id: 2,
        name: '游戏',
        type: CategoryType.live,
        sort: 2,
        status: 1,
      ),
    ];
  }

  /// 模拟聊天消息数据
  static List<ChatMessage> _getMockChatMessages() {
    final now = DateTime.now();
    return [
      ChatMessage(
        id: 'msg_001',
        senderId: 'user_001',
        roomId: 'room_001',
        messageType: MessageType.text,
        chatType: ChatType.live,
        content: '主播好棒！',
        sendTime: now.subtract(const Duration(minutes: 5)),
        status: 0,
      ),
      ChatMessage(
        id: 'msg_002',
        senderId: 'user_002',
        roomId: 'room_001',
        messageType: MessageType.text,
        chatType: ChatType.live,
        content: '支持主播！',
        sendTime: now.subtract(const Duration(minutes: 3)),
        status: 0,
      ),
    ];
  }
}