import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:shimmer/shimmer.dart';
import '../models/shared_models.dart';
import '../models/app_models.dart';
import '../services/shared_api_service.dart';
import '../widgets/video_card.dart';
import '../widgets/ad_carousel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SharedApiService _apiService = SharedApiService();
  
  List<Video> _videos = [];
  List<Category> _categories = [];
  List<Category> _secondaryCategories = [];
  bool _isLoading = true;
  String _searchText = '';
  int? _selectedCategoryId;
  String? _selectedSecondaryCategoryId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 加载分类数据
      final categories = await SharedApiService.getCategories();
      
      setState(() {
        _categories = categories;
        _videos = []; // 暂时使用空列表
        if (_categories.isNotEmpty) {
          _selectedCategoryId = _categories.first.id;
          _loadSecondaryCategories(_categories.first.id.toString());
        }
      });
    } catch (e) {
      print('加载数据失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载数据失败: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSecondaryCategories(String parentId) async {
    try {
      final response = await SharedApiService.getCategories();
        setState(() {
          _secondaryCategories = response;
          _selectedSecondaryCategoryId = null;
        });
    } catch (e) {
      print('加载二级分类失败: $e');
    }
  }

  Future<void> _loadVideos() async {
    try {
      // 暂时使用模拟数据，因为getVideos方法不存在
      final response = <Video>[];
      
        setState(() {
          _videos = response;
        });
    } catch (e) {
      print('加载视频失败: $e');
    }
  }

  void _onCategorySelected(String categoryId) {
    setState(() {
      _selectedCategoryId = int.tryParse(categoryId);
      _selectedSecondaryCategoryId = null;
      _secondaryCategories = [];
    });
    _loadSecondaryCategories(categoryId);
    _loadVideos();
  }

  void _onSecondaryCategorySelected(String categoryId) {
    setState(() {
      _selectedSecondaryCategoryId = categoryId;
    });
    _loadVideos();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchText = value;
    });
    
    // 延迟搜索以避免频繁请求
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchText == value) {
        _loadVideos();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // 顶部分类导航
            if (_categories.isNotEmpty)
              Container(
                height: 50,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = _selectedCategoryId == category.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: FilterChip(
                        label: Text(category.name),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            _onCategorySelected(category.id.toString());
                          }
                        },
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        selectedColor: Theme.of(context).colorScheme.primary,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    );
                  },
                ),
              ),

            // 搜索框
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '搜索视频...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchText.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onChanged: _onSearchChanged,
              ),
            ),

            const SizedBox(height: 12),

            // 二级分类
            if (_secondaryCategories.isNotEmpty)
              Container(
                height: 40,
                margin: const EdgeInsets.only(bottom: 16),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _secondaryCategories.length + 1, // +1 for "全部" option
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // "全部" 选项
                      final isSelected = _selectedSecondaryCategoryId == null;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedSecondaryCategoryId = null;
                            });
                            _loadVideos();
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            backgroundColor: isSelected 
                                ? Theme.of(context).colorScheme.primary
                                : null,
                            foregroundColor: isSelected
                                ? Theme.of(context).colorScheme.onPrimary
                                : null,
                          ),
                          child: const Text('全部'),
                        ),
                      );
                    }
                    
                    final category = _secondaryCategories[index - 1];
                    final isSelected = _selectedSecondaryCategoryId == category.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: OutlinedButton(
                        onPressed: () {
                          _onSecondaryCategorySelected(category.id.toString());
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          backgroundColor: isSelected 
                              ? Theme.of(context).colorScheme.primary
                              : null,
                          foregroundColor: isSelected
                              ? Theme.of(context).colorScheme.onPrimary
                              : null,
                        ),
                        child: Text(category.name),
                      ),
                    );
                  },
                ),
              ),

            // 广告轮播
            AdCarousel(
              adImages: const [
                'assets/images/ad1.png',
                'assets/images/ad2.png',
              ],
              height: 120,
              onAdTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('广告被点击了！'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // 视频网格
            Expanded(
              child: _isLoading
                  ? _buildLoadingGrid()
                  : _buildVideoGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: MasonryGridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        itemCount: 6,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 200 + (index % 3) * 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVideoGrid() {
    if (_videos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              _searchText.isNotEmpty ? '没有找到相关视频' : '暂无视频',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadVideos,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: MasonryGridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          itemCount: _videos.length,
          itemBuilder: (context, index) {
            final video = _videos[index];
            return VideoCard(
              video: video,
              onTap: () {
                context.go('/video/${video.id}');
              },
            );
          },
        ),
      ),
    );
  }
}