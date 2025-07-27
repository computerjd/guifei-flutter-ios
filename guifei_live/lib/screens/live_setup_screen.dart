import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/live_provider.dart';
import '../services/shared_api_service.dart';
import '../models/shared_models.dart';

class LiveSetupScreen extends ConsumerStatefulWidget {
  const LiveSetupScreen({super.key});

  @override
  ConsumerState<LiveSetupScreen> createState() => _LiveSetupScreenState();
}

class _LiveSetupScreenState extends ConsumerState<LiveSetupScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  final List<String> _selectedTags = [];
  final List<String> _availableTags = [
    '聊天', '唱歌', '跳舞', '美妆', '游戏', '美食', '旅行', '学习', '健身', '音乐',
    '绘画', '手工', '宠物', '时尚', '搞笑', '情感', '生活', '科技', '读书', '电影'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _startLiveStream() async {
    if (_formKey.currentState!.validate()) {
      try {
        // 显示加载状态
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
        
        // 使用共享API服务创建直播间
        final liveRoom = await SharedApiService.createLiveRoom(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          tags: _selectedTags,
          streamerId: 'streamer_123', // 应该从用户Provider获取
        );
        
        if (liveRoom != null) {
          final liveNotifier = ref.read(currentLiveSessionProvider.notifier);
          
          liveNotifier.startLiveSession(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            tags: _selectedTags,
          );
          
          // 关闭加载对话框
          Navigator.of(context).pop();
          
          // 跳转到直播页面
          context.pushReplacement('/live-stream');
        } else {
          // 关闭加载对话框
          Navigator.of(context).pop();
          
          // 显示错误信息
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('创建直播间失败，请重试'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        // 关闭加载对话框
        Navigator.of(context).pop();
        
        // 显示错误信息
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('创建直播间失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else if (_selectedTags.length < 5) {
        _selectedTags.add(tag);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('最多只能选择5个标签'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('直播设置'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            context.pop();
          },
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 直播标题
              const Text(
                '直播标题',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: '给你的直播起个吸引人的标题吧',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                maxLength: 50,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入直播标题';
                  }
                  if (value.trim().length < 2) {
                    return '标题至少需要2个字符';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              // 直播描述
              const Text(
                '直播描述',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  hintText: '简单介绍一下这次直播的内容',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                maxLines: 3,
                maxLength: 200,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty && value.trim().length < 5) {
                    return '描述至少需要5个字符';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              // 标签选择
              const Text(
                '选择标签',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '已选择 ${_selectedTags.length}/5 个标签',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableTags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return FilterChip(
                    label: Text(tag),
                    selected: isSelected,
                    onSelected: (_) => _toggleTag(tag),
                    selectedColor: Colors.pink.withOpacity(0.3),
                    checkmarkColor: Colors.pink,
                    backgroundColor: Colors.grey[800],
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.pink : Colors.white70,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              
              // 直播设置预览
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '直播设置',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildSettingRow(
                        Icons.videocam,
                        '画质',
                        '高清 (720p)',
                      ),
                      _buildSettingRow(
                        Icons.mic,
                        '音频',
                        '高质量',
                      ),
                      _buildSettingRow(
                        Icons.face_retouching_natural,
                        '美颜',
                        '已开启',
                      ),
                      _buildSettingRow(
                        Icons.visibility,
                        '可见性',
                        '公开',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // 开始直播按钮
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _startLiveStream,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.live_tv, size: 24),
                      SizedBox(width: 8),
                      Text(
                        '开始直播',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // 提示信息
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '请确保网络连接稳定，直播过程中请勿随意切换应用',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: Colors.white70,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.pink,
            ),
          ),
        ],
      ),
    );
  }
}