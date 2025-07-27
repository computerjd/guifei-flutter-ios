import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../providers/live_provider.dart';
import '../providers/websocket_provider.dart';
import '../models/live_session_model.dart';
import '../models/websocket_message_model.dart';
import '../services/api_service.dart';
import '../widgets/chat_widget.dart';
import '../widgets/gift_animation_widget.dart';

class LiveStreamScreen extends ConsumerStatefulWidget {
  const LiveStreamScreen({super.key});

  @override
  ConsumerState<LiveStreamScreen> createState() => _LiveStreamScreenState();
}

class _LiveStreamScreenState extends ConsumerState<LiveStreamScreen> with TickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isLiveStreaming = false;
  bool _isCameraInitialized = false;
  int _selectedCameraIndex = 0;
  bool _isFlashOn = false;
  bool _isMuted = false;
  bool _isBeautyOn = true;
  double _beautyLevel = 0.5;
  int _likeCount = 0;
  final ApiService _apiService = ApiService();
  String? _currentRoomId;
  
  // 抖音风格动画控制器
  late AnimationController _heartAnimationController;
  late AnimationController _giftAnimationController;
  late AnimationController _buttonAnimationController;
  
  // 模拟评论数据
  final List<Map<String, String>> _comments = [
    {'user': '小仙女', 'message': '主播好美！'},
    {'user': '路人甲', 'message': '666'},
    {'user': '粉丝1号', 'message': '关注了关注了'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    
    // 设置全屏沉浸式UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    // 初始化动画控制器
    _heartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _giftAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        _cameraController = CameraController(
          _cameras[_selectedCameraIndex],
          ResolutionPreset.high,
          enableAudio: true,
        );
        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint('相机初始化失败: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length > 1) {
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
      await _cameraController?.dispose();
      _cameraController = CameraController(
        _cameras[_selectedCameraIndex],
        ResolutionPreset.high,
        enableAudio: true,
      );
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController != null) {
      _isFlashOn = !_isFlashOn;
      await _cameraController!.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );
      setState(() {});
    }
  }

  void _toggleLiveStream() {
    setState(() {
      _isLiveStreaming = !_isLiveStreaming;
      if (_isLiveStreaming) {
        _currentRoomId = 'room_${DateTime.now().millisecondsSinceEpoch}';
        // 连接WebSocket
        ref.read(webSocketManagerProvider).connectToRoom(
          serverUrl: 'ws://localhost:3000',
          roomId: _currentRoomId!,
          userId: 'user_${DateTime.now().millisecondsSinceEpoch}',
          userName: '主播',
        );
      } else {
        // 断开WebSocket连接
        ref.read(webSocketManagerProvider).disconnect();
        _currentRoomId = null;
      }
    });
  }

  void _sendLike() {
    if (_currentRoomId != null) {
      ref.read(webSocketManagerProvider).sendLike();
      setState(() {
        _likeCount++;
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _heartAnimationController.dispose();
    _giftAnimationController.dispose();
    _buttonAnimationController.dispose();
    
    // 恢复系统UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    // 断开WebSocket连接
    if (_currentRoomId != null) {
      ref.read(webSocketManagerProvider).disconnect();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 全屏相机预览背景
          Positioned.fill(
            child: _cameraController != null && _cameraController!.value.isInitialized
                ? CameraPreview(_cameraController!)
                : Container(
                    color: Colors.black,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.pink,
                      ),
                    ),
                  ),
          ),
          
          // 渐变遮罩
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.6),
                  ],
                  stops: const [0.0, 0.3, 0.7, 1.0],
                ),
              ),
            ),
          ),
          
          // 顶部状态栏
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Row(
              children: [
                // 返回按钮
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const Spacer(),
                // 直播状态和观看人数
                if (_isLiveStreaming) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Consumer(
                    builder: (context, ref, child) {
                      final viewerCount = ref.watch(viewerCountProvider);
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.visibility,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${viewerCount.count}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
            
          // 右侧功能按钮（抖音风格）
          Positioned(
            right: 16,
            top: MediaQuery.of(context).size.height * 0.3,
            child: Column(
              children: [
                // 翻转摄像头
                _buildTikTokStyleButton(
                  Icons.flip_camera_ios,
                  _switchCamera,
                ),
                const SizedBox(height: 20),
                // 闪光灯
                _buildTikTokStyleButton(
                  _isFlashOn ? Icons.flash_on : Icons.flash_off,
                  _toggleFlash,
                  isActive: _isFlashOn,
                ),
                const SizedBox(height: 20),
                // 麦克风
                _buildTikTokStyleButton(
                  _isMuted ? Icons.mic_off : Icons.mic,
                  () {
                    setState(() {
                      _isMuted = !_isMuted;
                    });
                  },
                  isActive: _isMuted,
                ),
                const SizedBox(height: 20),
                // 美颜
                _buildTikTokStyleButton(
                  Icons.face_retouching_natural,
                  _showBeautyDialog,
                  isActive: _isBeautyOn,
                ),
                const SizedBox(height: 20),
                // 滤镜
                _buildTikTokStyleButton(
                  Icons.filter_vintage,
                  _showFilterDialog,
                ),
                const SizedBox(height: 20),
                // 观众列表
                _buildTikTokStyleButton(
                  Icons.people,
                  _showViewerList,
                ),
              ],
            ),
          ),
            
          // 左侧评论区域（抖音风格）
          if (_isLiveStreaming)
            Positioned(
              left: 16,
              bottom: 120,
              width: MediaQuery.of(context).size.width * 0.6,
              height: 200,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 实时评论流
                  Expanded(
                    child: ListView.builder(
                      reverse: true,
                      itemCount: _comments.length,
                      itemBuilder: (context, index) {
                        final comment = _comments[_comments.length - 1 - index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '${comment['user']}: ',
                                  style: const TextStyle(
                                    color: Colors.pink,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                TextSpan(
                                  text: comment['message'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          
          // 飘心动画区域
          if (_isLiveStreaming)
            Positioned(
              right: 20,
              bottom: 200,
              child: _buildHeartAnimation(),
            ),
          
          // 礼物动画区域
          if (_isLiveStreaming)
            Positioned(
              left: 20,
              top: MediaQuery.of(context).size.height * 0.4,
              child: _buildGiftAnimation(),
            ),
            
          // 底部控制栏（抖音风格）
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
                top: 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  // 评论输入框
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: const TextField(
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: '说点什么...',
                          hintStyle: TextStyle(
                            color: Colors.white54,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 开播/停播按钮
                  GestureDetector(
                    onTap: _toggleLiveStream,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: _isLiveStreaming 
                              ? [Colors.red, Colors.red.shade700]
                              : [Colors.pink, Colors.pink.shade700],
                        ),
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_isLiveStreaming ? Colors.red : Colors.pink).withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isLiveStreaming ? Icons.stop : Icons.videocam,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 抖音风格按钮
  Widget _buildTikTokStyleButton(IconData icon, VoidCallback onPressed, {bool isActive = false}) {
    return GestureDetector(
      onTap: () {
        _buttonAnimationController.forward().then((_) {
          _buttonAnimationController.reverse();
        });
        onPressed();
      },
      child: AnimatedBuilder(
        animation: _buttonAnimationController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_buttonAnimationController.value * 0.1),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive 
                    ? Colors.pink.withOpacity(0.9)
                    : Colors.black.withOpacity(0.6),
                border: Border.all(
                  color: isActive ? Colors.pink : Colors.white.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isActive ? Colors.pink : Colors.black).withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
          );
        },
      ),
    );
  }

  // 飘心动画
  Widget _buildHeartAnimation() {
    return AnimatedBuilder(
      animation: _heartAnimationController,
      builder: (context, child) {
        return Stack(
          children: List.generate(5, (index) {
            final random = Random();
            final delay = index * 0.2;
            final progress = (_heartAnimationController.value - delay).clamp(0.0, 1.0);
            
            return Positioned(
              right: random.nextDouble() * 30,
              bottom: progress * 100,
              child: Opacity(
                opacity: (1.0 - progress).clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: 0.5 + (progress * 0.5),
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.red,
                    size: 30,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
  
  // 礼物动画
  Widget _buildGiftAnimation() {
    return AnimatedBuilder(
      animation: _giftAnimationController,
      builder: (context, child) {
        return Opacity(
          opacity: _giftAnimationController.value > 0.5 
              ? (1.0 - _giftAnimationController.value) * 2 
              : _giftAnimationController.value * 2,
          child: Transform.scale(
            scale: 0.5 + (_giftAnimationController.value * 0.5),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.purple, Colors.pink],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '🎁 +1',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  // 发送飘心
  void _sendHeart() {
    _heartAnimationController.forward().then((_) {
      _heartAnimationController.reset();
    });
  }
  
  // 发送礼物
  void _sendGift() {
    _giftAnimationController.forward().then((_) {
      _giftAnimationController.reset();
    });
  }
  
  // 添加评论
  void _addComment(String message) {
    setState(() {
      _comments.add({
        'user': '观众${Random().nextInt(999)}',
        'message': message,
      });
      if (_comments.length > 20) {
        _comments.removeAt(0);
      }
    });
  }

  void _showBeautyDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.black.withOpacity(0.8),
              title: const Text(
                '美颜设置',
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text(
                        '美颜开关',
                        style: TextStyle(color: Colors.white),
                      ),
                      const Spacer(),
                      Switch(
                        value: _isBeautyOn,
                        onChanged: (value) {
                          setState(() {
                            _isBeautyOn = value;
                          });
                          this.setState(() {});
                        },
                        activeColor: Colors.pink,
                      ),
                    ],
                  ),
                  if (_isBeautyOn) ...[
                    const SizedBox(height: 16),
                    const Text(
                      '美颜强度',
                      style: TextStyle(color: Colors.white),
                    ),
                    Slider(
                      value: _beautyLevel,
                      onChanged: (value) {
                        setState(() {
                          _beautyLevel = value;
                        });
                        this.setState(() {});
                      },
                      activeColor: Colors.pink,
                      inactiveColor: Colors.grey,
                    ),
                    Text(
                      '${(_beautyLevel * 100).round()}%',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    '确定',
                    style: TextStyle(color: Colors.pink),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black.withOpacity(0.8),
          title: const Text(
            '滤镜选择',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('原始', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.of(context).pop(),
              ),
              ListTile(
                title: const Text('美白', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.of(context).pop(),
              ),
              ListTile(
                title: const Text('复古', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showViewerList() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Consumer(
          builder: (context, ref, child) {
            final viewerCount = ref.watch(viewerCountProvider);
            return AlertDialog(
              backgroundColor: Colors.black.withOpacity(0.8),
              title: Text(
                '观众列表 (${viewerCount.count})',
                style: const TextStyle(color: Colors.white),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 200,
                child: ListView.builder(
                  itemCount: viewerCount.count > 10 ? 10 : viewerCount.count,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person),
                      ),
                      title: Text(
                        '观众${index + 1}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    '关闭',
                    style: TextStyle(color: Colors.pink),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}