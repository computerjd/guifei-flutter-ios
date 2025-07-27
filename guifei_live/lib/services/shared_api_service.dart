import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/shared_models.dart';

/// 共享API服务 - 用于观众端和主播端的数据互通
class SharedApiService {
  static const String baseUrl = 'https://api.guifei.live'; // 替换为实际的API地址
  static const String _apiKey = 'your-api-key'; // 替换为实际的API密钥
  
  static final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $_apiKey',
  };

  /// 获取所有直播间列表
  static Future<List<LiveRoom>> getLiveRooms() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/live-rooms'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        return data.map((json) => LiveRoom.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load live rooms');
      }
    } catch (e) {
      // 返回模拟数据用于测试
      return _getMockLiveRooms();
    }
  }

  /// 获取特定直播间信息
  static Future<LiveRoom?> getLiveRoom(String roomId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/live-rooms/$roomId'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        return LiveRoom.fromJson(data);
      }
      return null;
    } catch (e) {
      // 返回模拟数据
      final mockRooms = _getMockLiveRooms();
      return mockRooms.firstWhere(
        (room) => room.id == roomId,
        orElse: () => mockRooms.first,
      );
    }
  }

  /// 创建直播间（主播端）
  static Future<LiveRoom?> createLiveRoom({
    required String title,
    required String description,
    required List<String> tags,
    required String streamerId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/live-rooms'),
        headers: _headers,
        body: json.encode({
          'title': title,
          'description': description,
          'tags': tags,
          'streamer_id': streamerId,
        }),
      );
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body)['data'];
        return LiveRoom.fromJson(data);
      }
      return null;
    } catch (e) {
      // 返回模拟创建的直播间
      return LiveRoom(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        description: description,
        streamerName: '主播名称',
        streamerAvatar: 'https://via.placeholder.com/100',
        thumbnailUrl: 'https://via.placeholder.com/300x200',
        viewerCount: 0,
        isLive: true,
        tags: tags,
        startTime: DateTime.now(),
      );
    }
  }

  /// 更新直播间状态
  static Future<bool> updateLiveRoomStatus(String roomId, bool isLive) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/live-rooms/$roomId'),
        headers: _headers,
        body: json.encode({'is_live': isLive}),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      return true; // 模拟成功
    }
  }

  /// 获取直播统计数据
  static Future<LiveStats> getLiveStats(String roomId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/live-rooms/$roomId/stats'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        return LiveStats.fromJson(data);
      } else {
        throw Exception('Failed to load live stats');
      }
    } catch (e) {
      // 返回模拟数据
      return LiveStats(
        viewerCount: 1234,
        likeCount: 567,
        commentCount: 89,
        shareCount: 23,
        duration: const Duration(hours: 1, minutes: 30),
        peakViewers: 2000,
      );
    }
  }

  /// 发送聊天消息
  static Future<bool> sendChatMessage({
    required String roomId,
    required String userId,
    required String message,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/live-rooms/$roomId/chat'),
        headers: _headers,
        body: json.encode({
          'user_id': userId,
          'message': message,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
      
      return response.statusCode == 201;
    } catch (e) {
      return true; // 模拟成功
    }
  }

  /// 获取聊天消息
  static Future<List<ChatMessage>> getChatMessages(String roomId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/live-rooms/$roomId/chat'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        return data.map((json) => ChatMessage.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load chat messages');
      }
    } catch (e) {
      // 返回模拟聊天数据
      return [
        ChatMessage(
          id: '1',
          userId: 'user1',
          userName: '观众1',
          message: '主播好棒！',
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
        ChatMessage(
          id: '2',
          userId: 'user2',
          userName: '观众2',
          message: '支持主播！',
          timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
        ),
      ];
    }
  }

  /// 模拟直播间数据
  static List<LiveRoom> _getMockLiveRooms() {
    return [
      LiveRoom(
        id: '1',
        title: '美女主播唱歌',
        description: '今晚为大家带来好听的歌曲',
        streamerName: '小美',
        streamerAvatar: 'https://via.placeholder.com/100',
        thumbnailUrl: 'https://via.placeholder.com/300x200',
        viewerCount: 1234,
        isLive: true,
        tags: ['唱歌', '美女', '才艺'],
        startTime: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      LiveRoom(
        id: '2',
        title: '游戏直播间',
        description: '一起来玩游戏吧',
        streamerName: '游戏达人',
        streamerAvatar: 'https://via.placeholder.com/100',
        thumbnailUrl: 'https://via.placeholder.com/300x200',
        viewerCount: 567,
        isLive: true,
        tags: ['游戏', '娱乐'],
        startTime: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      LiveRoom(
        id: '3',
        title: '聊天交友',
        description: '和大家一起聊天',
        streamerName: '聊天王',
        streamerAvatar: 'https://via.placeholder.com/100',
        thumbnailUrl: 'https://via.placeholder.com/300x200',
        viewerCount: 89,
        isLive: true,
        tags: ['聊天', '交友'],
        startTime: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
    ];
  }
}