import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeNotifier = ref.watch(themeProvider.notifier);
    final currentTheme = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.pop();
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 主题设置
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '主题设置',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: themeColors.map((themeColor) {
                      final isSelected = currentTheme.name == themeColor.name;
                      return GestureDetector(
                        onTap: () {
                          themeNotifier.changeTheme(themeColor);
                        },
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: themeColor.color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: themeColor.color.withOpacity(0.5),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 24,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // 直播设置
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.videocam),
                  title: const Text('直播画质'),
                  subtitle: const Text('高清'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showQualityDialog(context);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.face_retouching_natural),
                  title: const Text('美颜设置'),
                  subtitle: const Text('调整美颜参数'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showBeautyDialog(context);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.mic),
                  title: const Text('音频设置'),
                  subtitle: const Text('麦克风和音质设置'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showAudioDialog(context);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // 通知设置
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications),
                  title: const Text('推送通知'),
                  subtitle: const Text('接收粉丝互动通知'),
                  value: true,
                  onChanged: (value) {
                    // TODO: 实现通知设置
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.vibration),
                  title: const Text('震动反馈'),
                  subtitle: const Text('收到礼物时震动提醒'),
                  value: true,
                  onChanged: (value) {
                    // TODO: 实现震动设置
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // 隐私设置
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.privacy_tip),
                  title: const Text('隐私政策'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: 显示隐私政策
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.security),
                  title: const Text('账号安全'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showAudioDialog(context);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // 关于
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('关于贵妃直播'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showAboutDialog(context);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.help),
                  title: const Text('帮助与反馈'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showVibrationDialog(context);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.update),
                  title: const Text('检查更新'),
                  subtitle: const Text('当前版本 v1.0.0'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showNotificationDialog(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAudioDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('音频设置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('音质'),
              subtitle: const Text('高质量'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                _showQualitySelector(context, '音质');
              },
            ),
            ListTile(
              title: const Text('降噪'),
              subtitle: const Text('开启'),
              trailing: Switch(
                value: true,
                onChanged: (value) {},
                activeColor: Colors.pink,
              ),
            ),
            ListTile(
              title: const Text('回音消除'),
              subtitle: const Text('开启'),
              trailing: Switch(
                value: true,
                onChanged: (value) {},
                activeColor: Colors.pink,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showNotificationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('通知设置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('推送通知'),
              subtitle: const Text('接收直播相关通知'),
              trailing: Switch(
                value: true,
                onChanged: (value) {},
                activeColor: Colors.pink,
              ),
            ),
            ListTile(
              title: const Text('声音提醒'),
              subtitle: const Text('新消息声音提醒'),
              trailing: Switch(
                value: true,
                onChanged: (value) {},
                activeColor: Colors.pink,
              ),
            ),
            ListTile(
              title: const Text('免打扰时间'),
              subtitle: const Text('22:00 - 08:00'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('免打扰时间设置功能开发中')),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showVibrationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('震动设置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('震动反馈'),
              subtitle: const Text('触摸时震动'),
              trailing: Switch(
                value: true,
                onChanged: (value) {},
                activeColor: Colors.pink,
              ),
            ),
            ListTile(
              title: const Text('消息震动'),
              subtitle: const Text('收到消息时震动'),
              trailing: Switch(
                value: true,
                onChanged: (value) {},
                activeColor: Colors.pink,
              ),
            ),
            ListTile(
              title: const Text('震动强度'),
              subtitle: const Text('中等'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                _showVibrationIntensity(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showQualitySelector(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('选择$title'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('标准'),
              value: '标准',
              groupValue: '高质量',
              onChanged: (value) => Navigator.pop(context),
            ),
            RadioListTile<String>(
              title: const Text('高质量'),
              value: '高质量',
              groupValue: '高质量',
              onChanged: (value) => Navigator.pop(context),
            ),
            RadioListTile<String>(
              title: const Text('无损'),
              value: '无损',
              groupValue: '高质量',
              onChanged: (value) => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showVibrationIntensity(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('震动强度'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('轻微'),
              value: '轻微',
              groupValue: '中等',
              onChanged: (value) => Navigator.pop(context),
            ),
            RadioListTile<String>(
              title: const Text('中等'),
              value: '中等',
              groupValue: '中等',
              onChanged: (value) => Navigator.pop(context),
            ),
            RadioListTile<String>(
              title: const Text('强烈'),
              value: '强烈',
              groupValue: '中等',
              onChanged: (value) => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: '贵妃直播',
      applicationVersion: 'v1.0.0',
      applicationIcon: const Icon(
        Icons.live_tv,
        size: 64,
        color: Colors.pink,
      ),
      children: [
        const Text('贵妃直播是一款专业的主播端直播应用，为主播提供高质量的直播体验。'),
        const SizedBox(height: 16),
        const Text('© 2024 贵妃团队. 保留所有权利。'),
      ],
    );
  }

  void _showQualityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择直播画质'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('标清 (480p)'),
              value: '480p',
              groupValue: '1080p',
              onChanged: (value) {
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('高清 (720p)'),
              value: '720p',
              groupValue: '1080p',
              onChanged: (value) {
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('超清 (1080p)'),
              value: '1080p',
              groupValue: '1080p',
              onChanged: (value) {
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  void _showBeautyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('美颜设置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('磨皮'),
            Slider(
              value: 0.5,
              onChanged: (value) {
                // TODO: 实现磨皮调节
              },
            ),
            const Text('美白'),
            Slider(
              value: 0.3,
              onChanged: (value) {
                // TODO: 实现美白调节
              },
            ),
            const Text('瘦脸'),
            Slider(
              value: 0.2,
              onChanged: (value) {
                // TODO: 实现瘦脸调节
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}