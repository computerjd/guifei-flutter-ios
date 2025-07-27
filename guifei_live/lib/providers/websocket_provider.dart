import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/websocket_service.dart';
import '../models/websocket_message_model.dart';

// WebSocket服务提供者
final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  return WebSocketService();
});

// WebSocket连接状态提供者
final webSocketConnectionProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(webSocketServiceProvider);
  return service.connectionStream;
});

// WebSocket消息流提供者
final webSocketMessageProvider = StreamProvider<WebSocketMessage>((ref) {
  final service = ref.watch(webSocketServiceProvider);
  return service.messageStream;
});

// 聊天消息列表状态
class ChatState {
  final List<WebSocketMessage> messages;
  final bool isLoading;
  final String? error;

  ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  ChatState copyWith({
    List<WebSocketMessage>? messages,
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// 聊天状态管理器
class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier() : super(ChatState());

  void addMessage(WebSocketMessage message) {
    final updatedMessages = [...state.messages, message];
    // 限制消息数量，避免内存溢出
    if (updatedMessages.length > 500) {
      updatedMessages.removeRange(0, updatedMessages.length - 500);
    }
    state = state.copyWith(messages: updatedMessages);
  }

  void clearMessages() {
    state = state.copyWith(messages: []);
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }
}

// 聊天状态提供者
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier();
});

// 观众数量状态
class ViewerCountState {
  final int count;
  final List<String> recentViewers;

  ViewerCountState({
    this.count = 0,
    this.recentViewers = const [],
  });

  ViewerCountState copyWith({
    int? count,
    List<String>? recentViewers,
  }) {
    return ViewerCountState(
      count: count ?? this.count,
      recentViewers: recentViewers ?? this.recentViewers,
    );
  }
}

// 观众数量管理器
class ViewerCountNotifier extends StateNotifier<ViewerCountState> {
  ViewerCountNotifier() : super(ViewerCountState());

  void updateViewerCount(int count, List<String> recentViewers) {
    state = state.copyWith(
      count: count,
      recentViewers: recentViewers,
    );
  }

  void incrementViewer() {
    state = state.copyWith(count: state.count + 1);
  }

  void decrementViewer() {
    final newCount = state.count > 0 ? state.count - 1 : 0;
    state = state.copyWith(count: newCount);
  }
}

// 观众数量提供者
final viewerCountProvider = StateNotifierProvider<ViewerCountNotifier, ViewerCountState>((ref) {
  return ViewerCountNotifier();
});

// 礼物动画状态
class GiftAnimationState {
  final List<GiftMessageData> activeGifts;
  final bool isPlaying;

  GiftAnimationState({
    this.activeGifts = const [],
    this.isPlaying = false,
  });

  GiftAnimationState copyWith({
    List<GiftMessageData>? activeGifts,
    bool? isPlaying,
  }) {
    return GiftAnimationState(
      activeGifts: activeGifts ?? this.activeGifts,
      isPlaying: isPlaying ?? this.isPlaying,
    );
  }
}

// 礼物动画管理器
class GiftAnimationNotifier extends StateNotifier<GiftAnimationState> {
  GiftAnimationNotifier() : super(GiftAnimationState());

  void addGift(GiftMessageData gift) {
    final updatedGifts = [...state.activeGifts, gift];
    state = state.copyWith(
      activeGifts: updatedGifts,
      isPlaying: true,
    );
  }

  void removeGift(String giftId) {
    final updatedGifts = state.activeGifts
        .where((gift) => gift.giftId != giftId)
        .toList();
    state = state.copyWith(
      activeGifts: updatedGifts,
      isPlaying: updatedGifts.isNotEmpty,
    );
  }

  void clearGifts() {
    state = state.copyWith(
      activeGifts: [],
      isPlaying: false,
    );
  }
}

// 礼物动画提供者
final giftAnimationProvider = StateNotifierProvider<GiftAnimationNotifier, GiftAnimationState>((ref) {
  return GiftAnimationNotifier();
});

