import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

class FanManagementScreen extends ConsumerStatefulWidget {
  const FanManagementScreen({super.key});

  @override
  ConsumerState<FanManagementScreen> createState() => _FanManagementScreenState();
}

class _FanManagementScreenState extends ConsumerState<FanManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedFilter = 'all';
  
  List<Map<String, dynamic>> _allFans = [];
  List<Map<String, dynamic>> _filteredFans = [];
  List<Map<String, dynamic>> _vipFans = [];
  List<Map<String, dynamic>> _newFans = [];
  List<Map<String, dynamic>> _blacklist = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadFansData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFansData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 获取粉丝数据
      final fansResponse = await _apiService.getFansList();
      final vipResponse = await _apiService.getVipFans();
      final blacklistResponse = await _apiService.getBlacklist();
      
      setState(() {
        _allFans = fansResponse['fans'] ?? [];
        _vipFans = vipResponse['vipFans'] ?? [];
        _blacklist = blacklistResponse['blacklist'] ?? [];
        
        // 筛选新粉丝（7天内关注的）
        _newFans = _allFans.where((fan) {
          final followTime = DateTime.tryParse(fan['followTime'] ?? '') ?? DateTime.now();
          return DateTime.now().difference(followTime).inDays <= 7;
        }).toList();
        
        _filterFans();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载粉丝数据失败: ${e.toString()}')),
        );
      }
    }
  }



  void _filterFans() {
    List<Map<String, dynamic>> fans = [];
    
    switch (_selectedFilter) {
      case 'all':
        fans = _allFans;
        break;
      case 'vip':
        fans = _vipFans;
        break;
      case 'online':
        fans = _allFans.where((fan) => fan['isOnline']).toList();
        break;
      case 'active':
        fans = _allFans.where((fan) {
          final lastActive = fan['lastActiveTime'] as DateTime;
          return DateTime.now().difference(lastActive).inHours <= 24;
        }).toList();
        break;
    }
    
    if (_searchQuery.isNotEmpty) {
      fans = fans.where((fan) {
        return fan['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
               fan['location'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    setState(() {
      _filteredFans = fans;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('粉丝管理'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: '全部粉丝'),
            Tab(icon: Icon(Icons.star), text: 'VIP粉丝'),
            Tab(icon: Icon(Icons.person_add), text: '新粉丝'),
            Tab(icon: Icon(Icons.block), text: '黑名单'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFansData,
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              _showFansAnalytics();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAllFansTab(),
                _buildVipFansTab(),
                _buildNewFansTab(),
                _buildBlacklistTab(),
              ],
            ),
    );
  }

  Widget _buildAllFansTab() {
    return Column(
      children: [
        // 搜索和筛选
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: '搜索粉丝名称或地区',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                  _filterFans();
                },
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('全部', 'all'),
                    _buildFilterChip('VIP', 'vip'),
                    _buildFilterChip('在线', 'online'),
                    _buildFilterChip('活跃', 'active'),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // 统计信息
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('总粉丝', '${_allFans.length}', Colors.blue),
              _buildStatItem('在线', '${_allFans.where((f) => f['isOnline']).length}', Colors.green),
              _buildStatItem('VIP', '${_vipFans.length}', Colors.orange),
              _buildStatItem('新粉丝', '${_newFans.length}', Colors.purple),
            ],
          ),
        ),
        
        // 粉丝列表
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filteredFans.length,
            itemBuilder: (context, index) {
              final fan = _filteredFans[index];
              return _buildFanCard(fan);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVipFansTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _vipFans.length,
      itemBuilder: (context, index) {
        final fan = _vipFans[index];
        return _buildVipFanCard(fan);
      },
    );
  }

  Widget _buildNewFansTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _newFans.length,
      itemBuilder: (context, index) {
        final fan = _newFans[index];
        return _buildNewFanCard(fan);
      },
    );
  }

  Widget _buildBlacklistTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _blacklist.length,
      itemBuilder: (context, index) {
        final user = _blacklist[index];
        return _buildBlacklistCard(user);
      },
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: _selectedFilter == value,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = value;
          });
          _filterFans();
        },
      ),
    );
  }

  Widget _buildStatItem(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
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
    );
  }

  Widget _buildFanCard(Map<String, dynamic> fan) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(fan['avatar']),
            ),
            if (fan['isOnline'])
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Text(
              fan['name'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            if (fan['isVip'])
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'VIP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Lv.${fan['level']}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${fan['location']} · ${fan['age']}岁 · ${fan['gender']}'),
            Text('贡献: ¥${fan['totalGifts']} · 消息: ${fan['messageCount']}'),
            if (fan['tags'].isNotEmpty)
              Wrap(
                spacing: 4,
                children: (fan['tags'] as List<String>).map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'message',
              child: Row(
                children: [
                  Icon(Icons.message),
                  SizedBox(width: 8),
                  Text('发送私信'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'gift',
              child: Row(
                children: [
                  Icon(Icons.card_giftcard),
                  SizedBox(width: 8),
                  Text('赠送礼物'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'vip',
              child: Row(
                children: [
                  Icon(Icons.star),
                  SizedBox(width: 8),
                  Text('设为VIP'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'block',
              child: Row(
                children: [
                  Icon(Icons.block, color: Colors.red),
                  SizedBox(width: 8),
                  Text('拉黑', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            _handleFanAction(fan, value.toString());
          },
        ),
        onTap: () {
          _showFanDetails(fan);
        },
      ),
    );
  }

  Widget _buildVipFanCard(Map<String, dynamic> fan) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [Colors.orange.withOpacity(0.1), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListTile(
          leading: Stack(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(fan['avatar']),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.star,
                    color: Colors.white,
                    size: 10,
                  ),
                ),
              ),
            ],
          ),
          title: Text(
            fan['name'],
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('VIP等级: Lv.${fan['level']}'),
              Text('总贡献: ¥${fan['totalGifts']}'),
              Text('最爱礼物: ${fan['favoriteGift']}'),
            ],
          ),
          trailing: ElevatedButton(
            onPressed: () {
              _showVipManagement(fan);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('管理'),
          ),
        ),
      ),
    );
  }

  Widget _buildNewFanCard(Map<String, dynamic> fan) {
    final followDays = DateTime.now().difference(fan['followTime'] as DateTime).inDays;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [Colors.green.withOpacity(0.1), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListTile(
          leading: Stack(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(fan['avatar']),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    'N',
                    style: TextStyle(
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
            fan['name'],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('关注了 $followDays 天'),
              Text('等级: Lv.${fan['level']}'),
              Text('贡献: ¥${fan['totalGifts']}'),
            ],
          ),
          trailing: ElevatedButton(
            onPressed: () {
              _sendWelcomeMessage(fan);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('欢迎'),
          ),
        ),
      ),
    );
  }

  Widget _buildBlacklistCard(Map<String, dynamic> user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(user['avatar']),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.block,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        title: Text(
          user['name'],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('拉黑原因: ${user['blockReason']}'),
            Text('拉黑时间: ${_formatDate(user['blockTime'])}'),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () {
            _showUnblockDialog(user);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text('解封'),
        ),
      ),
    );
  }

  void _handleFanAction(Map<String, dynamic> fan, String action) {
    switch (action) {
      case 'message':
        _sendPrivateMessage(fan);
        break;
      case 'gift':
        _sendGift(fan);
        break;
      case 'vip':
        _setVip(fan);
        break;
      case 'block':
        _blockFan(fan);
        break;
    }
  }

  void _showFanDetails(Map<String, dynamic> fan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${fan['name']} 详情'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(fan['avatar']),
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow('等级', 'Lv.${fan['level']}'),
              _buildDetailRow('地区', fan['location']),
              _buildDetailRow('年龄', '${fan['age']}岁'),
              _buildDetailRow('性别', fan['gender']),
              _buildDetailRow('关注时间', _formatDate(fan['followTime'])),
              _buildDetailRow('最后活跃', _formatTime(fan['lastActiveTime'])),
              _buildDetailRow('总贡献', '¥${fan['totalGifts']}'),
              _buildDetailRow('消息数', '${fan['messageCount']}'),
              _buildDetailRow('最爱礼物', fan['favoriteGift']),
              if (fan['tags'].isNotEmpty)
                _buildDetailRow('标签', (fan['tags'] as List<String>).join(', ')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sendPrivateMessage(fan);
            },
            child: const Text('发送私信'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _sendPrivateMessage(Map<String, dynamic> fan) {
    showDialog(
      context: context,
      builder: (context) {
        final messageController = TextEditingController();
        return AlertDialog(
          title: Text('发送私信给 ${fan['name']}'),
          content: TextField(
            controller: messageController,
            decoration: const InputDecoration(
              hintText: '输入消息内容',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('已发送私信给 ${fan['name']}')),
                );
              },
              child: const Text('发送'),
            ),
          ],
        );
      },
    );
  }

  void _sendGift(Map<String, dynamic> fan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('赠送礼物给 ${fan['name']}'),
        content: const Text('选择要赠送的礼物'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('已赠送礼物给 ${fan['name']}')),
              );
            },
            child: const Text('赠送'),
          ),
        ],
      ),
    );
  }

  void _setVip(Map<String, dynamic> fan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('设置 ${fan['name']} 为VIP'),
        content: const Text('确定要将此粉丝设为VIP吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                fan['isVip'] = true;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${fan['name']} 已设为VIP')),
              );
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _blockFan(Map<String, dynamic> fan) {
    showDialog(
      context: context,
      builder: (context) {
        String reason = '违规行为';
        return AlertDialog(
          title: Text('拉黑 ${fan['name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('请选择拉黑原因:'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: reason,
                items: ['恶意刷屏', '不当言论', '骚扰主播', '违规行为', '其他']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (value) {
                  reason = value!;
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _blacklist.add({
                    'id': fan['id'],
                    'name': fan['name'],
                    'avatar': fan['avatar'],
                    'blockTime': DateTime.now(),
                    'blockReason': reason,
                    'isBlocked': true,
                  });
                  _allFans.removeWhere((f) => f['id'] == fan['id']);
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${fan['name']} 已被拉黑')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('拉黑'),
            ),
          ],
        );
      },
    );
  }

  void _showVipManagement(Map<String, dynamic> fan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('VIP管理 - ${fan['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('VIP特权设置'),
              onTap: () {
                Navigator.pop(context);
                // TODO: VIP特权设置
              },
            ),
            ListTile(
              leading: const Icon(Icons.card_giftcard),
              title: const Text('专属礼物'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 专属礼物
              },
            ),
            ListTile(
              leading: const Icon(Icons.message),
              title: const Text('专属消息'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 专属消息
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _sendWelcomeMessage(Map<String, dynamic> fan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已发送欢迎消息给 ${fan['name']}')),
    );
  }

  void _showUnblockDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('解封 ${user['name']}'),
        content: const Text('确定要解除对此用户的拉黑吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _blacklist.removeWhere((u) => u['id'] == user['id']);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${user['name']} 已解封')),
              );
            },
            child: const Text('解封'),
          ),
        ],
      ),
    );
  }

  void _showFansAnalytics() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('粉丝分析'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAnalyticsItem('总粉丝数', '${_allFans.length}'),
              _buildAnalyticsItem('VIP粉丝', '${_vipFans.length}'),
              _buildAnalyticsItem('新粉丝(7天)', '${_newFans.length}'),
              _buildAnalyticsItem('在线粉丝', '${_allFans.where((f) => f['isOnline']).length}'),
              _buildAnalyticsItem('活跃粉丝(24h)', '${_allFans.where((f) => DateTime.now().difference(f['lastActiveTime']).inHours <= 24).length}'),
              _buildAnalyticsItem('平均等级', '${(_allFans.fold<double>(0.0, (sum, f) => sum + f['level']) / _allFans.length).toStringAsFixed(1)}'),
              _buildAnalyticsItem('总贡献', '¥${_allFans.fold<double>(0.0, (sum, f) => sum + f['totalGifts']).toStringAsFixed(2)}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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
}