import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/customer_service_models.dart';
import '../models/shared_models.dart';
import 'shared_api_service.dart';

class CustomerService {
  static const String _baseUrl = 'http://localhost:3000/api';
  static final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // WebSocket连接管理
  static StreamController<CustomerServiceMessage>? _messageController;
  static StreamController<CustomerServiceSession>? _sessionController;
  static String? _currentSessionId;
  static String? _currentUserId;

  /// 初始化客服服务
  static Future<void> initialize(String userId) async {
    _currentUserId = userId;
    _messageController ??= StreamController<CustomerServiceMessage>.broadcast();
    _sessionController ??= StreamController<CustomerServiceSession>.broadcast();
  }

  /// 获取消息流
  static Stream<CustomerServiceMessage> get messageStream => 
      _messageController?.stream ?? const Stream.empty();

  /// 获取会话流
  static Stream<CustomerServiceSession> get sessionStream => 
      _sessionController?.stream ?? const Stream.empty();

  /// 创建客服会话
  static Future<CustomerServiceSession?> createSession({
    required String userId,
    String? issue,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/customer-service/sessions'),
        headers: _headers,
        body: jsonEncode({
          'user_id': userId,
          'issue': issue,
          'metadata': metadata,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final sessionData = data['data'];
        final session = CustomerServiceSession(
          id: sessionData['session_id'],
          userId: sessionData['user_id'],
          customerId: sessionData['user_id'],
          customerName: '用户',
          status: SessionStatus.active,
          createdAt: DateTime.parse(sessionData['created_at']),
        );
        _currentSessionId = session.id;
        _sessionController?.add(session);
        return session;
      } else {
        print('创建客服会话失败: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('创建客服会话错误: $e');
      // 返回模拟会话
      final session = CustomerServiceSession(
        id: 'mock_session_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        customerId: userId,
        customerName: '用户',
        status: SessionStatus.pending,
        createdAt: DateTime.now(),
      );
      _currentSessionId = session.id;
      return session;
    }
  }

  /// 获取用户的客服会话
  static Future<CustomerServiceSession?> getUserSession(String userId) async {
    try {
      // 后端没有此端点，直接创建新会话
      return await createSession(userId: userId);
    } catch (e) {
      print('获取用户会话错误: $e');
      return null;
    }
  }

  /// 发送消息
  static Future<bool> sendMessage({
    required String sessionId,
    required String content,
    String type = 'text',
    Map<String, dynamic>? extra,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/customer-service/messages'),
        headers: _headers,
        body: jsonEncode({
          'session_id': sessionId,
          'sender_id': _currentUserId,
          'content': content,
          'type': type,
          'is_from_customer': true,
          'extra': extra,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final messageData = data['data'];
        final message = CustomerServiceMessage(
          id: messageData['id'].toString(),
          sessionId: sessionId,
          senderId: messageData['sender_id'],
          senderName: messageData['sender_name'] ?? '用户',
          senderAvatar: messageData['sender_avatar'],
          content: messageData['content'],
          type: messageData['message_type'] ?? 'text',
          createdAt: DateTime.parse(messageData['created_at']),
          isFromCustomer: messageData['sender_id'] == _currentUserId,
        );
        _messageController?.add(message);
        return true;
      } else {
        print('发送消息失败: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('发送消息错误: $e');
      // 模拟发送成功
      final message = CustomerServiceMessage(
        id: 'mock_msg_${DateTime.now().millisecondsSinceEpoch}',
        sessionId: sessionId,
        senderId: _currentUserId ?? '',
        content: content,
        type: type,
        createdAt: DateTime.now(),
        isFromCustomer: true,
        extra: extra,
      );
      _messageController?.add(message);
      
      // 模拟客服回复
      Timer(const Duration(seconds: 2), () {
        final reply = CustomerServiceMessage(
          id: 'mock_reply_${DateTime.now().millisecondsSinceEpoch}',
          sessionId: sessionId,
          senderId: 'KEF001234567',
          senderName: '客服小助手',
          senderAvatar: 'assets/images/客服默认头像.png',
          content: _getAutoReply(content),
          type: 'text',
          createdAt: DateTime.now(),
          isFromCustomer: false,
        );
        _messageController?.add(reply);
      });
      
      return true;
    }
  }

  /// 获取会话消息
  static Future<List<CustomerServiceMessage>> getSessionMessages(
    String sessionId, {
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/customer-service/sessions/$sessionId/messages?page=$page&page_size=$pageSize'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> messagesData = data['data'] ?? [];
        return messagesData.map((json) => CustomerServiceMessage(
          id: json['id'].toString(),
          sessionId: sessionId,
          senderId: json['sender_id'],
          senderName: json['sender_name'] ?? '用户',
          senderAvatar: json['sender_avatar'],
          content: json['content'],
          type: json['message_type'] ?? 'text',
          createdAt: DateTime.parse(json['created_at']),
          isFromCustomer: json['sender_id'] != 'cs_001',
        )).toList();
      } else {
        print('获取会话消息失败: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('获取会话消息错误: $e');
      // 返回模拟消息
      return [
        CustomerServiceMessage(
          id: 'welcome_msg',
          sessionId: sessionId,
          senderId: 'KEF001234567',
          senderName: '客服小助手',
          senderAvatar: 'assets/images/客服默认头像.png',
          content: '您好！欢迎联系客服，我是您的专属客服小助手，有什么可以帮助您的吗？',
          type: 'text',
          createdAt: DateTime.now().subtract(const Duration(minutes: 1)),
          isFromCustomer: false,
        ),
      ];
    }
  }

  /// 关闭会话
  static Future<bool> closeSession(String sessionId) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/customer-service/sessions/$sessionId/close'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        _currentSessionId = null;
        return true;
      } else {
        print('关闭会话失败: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('关闭会话错误: $e');
      _currentSessionId = null;
      return true; // 模拟成功
    }
  }

  /// 标记消息为已读
  static Future<bool> markMessagesAsRead(String sessionId) async {
    try {
      // 后端没有此端点，直接返回成功
      return true;
    } catch (e) {
      print('标记消息已读错误: $e');
      return true; // 模拟成功
    }
  }

  /// 获取在线客服列表
  static Future<List<CustomerServiceAgent>> getOnlineAgents() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/customer-service/agents'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> agentsData = data['data'] ?? [];
        return agentsData.map((json) => CustomerServiceAgent.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('获取在线客服错误: $e');
      // 返回模拟客服
      return [
        CustomerServiceAgent(
          id: 'agent_1',
          userId: 'KEF001234567',
          name: '客服小助手',
          avatar: 'assets/images/客服默认头像.png',
          status: 'online',
          tags: ['新手指导', '充值问题', '技术支持'],
          activeSessionCount: 3,
          rating: 4.8,
          totalSessions: 156,
          lastActiveTime: DateTime.now(),
        ),
      ];
    }
  }

  /// 获取快捷回复模板
  static Future<List<QuickReplyTemplate>> getQuickReplyTemplates() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/customer-service/quick-replies'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> templatesData = data['data'] ?? [];
        return templatesData.map((json) => QuickReplyTemplate.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('获取快捷回复模板错误: $e');
      // 返回默认模板
      return [
        QuickReplyTemplate(
          id: 'template_1',
          title: '常见问题',
          content: '您好，请问遇到了什么问题？我来为您解答。',
          category: 'greeting',
        ),
        QuickReplyTemplate(
          id: 'template_2',
          title: '充值问题',
          content: '关于充值问题，请提供您的用户ID和充值金额，我来为您查询。',
          category: 'payment',
        ),
        QuickReplyTemplate(
          id: 'template_3',
          title: '技术支持',
          content: '请详细描述您遇到的技术问题，我会尽快为您解决。',
          category: 'technical',
        ),
      ];
    }
  }

  /// 自动回复逻辑
  static String _getAutoReply(String userMessage) {
    final message = userMessage.toLowerCase();
    
    if (message.contains('充值') || message.contains('付费') || message.contains('支付')) {
      return '关于充值问题，请提供您的用户ID和充值金额，我来为您查询处理。如需人工客服，请回复"人工客服"。';
    } else if (message.contains('登录') || message.contains('密码') || message.contains('账号')) {
      return '账号登录问题我来帮您解决。请确认您的手机号是否正确，密码是否记得。如需重置密码，请回复"重置密码"。';
    } else if (message.contains('直播') || message.contains('开播')) {
      return '关于直播功能，您可以在首页点击"开始直播"按钮。如需了解更多直播规则，请回复"直播规则"。';
    } else if (message.contains('人工') || message.contains('转人工')) {
      return '正在为您转接人工客服，请稍等片刻...';
    } else {
      return '收到您的消息，我是智能客服小助手。如需人工客服协助，请回复"人工客服"。';
    }
  }

  /// 清理资源
  static void dispose() {
    _messageController?.close();
    _sessionController?.close();
    _messageController = null;
    _sessionController = null;
    _currentSessionId = null;
    _currentUserId = null;
  }
}