import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/html.dart';
import 'package:web_socket_channel/io.dart';
import '../models/websocket_message_model.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  StreamController<WebSocketMessage>? _messageController;
  StreamController<bool>? _connectionController;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  
  static const String _serverUrl = 'ws://localhost:3001';
  String? _roomId;
  String? _userId;
  String? _userName;
  String? _userAvatar;
  
  bool _isConnected = false;
  bool _isConnecting = false;
  bool _shouldReconnect = true;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);
  static const Duration _heartbeatInterval = Duration(seconds: 30);

  // 消息流
  Stream<WebSocketMessage> get messageStream => _messageController?.stream ?? const Stream.empty();
  
  // 连接状态流
  Stream<bool> get connectionStream => _connectionController?.stream ?? const Stream.empty();
  
  // 当前连接状态
  bool get isConnected => _isConnected;
  
  // 当前房间ID
  String? get currentRoomId => _roomId;

  /// 连接到WebSocket服务器
  Future<bool> connect({
    required String serverUrl,
    required String roomId,
    required String userId,
    required String userName,
    String? userAvatar,
  }) async {
    if (_isConnecting || _isConnected) {
      debugPrint('WebSocket: Already connecting or connected');
      return _isConnected;
    }

    _isConnecting = true;
    _roomId = roomId;
    _userId = userId;
    _userName = userName;
    _userAvatar = userAvatar;

    try {
      debugPrint('WebSocket: Connecting to $serverUrl');
      
      // 初始化流控制器
      _messageController ??= StreamController<WebSocketMessage>.broadcast();
      _connectionController ??= StreamController<bool>.broadcast();

      // 创建WebSocket连接
      final uri = Uri.parse('$serverUrl?roomId=$roomId&userId=$userId&userName=${Uri.encodeComponent(userName)}');
      if (kIsWeb) {
        _channel = HtmlWebSocketChannel.connect(uri);
      } else {
        _channel = IOWebSocketChannel.connect(uri);
      }

      // 监听消息
      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDisconnected,
      );

      // 发送加入房间消息
      await _sendJoinRoom();
      
      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempts = 0;
      
      _connectionController?.add(true);
      _startHeartbeat();
      
      debugPrint('WebSocket: Connected successfully');
      return true;
      
    } catch (e) {
      debugPrint('WebSocket: Connection failed: $e');
      _isConnecting = false;
      _isConnected = false;
      _connectionController?.add(false);
      
      if (_shouldReconnect) {
        _scheduleReconnect();
      }
      
      return false;
    }
  }

  /// 断开连接
  Future<void> disconnect() async {
    debugPrint('WebSocket: Disconnecting...');
    
    _shouldReconnect = false;
    _stopHeartbeat();
    _stopReconnectTimer();
    
    if (_isConnected && _channel != null) {
      await _sendLeaveRoom();
      await _channel?.sink.close();
    }
    
    _isConnected = false;
    _isConnecting = false;
    _connectionController?.add(false);
    
    debugPrint('WebSocket: Disconnected');
  }

  /// 发送聊天消息
  Future<void> sendChatMessage(String message, {String? color}) async {
    if (!_isConnected) {
      debugPrint('WebSocket: Not connected, cannot send message');
      return;
    }

    final chatData = ChatMessageData(
      message: message,
      color: color,
      isVip: false, // 可以根据用户状态设置
    );

    final wsMessage = WebSocketMessage(
      type: MessageType.chat,
      senderId: _userId,
      senderName: _userName,
      senderAvatar: _userAvatar,
      roomId: _roomId,
      data: chatData.toJson(),
      timestamp: DateTime.now(),
      messageId: _generateMessageId(),
    );

    await _sendMessage(wsMessage);
  }

  /// 发送礼物消息
  Future<void> sendGift({
    required String giftId,
    required String giftName,
    required String giftIcon,
    required int giftValue,
    int quantity = 1,
    String? animation,
  }) async {
    if (!_isConnected) {
      debugPrint('WebSocket: Not connected, cannot send gift');
      return;
    }

    final giftData = GiftMessageData(
      giftId: giftId,
      giftName: giftName,
      giftIcon: giftIcon,
      giftValue: giftValue,
      quantity: quantity,
      animation: animation,
    );

    final wsMessage = WebSocketMessage(
      type: MessageType.gift,
      senderId: _userId,
      senderName: _userName,
      senderAvatar: _userAvatar,
      roomId: _roomId,
      data: giftData.toJson(),
      timestamp: DateTime.now(),
      messageId: _generateMessageId(),
    );

    await _sendMessage(wsMessage);
  }

  /// 发送点赞消息
  Future<void> sendLike() async {
    if (!_isConnected) {
      debugPrint('WebSocket: Not connected, cannot send like');
      return;
    }

    final wsMessage = WebSocketMessage(
      type: MessageType.like,
      senderId: _userId,
      senderName: _userName,
      senderAvatar: _userAvatar,
      roomId: _roomId,
      data: {'count': 1},
      timestamp: DateTime.now(),
      messageId: _generateMessageId(),
    );

    await _sendMessage(wsMessage);
  }

  /// 处理接收到的消息
  void _onMessage(dynamic data) {
    try {
      final Map<String, dynamic> json = jsonDecode(data.toString());
      final message = WebSocketMessage.fromJson(json);
      
      debugPrint('WebSocket: Received message: ${message.type}');
      
      // 处理心跳响应
      if (message.type == MessageType.heartbeat) {
        debugPrint('WebSocket: Heartbeat received');
        return;
      }
      
      _messageController?.add(message);
      
    } catch (e) {
      debugPrint('WebSocket: Error parsing message: $e');
    }
  }

  /// 处理连接错误
  void _onError(error) {
    debugPrint('WebSocket: Error: $error');
    _isConnected = false;
    _connectionController?.add(false);
    
    if (_shouldReconnect) {
      _scheduleReconnect();
    }
  }

  /// 处理连接断开
  void _onDisconnected() {
    debugPrint('WebSocket: Connection closed');
    _isConnected = false;
    _connectionController?.add(false);
    _stopHeartbeat();
    
    if (_shouldReconnect) {
      _scheduleReconnect();
    }
  }

  /// 发送加入房间消息
  Future<void> _sendJoinRoom() async {
    final userInfo = UserInfoData(
      userId: _userId!,
      userName: _userName!,
      userAvatar: _userAvatar,
      isVip: false,
      level: 1,
    );

    final wsMessage = WebSocketMessage(
      type: MessageType.userJoin,
      senderId: _userId,
      senderName: _userName,
      senderAvatar: _userAvatar,
      roomId: _roomId,
      data: userInfo.toJson(),
      timestamp: DateTime.now(),
      messageId: _generateMessageId(),
    );

    await _sendMessage(wsMessage);
  }

  /// 发送离开房间消息
  Future<void> _sendLeaveRoom() async {
    final wsMessage = WebSocketMessage(
      type: MessageType.userLeave,
      senderId: _userId,
      senderName: _userName,
      senderAvatar: _userAvatar,
      roomId: _roomId,
      data: {'userId': _userId},
      timestamp: DateTime.now(),
      messageId: _generateMessageId(),
    );

    await _sendMessage(wsMessage);
  }

  /// 发送消息到服务器
  Future<void> _sendMessage(WebSocketMessage message) async {
    try {
      final jsonString = jsonEncode(message.toJson());
      _channel?.sink.add(jsonString);
      debugPrint('WebSocket: Sent message: ${message.type}');
    } catch (e) {
      debugPrint('WebSocket: Error sending message: $e');
    }
  }

  /// 开始心跳
  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
      if (_isConnected) {
        _sendHeartbeat();
      }
    });
  }

  /// 停止心跳
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// 发送心跳
  Future<void> _sendHeartbeat() async {
    final wsMessage = WebSocketMessage(
      type: MessageType.heartbeat,
      senderId: _userId,
      roomId: _roomId,
      data: {'timestamp': DateTime.now().millisecondsSinceEpoch},
      timestamp: DateTime.now(),
    );

    await _sendMessage(wsMessage);
  }

  /// 安排重连
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('WebSocket: Max reconnect attempts reached');
      return;
    }

    _reconnectAttempts++;
    debugPrint('WebSocket: Scheduling reconnect attempt $_reconnectAttempts');
    
    _stopReconnectTimer();
    _reconnectTimer = Timer(_reconnectDelay, () {
      if (_shouldReconnect && !_isConnected && !_isConnecting) {
        connect(
          serverUrl: _serverUrl!,
          roomId: _roomId!,
          userId: _userId!,
          userName: _userName!,
          userAvatar: _userAvatar,
        );
      }
    });
  }

  /// 停止重连定时器
  void _stopReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  /// 生成消息ID
  String _generateMessageId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${_userId}_${DateTime.now().microsecond}';
  }

  /// 清理资源
  void dispose() {
    _shouldReconnect = false;
    _stopHeartbeat();
    _stopReconnectTimer();
    _channel?.sink.close();
    _messageController?.close();
    _connectionController?.close();
    _messageController = null;
    _connectionController = null;
  }
}