// WebSocket管理器 - 统一处理所有WebSocket相关逻辑
class WebSocketManager {
  final Ref ref;
  
  WebSocketManager(this.ref) {
    _listenToMessages();
  }

  void _listenToMessages() {
    ref.listen(webSocketMessageProvider, (previous, next) {
      next.when(
        data: (message) => _handleMessage(message),
        loading: () {},
        error: (error, stack) => _handleError(error),
      );
    });
  }

  void _handleMessage(WebSocketMessage message) {
    switch (message.type) {
      case MessageType.chat:
        ref.read(chatProvider.notifier).addMessage(message);
        break;
        
      case MessageType.gift:
        ref.read(chatProvider.notifier).addMessage(message);
        if (message.data != null) {
          final giftData = GiftMessageData.fromJson(message.data);
          ref.read(giftAnimationProvider.notifier).addGift(giftData);
        }
        break;
        
      case MessageType.like:
        ref.read(chatProvider.notifier).addMessage(message);
        break;
        
      case MessageType.userJoin:
        ref.read(chatProvider.notifier).addMessage(message);
        ref.read(viewerCountProvider.notifier).incrementViewer();
        break;
        
      case MessageType.userLeave:
        ref.read(chatProvider.notifier).addMessage(message);
        ref.read(viewerCountProvider.notifier).decrementViewer();
        break;
        
      case MessageType.viewerCount:
        if (message.data != null) {
          final viewerData = ViewerCountData.fromJson(message.data);
          ref.read(viewerCountProvider.notifier).updateViewerCount(
            viewerData.count,
            viewerData.recentViewers,
          );
        }
        break;
        
      case MessageType.systemMessage:
        ref.read(chatProvider.notifier).addMessage(message);
        break;
        
      default:
        // 处理其他类型的消息
        break;
    }
  }

  void _handleError(Object error) {
    ref.read(chatProvider.notifier).setError(error.toString());
  }

  // 连接到房间
  Future<bool> connectToRoom({
    required String serverUrl,
    required String roomId,
    required String userId,
    required String userName,
    String? userAvatar,
  }) async {
    final service = ref.read(webSocketServiceProvider);
    ref.read(chatProvider.notifier).setLoading(true);
    
    try {
      final success = await service.connect(
        serverUrl: serverUrl,
        roomId: roomId,
        userId: userId,
        userName: userName,
        userAvatar: userAvatar,
      );
      
      if (success) {
        ref.read(chatProvider.notifier).setError(null);
      } else {
        ref.read(chatProvider.notifier).setError('连接失败');
      }
      
      return success;
    } catch (e) {
      ref.read(chatProvider.notifier).setError(e.toString());
      return false;
    } finally {
      ref.read(chatProvider.notifier).setLoading(false);
    }
  }

  // 断开连接
  Future<void> disconnect() async {
    final service = ref.read(webSocketServiceProvider);
    await service.disconnect();
    ref.read(chatProvider.notifier).clearMessages();
    ref.read(giftAnimationProvider.notifier).clearGifts();
  }

  // 发送聊天消息
  Future<void> sendChatMessage(String message, {String? color}) async {
    final service = ref.read(webSocketServiceProvider);
    await service.sendChatMessage(message, color: color);
  }

  // 发送礼物
  Future<void> sendGift({
    required String giftId,
    required String giftName,
    required String giftIcon,
    required int giftValue,
    int quantity = 1,
    String? animation,
  }) async {
    final service = ref.read(webSocketServiceProvider);
    await service.sendGift(
      giftId: giftId,
      giftName: giftName,
      giftIcon: giftIcon,
      giftValue: giftValue,
      quantity: quantity,
      animation: animation,
    );
  }

  // 发送点赞
  Future<void> sendLike() async {
    final service = ref.read(webSocketServiceProvider);
    await service.sendLike();
  }
}

// WebSocket管理器提供者
final webSocketManagerProvider = Provider<WebSocketManager>((ref) {
  return WebSocketManager(ref);
});