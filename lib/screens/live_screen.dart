import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../models/app_models.dart';
import '../models/shared_models.dart';
import '../services/shared_api_service.dart';
import 'dart:math' as math;

class LiveScreen extends StatefulWidget {
  const LiveScreen({super.key});

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> with TickerProviderStateMixin {
  final SharedApiService _apiService = SharedApiService();
  final PageController _pageController = PageController();
  final TextEditingController _commentController = TextEditingController();
  
  bool _isLoading = true;
  List<LiveRoom> _liveRooms = [];
  int _currentIndex = 0;
  bool _showComments = false;
  
  // 动画控制器
  late AnimationController _heartAnimationController;
  late AnimationController _giftAnimationController;
  
  // 模拟评论数据
  final List<Map<String, String>> _comments = [
    {'user': '用户123', 'message': '主播好棒！'},
    {'user': '小可爱', 'message': '666666'},
    {'user': '路人甲', 'message': '这个游戏好玩吗？'},
    {'user': '粉丝一号', 'message': '支持主播！'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _heartAnimationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _giftAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // 设置全屏沉浸式
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _commentController.dispose();
    _heartAnimationController.dispose();
    _giftAnimationController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final liveRooms = await SharedApiService.getLiveRooms();
      setState(() {
        _liveRooms = liveRooms.where((room) => room.status == LiveRoomStatus.live).toList();
      });
    } catch (e) {
      print('加载数据失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载数据失败: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _sendHeart() {
    _heartAnimationController.forward().then((_) {
      _heartAnimationController.reset();
    });
  }

  void _sendGift() {
    _giftAnimationController.forward().then((_) {
      _giftAnimationController.reset();
    });
  }

  void _sendComment() {
    if (_commentController.text.trim().isNotEmpty) {
      setState(() {
        _comments.add({
          'user': '我',
          'message': _commentController.text.trim(),
        });
      });
      _commentController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : _liveRooms.isEmpty
              ? _buildEmptyState()
              : Stack(
                  children: [
                    // 主要内容区域 - 全屏PageView
                    PageView.builder(
                      controller: _pageController,
                      scrollDirection: Axis.vertical,
                      itemCount: _liveRooms.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        return _buildLivePageView(_liveRooms[index]);
                      },
                    ),
                    
                    // 顶部状态栏和返回按钮
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 10,
                      left: 16,
                      right: 16,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
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
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.live_tv_outlined,
            size: 64,
            color: Colors.white.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无直播间',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('刷新'),
          ),
        ],
      ),
    );
  }

  Widget _buildLivePageView(LiveRoom room) {
    return Stack(
      children: [
        // 背景视频/图片
        Positioned.fill(
          child: room.cover != null
              ? CachedNetworkImage(
                  imageUrl: room.cover!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[800],
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[800],
                    child: const Center(
                      child: Icon(
                        Icons.live_tv,
                        color: Colors.white,
                        size: 100,
                      ),
                    ),
                  ),
                )
              : Container(
                  color: Colors.grey[800],
                  child: const Center(
                    child: Icon(
                      Icons.live_tv,
                      color: Colors.white,
                      size: 100,
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
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.7),
                ],
                stops: const [0.0, 0.5, 0.8, 1.0],
              ),
            ),
          ),
        ),
        
        // 右侧功能按钮
        Positioned(
          right: 16,
          bottom: 200,
          child: _buildRightSideButtons(room),
        ),
        
        // 底部主播信息和评论区
        Positioned(
          left: 16,
          right: 80,
          bottom: 100,
          child: _buildBottomInfo(room),
        ),
        
        // 评论输入框
        if (_showComments)
          Positioned(
            left: 16,
            right: 16,
            bottom: 50,
            child: _buildCommentInput(),
          ),
        
        // 飘心动画
        _buildHeartAnimation(),
        
        // 礼物动画
        _buildGiftAnimation(),
      ],
    );
  }

  Widget _buildRightSideButtons(LiveRoom room) {
    return Column(
      children: [
        // 点赞按钮
        _buildActionButton(
          icon: Icons.favorite,
          onTap: _sendHeart,
          color: Colors.red,
        ),
        const SizedBox(height: 20),
        
        // 评论按钮
        _buildActionButton(
          icon: Icons.chat_bubble_outline,
          onTap: () {
            setState(() {
              _showComments = !_showComments;
            });
          },
        ),
        const SizedBox(height: 20),
        
        // 礼物按钮
        _buildActionButton(
          icon: Icons.card_giftcard,
          onTap: _sendGift,
          color: Colors.amber,
        ),
        const SizedBox(height: 20),
        
        // 分享按钮
        _buildActionButton(
          icon: Icons.share,
          onTap: () {
            // 分享功能
          },
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: color ?? Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildBottomInfo(LiveRoom room) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 主播信息
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: Colors.grey,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '主播${room.anchorId}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_formatViewerCount(room.viewerCount ?? 0)} 人观看',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // 关注按钮
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '关注',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // 直播标题
        Text(
          room.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),
        
        // 评论列表
        if (_showComments)
          Container(
            height: 150,
            child: ListView.builder(
              itemCount: _comments.length,
              itemBuilder: (context, index) {
                final comment = _comments[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${comment['user']}: ',
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: comment['message'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
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
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: '说点什么...',
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          GestureDetector(
            onTap: _sendComment,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeartAnimation() {
    return AnimatedBuilder(
      animation: _heartAnimationController,
      builder: (context, child) {
        if (_heartAnimationController.value == 0) {
          return const SizedBox.shrink();
        }
        
        return Positioned(
          right: 30 + (20 * _heartAnimationController.value),
          bottom: 300 + (100 * _heartAnimationController.value),
          child: Opacity(
            opacity: 1 - _heartAnimationController.value,
            child: Transform.scale(
              scale: 0.5 + (0.5 * _heartAnimationController.value),
              child: const Icon(
                Icons.favorite,
                color: Colors.red,
                size: 30,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGiftAnimation() {
    return AnimatedBuilder(
      animation: _giftAnimationController,
      builder: (context, child) {
        if (_giftAnimationController.value == 0) {
          return const SizedBox.shrink();
        }
        
        return Positioned(
          left: 20,
          bottom: 200 + (50 * _giftAnimationController.value),
          child: Opacity(
            opacity: 1 - _giftAnimationController.value,
            child: Transform.scale(
              scale: 1 + (0.5 * _giftAnimationController.value),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '🎁 礼物',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }



  String _formatViewerCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }
}