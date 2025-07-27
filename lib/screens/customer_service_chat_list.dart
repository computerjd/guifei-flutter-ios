import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/customer_service.dart';
import '../models/customer_service_models.dart';

class CustomerServiceChatList extends StatefulWidget {
  const CustomerServiceChatList({super.key});

  @override
  State<CustomerServiceChatList> createState() => _CustomerServiceChatListState();
}

class _CustomerServiceChatListState extends State<CustomerServiceChatList> with TickerProviderStateMixin {
  final CustomerService _customerService = CustomerService();
  late TabController _tabController;
  
  List<CustomerServiceSession> _allSessions = [];
  List<CustomerServiceSession> _activeSessions = [];
  List<CustomerServiceSession> _pendingSessions = [];
  List<CustomerServiceSession> _closedSessions = [];
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSessions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 模拟加载会话数据
      await Future.delayed(const Duration(milliseconds: 500));
      
      final mockSessions = [
        CustomerServiceSession(
          id: '1',
          userId: 'user_001',
          agentId: 'cs_001',
          status: SessionStatus.active,
          subject: '账户充值问题',
          createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
          lastMessageTime: DateTime.now().subtract(const Duration(minutes: 5)),
          unreadCount: 2,
        ),
        CustomerServiceSession(
          id: '2',
          userId: 'user_002',
          agentId: 'cs_001',
          status: SessionStatus.pending,
          subject: '直播功能咨询',
          createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
          lastMessageTime: DateTime.now().subtract(const Duration(minutes: 10)),
          unreadCount: 1,
        ),
        CustomerServiceSession(
          id: '3',
          userId: 'user_003',
          agentId: 'cs_001',
          status: SessionStatus.closed,
          subject: '密码重置',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          lastMessageTime: DateTime.now().subtract(const Duration(hours: 1)),
          unreadCount: 0,
        ),
      ];
      
      setState(() {
        _allSessions = mockSessions;
        _activeSessions = mockSessions.where((s) => s.status == SessionStatus.active).toList();
        _pendingSessions = mockSessions.where((s) => s.status == SessionStatus.pending).toList();
        _closedSessions = mockSessions.where((s) => s.status == SessionStatus.closed).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载会话失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('客服会话'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(
              text: '进行中 (${_activeSessions.length})',
              icon: const Icon(Icons.chat_bubble, size: 16),
            ),
            Tab(
              text: '待处理 (${_pendingSessions.length})',
              icon: const Icon(Icons.pending, size: 16),
            ),
            Tab(
              text: '已关闭 (${_closedSessions.length})',
              icon: const Icon(Icons.check_circle, size: 16),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSessions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSessionList(_activeSessions, SessionStatus.active),
                _buildSessionList(_pendingSessions, SessionStatus.pending),
                _buildSessionList(_closedSessions, SessionStatus.closed),
              ],
            ),
    );
  }

  Widget _buildSessionList(List<CustomerServiceSession> sessions, SessionStatus status) {
    if (sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getStatusIcon(status),
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _getEmptyMessage(status),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSessions,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: sessions.length,
        itemBuilder: (context, index) {
          final session = sessions[index];
          return _buildSessionCard(session);
        },
      ),
    );
  }

  Widget _buildSessionCard(CustomerServiceSession session) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 2,
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: _getStatusColor(session.status),
              child: Icon(
                _getStatusIcon(session.status),
                color: Colors.white,
                size: 20,
              ),
            ),
            if (session.unreadCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    session.unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          session.subject ?? '客服咨询',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '用户ID: ${session.userId}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '最后活动: ${_formatTime(session.lastMessageTime)}',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 11,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(session.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getStatusColor(session.status),
                  width: 1,
                ),
              ),
              child: Text(
                _getStatusText(session.status),
                style: TextStyle(
                  color: _getStatusColor(session.status),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        onTap: () {
          context.push('/chat/${session.id}');
        },
      ),
    );
  }

  IconData _getStatusIcon(SessionStatus status) {
    switch (status) {
      case SessionStatus.active:
        return Icons.chat_bubble;
      case SessionStatus.pending:
        return Icons.pending;
      case SessionStatus.closed:
        return Icons.check_circle;
    }
  }

  Color _getStatusColor(SessionStatus status) {
    switch (status) {
      case SessionStatus.active:
        return Colors.green;
      case SessionStatus.pending:
        return Colors.orange;
      case SessionStatus.closed:
        return Colors.grey;
    }
  }

  String _getStatusText(SessionStatus status) {
    switch (status) {
      case SessionStatus.active:
        return '进行中';
      case SessionStatus.pending:
        return '待处理';
      case SessionStatus.closed:
        return '已关闭';
    }
  }

  String _getEmptyMessage(SessionStatus status) {
    switch (status) {
      case SessionStatus.active:
        return '暂无进行中的会话';
      case SessionStatus.pending:
        return '暂无待处理的会话';
      case SessionStatus.closed:
        return '暂无已关闭的会话';
    }
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '未知';
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else {
      return '${difference.inDays}天前';
    }
  }
}