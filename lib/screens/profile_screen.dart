import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/app_models.dart';
import '../services/auth_service.dart';
import 'customer_service_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  FullUserInfo? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = AuthService.currentUser;
      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // 如果获取用户信息失败，可能是未登录，跳转到登录页
        context.go('/login');
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认登出'),
        content: const Text('您确定要登出吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确认'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      AuthService.logout();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '请先登录',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/login'),
                child: const Text('去登录'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 用户信息头部
            _buildUserHeader(),
            const SizedBox(height: 20),
            // 功能菜单
            _buildMenuSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // 头像和基本信息
              Row(
                children: [
                  // 头像
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: _user!.user.avatar != null && _user!.user.avatar!.isNotEmpty 
                            ? NetworkImage(_user!.user.avatar!) 
                            : null,
                        backgroundColor: Colors.grey[300],
                        child: _user!.user.avatar == null || _user!.user.avatar!.isEmpty
                            ? const Icon(Icons.person, size: 40)
                            : null,
                      ),
                      // VIP标识
                      if (_user!.user.userType == UserType.consumer) // 简化VIP权限检查
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.amber,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.diamond,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      // 用户类型标识
                      if (_user!.user.userType == UserType.anchor)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.videocam,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  // 用户信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _user!.user.username,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // 用户类型标签
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getUserTypeColor(_user!.user.userType),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _getUserTypeText(_user!.user.userType),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // 消费等级标签
                            if (_user!.user.userType == UserType.consumer) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'VIP用户', // 简化消费等级显示
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '未设置邮箱', // User模型中没有email字段
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                        if (_user!.user.phone != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            _user!.user.phone!,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // 编辑按钮
                  IconButton(
                    onPressed: () {
                      _showEditProfileDialog();
                    },
                    icon: const Icon(
                      Icons.edit,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // 余额信息（仅消费者用户显示）
              if (_user!.user.userType == UserType.consumer)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '账户余额',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '¥0.00', // User模型中没有balance字段
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _showRechargeDialog();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Theme.of(context).colorScheme.primary,
                        ),
                        child: const Text('充值'),
                      ),
                    ],
                  ),
                ),
              // 统计信息
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      '关注',
                      '0', // 关注数暂未实现
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      '粉丝',
                      '0', // 粉丝数暂未实现
                    ),
                  ),
                  if (_user!.user.userType == UserType.anchor)
                    Expanded(
                      child: _buildStatItem(
                        '获赞',
                        '0', // 获赞数暂未实现
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Color _getUserTypeColor(UserType userType) {
    switch (userType) {
      case UserType.admin:
        return Colors.red;
      case UserType.service:
        return Colors.orange;
      case UserType.anchor:
        return Colors.purple;
      case UserType.consumer:
        return Colors.blue;
      // case UserType.viewer:
      //   return Colors.grey;
    }
  }

  String _getUserTypeText(UserType userType) {
    switch (userType) {
      case UserType.admin:
        return '管理员';
      case UserType.service:
        return '客服';
      case UserType.anchor:
        return '主播';
      case UserType.consumer:
        return '用户';
      // case UserType.viewer:
      //   return '观众';
    }
  }

  Widget _buildMenuSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // 账户管理
          _buildMenuGroup(
            '账户管理',
            [
              _buildMenuItem(
                Icons.person_outline,
                '个人信息',
                '编辑个人资料',
                () => _showEditProfileDialog(),
              ),
              if (_user!.user.userType == UserType.consumer)
                _buildMenuItem(
                  Icons.account_balance_wallet,
                  '余额管理',
                  '充值和提现',
                  () => _showBalanceDialog(),
                ),
              _buildMenuItem(
                Icons.security,
                '账户安全',
                '密码和安全设置',
                () => _showSecurityDialog(),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 社交功能
          _buildMenuGroup(
            '社交功能',
            [
              _buildMenuItem(
                Icons.favorite_outline,
                '我的关注',
                '查看关注的用户',
                () => _showFollowingList(),
              ),
              _buildMenuItem(
                Icons.people_outline,
                '我的粉丝',
                '查看粉丝列表',
                () => _showFollowersList(),
              ),
              if (_user!.user.userType == UserType.anchor)
                _buildMenuItem(
                  Icons.live_tv,
                  '直播管理',
                  '直播间设置和数据',
                  () => _showLiveManagement(),
                ),
            ],
          ),
          const SizedBox(height: 20),
          // 应用设置
          _buildMenuGroup(
            '应用设置',
            [
              _buildMenuItem(
                Icons.settings,
                '通用设置',
                '应用设置和偏好',
                () => context.push('/settings'),
              ),
              _buildMenuItem(
                Icons.privacy_tip,
                '隐私设置',
                '隐私和权限管理',
                () => _showPrivacySettings(),
              ),
              _buildMenuItem(
                Icons.notifications_outlined,
                '通知设置',
                '推送通知管理',
                () => _showNotificationSettings(),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 帮助支持
          _buildMenuGroup(
            '帮助支持',
            [
              _buildMenuItem(
                Icons.help_outline,
                '帮助中心',
                '常见问题和帮助',
                () => _showHelpCenter(),
              ),
              _buildMenuItem(
                Icons.support_agent,
                '客服中心',
                '联系客服获取帮助',
                () => _showCustomerService(),
              ),
              _buildMenuItem(
                Icons.info_outline,
                '关于我们',
                '应用信息和版本',
                () => _showAboutDialog(),
              ),
            ],
          ),
          const SizedBox(height: 40),
          // 退出登录
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _showLogoutDialog,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('退出登录'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMenuGroup(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(
        icon,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑个人信息'),
        content: const Text('个人信息编辑功能正在开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showRechargeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('充值'),
        content: const Text('充值功能正在开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showBalanceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('余额管理'),
        content: const Text('余额管理功能正在开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showSecurityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('账户安全'),
        content: const Text('账户安全设置功能正在开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showFollowingList() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('我的关注'),
        content: const Text('关注列表功能正在开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showFollowersList() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('我的粉丝'),
        content: const Text('粉丝列表功能正在开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showLiveManagement() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('直播管理'),
        content: const Text('直播管理功能正在开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showPrivacySettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('隐私设置'),
        content: const Text('隐私设置功能正在开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('通知设置'),
        content: const Text('通知设置功能正在开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showHelpCenter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('帮助中心'),
        content: const Text('帮助中心功能正在开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showCustomerService() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CustomerServiceScreen(),
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: '贵妃',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.play_circle_filled,
        size: 48,
      ),
      children: [
        const Text('一个功能丰富的多媒体应用'),
        const SizedBox(height: 8),
        const Text('包含视频、直播、游戏等多种娱乐功能'),
      ],
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handleLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('退出'),
          ),
        ],
      ),
    );
  }
}