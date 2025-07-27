import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/live_provider.dart';
import '../services/api_service.dart';
import '../models/live_session_model.dart';

class LiveManagementScreen extends ConsumerStatefulWidget {
  const LiveManagementScreen({super.key});

  @override
  ConsumerState<LiveManagementScreen> createState() => _LiveManagementScreenState();
}

class _LiveManagementScreenState extends ConsumerState<LiveManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  List<Map<String, dynamic>> _viewers = [];
  Map<String, dynamic> _liveStats = {};
  List<Map<String, dynamic>> _recentComments = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadManagementData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadManagementData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 从API获取直播管理数据
      final viewersResponse = await _apiService.getLiveViewers();
      final statsResponse = await _apiService.getLiveStats('default_room');
      final commentsResponse = await _apiService.getLiveComments();
      
      setState(() {
        _viewers = List<Map<String, dynamic>>.from(
          viewersResponse['data'] ?? []
        );
        _liveStats = statsResponse['data'] ?? {};
        _recentComments = List<Map<String, dynamic>>.from(
          commentsResponse['data'] ?? []
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载直播数据失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('直播管理'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: '概览'),
            Tab(icon: Icon(Icons.people), text: '观众'),
            Tab(icon: Icon(Icons.chat), text: '评论'),
            Tab(icon: Icon(Icons.settings), text: '设置'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadManagementData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildViewersTab(),
                _buildCommentsTab(),
                _buildSettingsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 实时数据卡片
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '当前观众',
                  '${_liveStats['currentViewers']}',
                  Icons.people,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  '总观众',
                  '${_liveStats['totalViewers']}',
                  Icons.visibility,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '点赞数',
                  '${_liveStats['likes']}',
                  Icons.favorite,
                  Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  '收益',
                  '¥${_liveStats['revenue']}',
                  Icons.monetization_on,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // 直播时长
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.purple),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '直播时长',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatDuration(_liveStats['duration']),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // 互动数据
          const Text(
            '互动数据',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInteractionRow('评论', _liveStats['comments'], Icons.chat),
                  const Divider(),
                  _buildInteractionRow('分享', _liveStats['shares'], Icons.share),
                  const Divider(),
                  _buildInteractionRow('礼物', _liveStats['gifts'], Icons.card_giftcard),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewersTab() {
    return Column(
      children: [
        // 观众统计
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    '${_viewers.length}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text('当前观众'),
                ],
              ),
              Column(
                children: [
                  Text(
                    '${_viewers.where((v) => v['isVip']).length}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const Text('VIP观众'),
                ],
              ),
              Column(
                children: [
                  Text(
                    '${_viewers.where((v) => v['isMuted']).length}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const Text('已禁言'),
                ],
              ),
            ],
          ),
        ),
        
        // 观众列表
        Expanded(
          child: ListView.builder(
            itemCount: _viewers.length,
            itemBuilder: (context, index) {
              final viewer = _viewers[index];
              return ListTile(
                leading: Stack(
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(viewer['avatar']),
                    ),
                    if (viewer['isVip'])
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.star,
                            size: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                title: Row(
                  children: [
                    Text(viewer['name']),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Lv.${viewer['level']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  '进入时间: ${_formatTime(viewer['joinTime'])}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'mute',
                      child: Row(
                        children: [
                          Icon(
                            viewer['isMuted'] ? Icons.volume_up : Icons.volume_off,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(viewer['isMuted'] ? '取消禁言' : '禁言'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'kick',
                      child: Row(
                        children: [
                          Icon(Icons.exit_to_app, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('踢出直播间', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    _handleViewerAction(viewer, value.toString());
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCommentsTab() {
    return Column(
      children: [
        // 评论统计
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    '${_recentComments.length}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text('总评论'),
                ],
              ),
              Column(
                children: [
                  Text(
                    '${_recentComments.where((c) => c['isReported']).length}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const Text('被举报'),
                ],
              ),
            ],
          ),
        ),
        
        // 评论列表
        Expanded(
          child: ListView.builder(
            itemCount: _recentComments.length,
            itemBuilder: (context, index) {
              final comment = _recentComments[index];
              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(comment['userName'][0]),
                  ),
                  title: Text(comment['userName']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(comment['content']),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(comment['timestamp']),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (comment['isReported'])
                        const Icon(
                          Icons.report,
                          color: Colors.red,
                          size: 16,
                        ),
                      PopupMenuButton(
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 16, color: Colors.red),
                                SizedBox(width: 8),
                                Text('删除评论', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'report',
                            child: Row(
                              children: [
                                Icon(Icons.report, size: 16),
                                SizedBox(width: 8),
                                Text('举报'),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          _handleCommentAction(comment, value.toString());
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          '直播间设置',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.title),
                title: const Text('直播间标题'),
                subtitle: const Text('我的精彩直播'),
                trailing: const Icon(Icons.edit),
                onTap: () {
                  _showEditDialog('标题', '我的精彩直播');
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('直播间描述'),
                subtitle: const Text('欢迎来到我的直播间'),
                trailing: const Icon(Icons.edit),
                onTap: () {
                  _showEditDialog('描述', '欢迎来到我的直播间');
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('直播间封面'),
                subtitle: const Text('点击更换封面'),
                trailing: const Icon(Icons.photo_camera),
                onTap: () {
                  _showCoverOptions();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        const Text(
          '互动设置',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        Card(
          child: Column(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.chat),
                title: const Text('允许评论'),
                subtitle: const Text('观众可以发送评论'),
                value: true,
                onChanged: (value) {
                  // TODO: 实现评论开关
                },
              ),
              const Divider(),
              SwitchListTile(
                secondary: const Icon(Icons.card_giftcard),
                title: const Text('允许送礼'),
                subtitle: const Text('观众可以送礼物'),
                value: true,
                onChanged: (value) {
                  // TODO: 实现送礼开关
                },
              ),
              const Divider(),
              SwitchListTile(
                secondary: const Icon(Icons.share),
                title: const Text('允许分享'),
                subtitle: const Text('观众可以分享直播间'),
                value: true,
                onChanged: (value) {
                  // TODO: 实现分享开关
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        const Text(
          '管理工具',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.block, color: Colors.red),
                title: const Text('黑名单管理'),
                subtitle: const Text('管理被拉黑的用户'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: 打开黑名单管理页面
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.volume_off, color: Colors.orange),
                title: const Text('禁言列表'),
                subtitle: const Text('管理被禁言的用户'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: 打开禁言列表页面
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.report, color: Colors.purple),
                title: const Text('举报处理'),
                subtitle: const Text('处理用户举报'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: 打开举报处理页面
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractionRow(String title, int value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else {
      return '${time.month}/${time.day} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  void _handleViewerAction(Map<String, dynamic> viewer, String action) {
    switch (action) {
      case 'mute':
        setState(() {
          viewer['isMuted'] = !viewer['isMuted'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              viewer['isMuted'] ? '已禁言 ${viewer['name']}' : '已取消禁言 ${viewer['name']}',
            ),
          ),
        );
        break;
      case 'kick':
        setState(() {
          _viewers.remove(viewer);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已踢出 ${viewer['name']}'),
          ),
        );
        break;
    }
  }

  void _handleCommentAction(Map<String, dynamic> comment, String action) {
    switch (action) {
      case 'delete':
        setState(() {
          _recentComments.remove(comment);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('评论已删除'),
          ),
        );
        break;
      case 'report':
        setState(() {
          comment['isReported'] = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('评论已举报'),
          ),
        );
        break;
    }
  }

  void _showEditDialog(String field, String currentValue) {
    final controller = TextEditingController(text: currentValue);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('编辑$field'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: field,
            border: const OutlineInputBorder(),
          ),
          maxLines: field == '描述' ? 3 : 1,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: 保存修改
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$field已更新')),
              );
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showCoverOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('拍照'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 实现拍照功能
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('从相册选择'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 实现相册选择功能
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('取消'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}