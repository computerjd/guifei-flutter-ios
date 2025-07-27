import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../models/shared_models.dart';
import '../services/shared_api_service.dart';
import '../widgets/custom_video_player.dart';

class VideoDetailScreen extends StatefulWidget {
  final String videoId;

  const VideoDetailScreen({super.key, required this.videoId});

  @override
  State<VideoDetailScreen> createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  Video? _video;
  bool _isLoading = true;
  bool _isLiked = false;
  bool _isFavorited = false;
  List<Video> _relatedVideos = [];

  @override
  void initState() {
    super.initState();
    _loadVideoData();
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> _loadVideoData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 获取视频详情
      // 模拟获取视频详情
      _video = Video(
        id: widget.videoId,
        title: '示例视频标题',
        cover: 'https://picsum.photos/400/300',
        url: 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4',
        description: '这是一个示例视频的描述内容。',
        duration: 300,
        viewCount: 1234,
        likeCount: 56,
        categoryId: 1,
        uploaderId: 'uploader_123',
        uploadTime: DateTime.now().subtract(Duration(hours: 2)),
        tags: ['标签1', '标签2', '标签3'],
         status: 1,
      );
      
      // 获取相关视频
      if (_video != null) {
        // 模拟获取相关视频
        _relatedVideos = List.generate(6, (index) =>
          Video(
            id: 'related_$index',
            title: '相关视频 ${index + 1}',
            cover: 'https://picsum.photos/300/200?random=$index',
            url: 'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4',
            duration: 120 + index * 30,
            viewCount: 1000 + index * 100,
            likeCount: 50 + index * 10,
            categoryId: 1,
            uploaderId: 'uploader_$index',
            uploadTime: DateTime.now().subtract(Duration(days: index)),
            status: index % 4 == 0 ? 1 : 0,
          ),
        );
      }
    } catch (e) {
      print('加载视频数据失败: $e');
      // 使用模拟数据作为后备
      _video = Video(
        id: widget.videoId,
        title: '精彩视频内容 ${widget.videoId}',
        description: '这是一个非常精彩的视频内容，包含了丰富的娱乐元素和有趣的情节。视频制作精良，画质清晰，内容引人入胜。',
        cover: 'https://picsum.photos/800/450?random=${widget.videoId}',
        url: 'assets/videos/941.mp4',
        duration: 330, // 5分30秒
        viewCount: 12580,
        likeCount: 856,
        categoryId: 1,
        uploadTime: DateTime.now().subtract(const Duration(days: 2)),
        status: widget.videoId == '1' || widget.videoId == '3' ? 1 : 0,
        tags: ['娱乐', '精彩'],
        uploaderId: 'user1',
      );
      
      // 模拟相关视频
      _relatedVideos = List.generate(10, (index) {
        return Video(
          id: '${100 + index}',
          title: '相关视频 ${index + 1}',
          description: '相关视频描述 ${index + 1}',
          cover: 'https://picsum.photos/300/200?random=${100 + index}',
          url: 'assets/videos/941.mp4',
          duration: 180 + (index * 30), // 3-8分钟
          viewCount: 1000 + (index * 500),
          likeCount: 50 + (index * 20),
          categoryId: 1,
          uploadTime: DateTime.now().subtract(Duration(days: index + 1)),
          status: index % 4 == 0 ? 1 : 0,
          tags: ['娱乐'],
          uploaderId: 'user${index + 1}',
        );
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // 视频播放器
          _buildVideoPlayer(),
          // 视频信息和相关内容
          Expanded(
            child: Container(
              color: Theme.of(context).colorScheme.background,
              child: Column(
                children: [
                  // 视频信息
                  _buildVideoInfo(),
                  // 操作按钮
                  _buildActionButtons(),
                  // 相关视频
                  Expanded(
                    child: _buildRelatedVideos(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return SafeArea(
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: _video?.url?.isNotEmpty == true
            ? CustomVideoPlayer(
                videoUrl: _video!.url ?? '',
                autoPlay: true,
                aspectRatio: 16 / 9,
              )
            : Container(
                color: Colors.black,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.play_circle_outline,
                        color: Colors.white,
                        size: 64,
                      ),
                      SizedBox(height: 16),
                      Text(
                        '视频链接无效',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
        ),
    );
  }

  Widget _buildVideoInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            children: [
              Expanded(
                child: Text(
                  _video!.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_video!.status == 1) // VIP状态
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.amber, Colors.orange],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'VIP',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // 统计信息
          Row(
            children: [
              Icon(
                Icons.visibility,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                '${_formatCount(_video!.viewCount)}次观看',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.thumb_up,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                '${_formatCount(_video!.likeCount)}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                _formatUploadTime(_video!.uploadTime),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 标签
          if (_video!.tags?.isNotEmpty == true)
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _video!.tags?.map<Widget>((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                    ),
                  ),
                );
              }).toList() ?? [],
            ),
          const SizedBox(height: 12),
          // 描述
          Text(
            _video!.description ?? '暂无描述',
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey[300]!,
            width: 0.5,
          ),
          bottom: BorderSide(
            color: Colors.grey[300]!,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionButton(
            icon: _isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
            label: '点赞',
            isActive: _isLiked,
            onTap: () {
              setState(() {
                _isLiked = !_isLiked;
              });
              _handleLike();
            },
          ),
          _buildActionButton(
            icon: _isFavorited ? Icons.favorite : Icons.favorite_border,
            label: '收藏',
            isActive: _isFavorited,
            onTap: () {
              setState(() {
                _isFavorited = !_isFavorited;
              });
              _handleFavorite();
            },
          ),
          _buildActionButton(
            icon: Icons.share,
            label: '分享',
            onTap: () {
              _showShareDialog();
            },
          ),
          _buildActionButton(
            icon: Icons.download,
            label: '下载',
            onTap: () {
              _downloadVideo();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    final color = isActive
        ? Theme.of(context).colorScheme.primary
        : Colors.grey[600];

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedVideos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '相关推荐',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _relatedVideos.length,
            itemBuilder: (context, index) {
              final video = _relatedVideos[index];
              return _buildRelatedVideoItem(video);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRelatedVideoItem(Video video) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => VideoDetailScreen(videoId: video.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            // 缩略图
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 120,
                    height: 68,
                    child: Image.network(
                      video.cover ?? 'https://via.placeholder.com/300x200',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.error,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // 时长
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      _formatDuration(Duration(seconds: video.duration)),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                if (video.status == 1) // VIP状态
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.amber, Colors.orange],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: const Text(
                        'VIP',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // 视频信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatCount(video.viewCount)}次观看 • ${_formatUploadTime(video.uploadTime)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}万';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatUploadTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

  Future<void> _handleLike() async {
    try {
      if (_isLiked) {
        await SharedApiService.likeVideo(widget.videoId);
      } else {
        await SharedApiService.unlikeVideo(widget.videoId);
      }
    } catch (e) {
      print('点赞操作失败: $e');
      // 显示错误提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('操作失败，请稍后重试')),
      );
    }
  }

  Future<void> _handleFavorite() async {
    try {
      if (_isFavorited) {
        await SharedApiService.favoriteVideo(widget.videoId);
      } else {
        await SharedApiService.unfavoriteVideo(widget.videoId);
      }
    } catch (e) {
      print('收藏操作失败: $e');
      // 显示错误提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('操作失败，请稍后重试')),
      );
    }
  }

  void _showShareDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '分享到',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildShareOption(Icons.wechat, '微信', () {
                  Navigator.pop(context);
                  _shareToWeChat();
                }),
                _buildShareOption(Icons.share, '朋友圈', () {
                  Navigator.pop(context);
                  _shareToMoments();
                }),
                _buildShareOption(Icons.link, '复制链接', () {
                  Navigator.pop(context);
                  _copyLink();
                }),
                _buildShareOption(Icons.more_horiz, '更多', () {
                  Navigator.pop(context);
                  _showMoreShareOptions();
                }),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  void _shareToWeChat() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('分享到微信功能开发中')),
    );
  }

  void _shareToMoments() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('分享到朋友圈功能开发中')),
    );
  }

  void _copyLink() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('链接已复制到剪贴板')),
    );
  }

  void _showMoreShareOptions() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('更多分享选项开发中')),
    );
  }

  void _downloadVideo() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('开始下载 ${_video!.title}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}