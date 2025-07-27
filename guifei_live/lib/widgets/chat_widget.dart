import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/websocket_message_model.dart';
import '../providers/websocket_provider.dart';

class ChatWidget extends ConsumerStatefulWidget {
  final String roomId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final double height;
  final bool showInput;

  const ChatWidget({
    super.key,
    required this.roomId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    this.height = 300,
    this.showInput = true,
  });

  @override
  ConsumerState<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends ConsumerState<ChatWidget> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectToRoom();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _connectToRoom() async {
    final manager = ref.read(webSocketManagerProvider);
    await manager.connectToRoom(
      serverUrl: 'ws://localhost:3000', // 可以配置为环境变量
      roomId: widget.roomId,
      userId: widget.userId,
      userName: widget.userName,
      userAvatar: widget.userAvatar,
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final manager = ref.read(webSocketManagerProvider);
    await manager.sendChatMessage(message);
    
    _messageController.clear();
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // 聊天头部
          _buildChatHeader(),
          
          // 消息列表
          Expanded(
            child: _buildMessageList(),
          ),
          
          // 输入框
          if (widget.showInput) _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildChatHeader() {
    return Consumer(builder: (context, ref, child) {
      final connectionState = ref.watch(webSocketConnectionProvider);
      final viewerCount = ref.watch(viewerCountProvider);
      
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.pink.withOpacity(0.8),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: Row(
          children: [
            Icon(
              connectionState.when(
                data: (connected) => connected ? Icons.circle : Icons.circle_outlined,
                loading: () => Icons.circle_outlined,
                error: (_, __) => Icons.error_outline,
              ),
              color: connectionState.when(
                data: (connected) => connected ? Colors.green : Colors.red,
                loading: () => Colors.orange,
                error: (_, __) => Colors.red,
              ),
              size: 12,
            ),
            const SizedBox(width: 8),
            const Text(
              '聊天室',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(
                  Icons.visibility,
                  color: Colors.white70,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${viewerCount.count}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMessageList() {
    return Consumer(builder: (context, ref, child) {
      final chatState = ref.watch(chatProvider);
      
      // 监听新消息，自动滚动到底部
      ref.listen(chatProvider, (previous, next) {
        if (next.messages.length > (previous?.messages.length ?? 0)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }
      });
      
      if (chatState.isLoading && chatState.messages.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.pink),
        );
      }
      
      if (chatState.error != null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 8),
              Text(
                '连接失败: ${chatState.error}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _connectToRoom,
                child: const Text('重新连接'),
              ),
            ],
          ),
        );
      }
      
      if (chatState.messages.isEmpty) {
        return const Center(
          child: Text(
            '暂无消息，快来聊天吧~',
            style: TextStyle(color: Colors.white60),
          ),
        );
      }
      
      return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: chatState.messages.length,
        itemBuilder: (context, index) {
          final message = chatState.messages[index];
          return _buildMessageItem(message);
        },
      );
    });
  }

  Widget _buildMessageItem(WebSocketMessage message) {
    switch (message.type) {
      case MessageType.chat:
        return _buildChatMessage(message);
      case MessageType.gift:
        return _buildGiftMessage(message);
      case MessageType.like:
        return _buildLikeMessage(message);
      case MessageType.userJoin:
        return _buildSystemMessage(message, '${message.senderName} 加入了直播间', Colors.green);
      case MessageType.userLeave:
        return _buildSystemMessage(message, '${message.senderName} 离开了直播间', Colors.orange);
      case MessageType.systemMessage:
        return _buildSystemMessage(message, message.data?['message'] ?? '', Colors.blue);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildChatMessage(WebSocketMessage message) {
    final chatData = message.data != null 
        ? ChatMessageData.fromJson(message.data) 
        : null;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 用户头像
          CircleAvatar(
            radius: 12,
            backgroundColor: Colors.pink,
            backgroundImage: message.senderAvatar != null 
                ? NetworkImage(message.senderAvatar!) 
                : null,
            child: message.senderAvatar == null 
                ? Text(
                    message.senderName?.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          // 消息内容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 用户名和时间
                Row(
                  children: [
                    Text(
                      message.senderName ?? 'Unknown',
                      style: TextStyle(
                        color: chatData?.isVip == true ? Colors.amber : Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (chatData?.isVip == true) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'VIP',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      _formatTime(message.timestamp),
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                // 消息文本
                Text(
                  chatData?.message ?? '',
                  style: TextStyle(
                    color: chatData?.color != null 
                        ? Color(int.parse(chatData!.color!.replaceFirst('#', '0xFF')))
                        : Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGiftMessage(WebSocketMessage message) {
    final giftData = message.data != null 
        ? GiftMessageData.fromJson(message.data) 
        : null;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.withOpacity(0.3), Colors.pink.withOpacity(0.3)],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.pink.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          // 礼物图标
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.pink,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.card_giftcard,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          // 礼物信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 14),
                    children: [
                      TextSpan(
                        text: message.senderName ?? 'Unknown',
                        style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(
                        text: ' 送出了 ',
                        style: TextStyle(color: Colors.white70),
                      ),
                      TextSpan(
                        text: giftData?.giftName ?? '礼物',
                        style: const TextStyle(color: Colors.pink, fontWeight: FontWeight.bold),
                      ),
                      if (giftData?.quantity != null && giftData!.quantity > 1) ...[
                        const TextSpan(
                          text: ' x',
                          style: TextStyle(color: Colors.white70),
                        ),
                        TextSpan(
                          text: '${giftData.quantity}',
                          style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ],
                  ),
                ),
                if (giftData?.giftValue != null)
                  Text(
                    '价值: ${giftData!.giftValue} 金币',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          // 时间
          Text(
            _formatTime(message.timestamp),
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLikeMessage(WebSocketMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(
            Icons.favorite,
            color: Colors.red,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '${message.senderName} 点了个赞',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const Spacer(),
          Text(
            _formatTime(message.timestamp),
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemMessage(WebSocketMessage message, String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          Text(
            _formatTime(message.timestamp),
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _focusNode,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '说点什么...',
                hintStyle: const TextStyle(color: Colors.white60),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Colors.pink),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                suffixIcon: IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(
                    Icons.send,
                    color: Colors.pink,
                  ),
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          // 点赞按钮
          GestureDetector(
            onTap: () async {
              final manager = ref.read(webSocketManagerProvider);
              await manager.sendLike();
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.favorite,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}小时前';
    } else {
      return '${dateTime.month}/${dateTime.day} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}