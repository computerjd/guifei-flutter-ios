import 'package:flutter/material.dart';
import '../services/customer_service.dart';
import '../models/customer_service_models.dart';

class CustomerServiceDashboard extends StatefulWidget {
  const CustomerServiceDashboard({super.key});

  @override
  State<CustomerServiceDashboard> createState() => _CustomerServiceDashboardState();
}

class _CustomerServiceDashboardState extends State<CustomerServiceDashboard> {
  final CustomerService _customerService = CustomerService();
  bool _isOnline = true;
  int _todayChats = 0;
  int _pendingChats = 0;
  int _resolvedChats = 0;
  double _avgResponseTime = 0.0;
  List<CustomerServiceSession> _recentSessions = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    // 模拟加载工作台数据
    setState(() {
      _todayChats = 15;
      _pendingChats = 3;
      _resolvedChats = 12;
      _avgResponseTime = 2.5;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('客服工作台'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          Switch(
            value: _isOnline,
            onChanged: (value) {
              setState(() {
                _isOnline = value;
              });
            },
            activeColor: Colors.green,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                _isOnline ? '在线' : '离线',
                style: TextStyle(
                  color: _isOnline ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 状态卡片
              _buildStatusCard(),
              const SizedBox(height: 20),
              
              // 统计数据
              _buildStatsGrid(),
              const SizedBox(height: 20),
              
              // 今日工作概览
              _buildTodayOverview(),
              const SizedBox(height: 20),
              
              // 快捷操作
              _buildQuickActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: _isOnline 
                ? [Colors.green[400]!, Colors.green[600]!]
                : [Colors.grey[400]!, Colors.grey[600]!],
          ),
        ),
        child: Column(
          children: [
            Icon(
              _isOnline ? Icons.online_prediction : Icons.offline_bolt,
              size: 48,
              color: Colors.white,
            ),
            const SizedBox(height: 12),
            Text(
              _isOnline ? '当前在线服务中' : '当前离线状态',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isOnline ? '准备接收新的客户咨询' : '点击上方开关上线',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatCard(
          title: '今日接待',
          value: _todayChats.toString(),
          icon: Icons.chat,
          color: Colors.blue,
        ),
        _buildStatCard(
          title: '待处理',
          value: _pendingChats.toString(),
          icon: Icons.pending,
          color: Colors.orange,
        ),
        _buildStatCard(
          title: '已解决',
          value: _resolvedChats.toString(),
          icon: Icons.check_circle,
          color: Colors.green,
        ),
        _buildStatCard(
          title: '平均响应',
          value: '${_avgResponseTime}分钟',
          icon: Icons.timer,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayOverview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '今日工作概览',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildOverviewItem(
              icon: Icons.access_time,
              title: '上线时间',
              value: '09:00 - 18:00',
              color: Colors.blue,
            ),
            _buildOverviewItem(
              icon: Icons.trending_up,
              title: '服务效率',
              value: '95%',
              color: Colors.green,
            ),
            _buildOverviewItem(
              icon: Icons.star,
              title: '客户满意度',
              value: '4.8/5.0',
              color: Colors.amber,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '快捷操作',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickActionButton(
                  icon: Icons.refresh,
                  label: '刷新数据',
                  onTap: _loadDashboardData,
                ),
                _buildQuickActionButton(
                  icon: Icons.settings,
                  label: '设置',
                  onTap: () {
                    // TODO: 打开设置页面
                  },
                ),
                _buildQuickActionButton(
                  icon: Icons.help,
                  label: '帮助',
                  onTap: () {
                    // TODO: 打开帮助页面
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          children: [
            Icon(icon, size: 24, color: Colors.blue[600]),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}