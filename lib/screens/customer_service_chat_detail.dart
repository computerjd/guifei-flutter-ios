import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/customer_service.dart';
import '../models/customer_service_models.dart';

class CustomerServiceChatDetail extends StatefulWidget {
  final String sessionId;
  
  const CustomerServiceChatDetail({
    super.key,
    required this.sessionId,
  });

  @override
  State<CustomerServiceChatDetail> createState() => _CustomerServiceChatDetailState();
}

class _CustomerServiceChatDetailState extends State<CustomerServiceChatDetail> {
  final CustomerService _customerService = CustomerService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  CustomerServiceSession? _session;
  List<CustomerServiceMessage> _messages = [];
  List<QuickReplyTemplate> _quickReplies = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _showQuickReplies = false;

  @override
  void initState() {
    super.initState();
    _loadChatData();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChatData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 模拟加载会话和消息数据
      await Future.delayed(const Duration(milliseconds: 500));
      
      final session = CustomerServiceSession(
        id: widget.sessionId,
        userId: 'user_001',
        agentId: 'cs_001',
        status: SessionStatus.active,
        subject: '账户充值问题',
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        lastMessageTime: DateTime.now().subtract(const Duration(minutes: 5)),
        unreadCount: 0,
      );
      
      final messages = [
        CustomerServiceMessage(
          id: '1',
          sessionId: widget.sessionId,
          senderId: 'user_001',
          senderName: '用户小明',
          content: '你好，我在充值的时候遇到了问题',
          type: 'text',
          createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
          isFromCustomer: true,
        ),
        CustomerServiceMessage(
          id: '2',
          sessionId: widget.sessionId,
          senderId: 'cs_001',
          senderName: '客服小助手',
          content: '您好！我是客服小助手，很高兴为您服务。请问您遇到了什么充值问题呢？',
          type: 'text',
          createdAt: DateTime.now().subtract(const Duration(minutes: 24)),
          isFromCustomer: false,
        ),
        CustomerServiceMessage(
          id: '3',
          sessionId: widget.sessionId,
          senderId: 'user_001',
          senderName: '用户小明',
          content: '我用支付宝充值了100元，但是余额没有到账',
          type: 'text',
          createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
          isFromCustomer: true,
        ),
      ];
      
      final quickReplies = await CustomerService.getQuickReplyTemplates();
      
      setState(() {
        _session = session;
        _messages = messages;
        _quickReplies = quickReplies;
        _isLoading = false;
      });
      
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载聊天数据失败: $e')),
        );
      }
    }
  }

  Future<void> _sendMessage(String content) async {
    if (content.trim().isEmpty || _isSending) return;
    
    setState(() {
      _isSending = true;
    });
    
    try {
      final message = CustomerServiceMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sessionId: widget.sessionId,
        senderId: 'cs_001',
        senderName: '客服小助手',
        content: content,
        type: 'text',
        createdAt: DateTime.now(),
        isFromCustomer: false,
      );
      
      setState(() {
        _messages.add(message);
        _messageController.clear();
        _showQuickReplies = false;
      });
      
      _scrollToBottom();
      
      // 模拟发送到服务器
      await Future.delayed(const Duration(milliseconds: 300));
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发送消息失败: $e')),
        );
      }
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_session?.subject ?? '客服会话'),
            if (_session != null)
              Text(
                '用户ID: ${_session!.userId}',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'close':
                  _closeSession();
                  break;
                case 'transfer':
                  _transferSession();
                  break;
                case 'info':
                  _showUserInfo();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'info',
                child: Row(
                  children: [
                    Icon(Icons.info, size: 20),
                    SizedBox(width: 8),
                    Text('用户信息'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'transfer',
                child: Row(
                  children: [
                    Icon(Icons.transfer_within_a_station, size: 20),
                    SizedBox(width: 8),
                    Text('转接'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'close',
                child: Row(
                  children: [
                    Icon(Icons.close, size: 20),
                    SizedBox(width: 8),
                    Text('关闭会话'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 消息列表
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
                ),
                
                // 快捷回复
                if (_showQuickReplies) _buildQuickReplies(),
                
                // 输入区域
                _buildInputArea(),
              ],
            ),
    );
  }

  Widget _buildMessageBubble(CustomerServiceMessage message) {
    final isFromAgent = message.isFromAgent;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isFromAgent ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isFromAgent) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue[100],
              child: const Icon(Icons.person, size: 16, color: Colors.blue),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isFromAgent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isFromAgent ? Colors.blue[600] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      color: isFromAgent ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatMessageTime(message.createdAt),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          if (isFromAgent) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.green[100],
              child: const Icon(Icons.support_agent, size: 16, color: Colors.green),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickReplies() {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '快捷回复',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _quickReplies.length,
              itemBuilder: (context, index) {
                final reply = _quickReplies[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(
                      reply.title,
                      style: const TextStyle(fontSize: 12),
                    ),
                    onPressed: () {
                      _messageController.text = reply.content;
                      setState(() {
                        _showQuickReplies = false;
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _showQuickReplies ? Icons.keyboard : Icons.quick_contacts_dialer,
              color: Colors.blue[600],
            ),
            onPressed: () {
              setState(() {
                _showQuickReplies = !_showQuickReplies;
              });
            },
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: '输入消息...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (value) {
                _sendMessage(value);
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: _isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.send, color: Colors.blue[600]),
            onPressed: _isSending
                ? null
                : () {
                    _sendMessage(_messageController.text);
                  },
          ),
        ],
      ),
    );
  }

  String _formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (messageDate == today) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.month}/${dateTime.day} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  void _closeSession() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('关闭会话'),
        content: const Text('确定要关闭这个客服会话吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _transferSession() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('转接会话'),
        content: const Text('转接功能正在开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showUserInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('用户信息'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('用户ID: ${_session?.userId}'),
            const SizedBox(height: 8),
            const Text('昵称: 用户小明'),
            const SizedBox(height: 8),
            const Text('注册时间: 2024-01-15'),
            const SizedBox(height: 8),
            const Text('VIP等级: 普通用户'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}