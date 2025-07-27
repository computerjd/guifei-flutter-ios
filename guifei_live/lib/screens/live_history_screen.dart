import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/live_provider.dart';
import '../models/live_session_model.dart';
import '../services/api_service.dart';

class LiveHistoryScreen extends ConsumerStatefulWidget {
  const LiveHistoryScreen({super.key});

  @override
  ConsumerState<LiveHistoryScreen> createState() => _LiveHistoryScreenState();
}

class _LiveHistoryScreenState extends ConsumerState<LiveHistoryScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  List<LiveSessionModel> _historyList = [];
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory({bool refresh = false}) async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      if (refresh) {
        _currentPage = 1;
        _historyList.clear();
        _hasMore = true;
      }
    });

    try {
      final history = await _apiService.getLiveHistory(
        page: _currentPage,
        limit: 20,
      );
      
      setState(() {
        if (refresh) {
          _historyList = history;
        } else {
          _historyList.addAll(history);
        }
        _hasMore = history.length == 20;
        _currentPage++;
        _isLoading = false;
      });
    } catch (e) {
      // 使用Provider中的模拟数据
      final providerHistory = ref.read(liveHistoryProvider);
      setState(() {
        _historyList = providerHistory;
        _hasMore = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          '直播历史',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _loadHistory(refresh: true),
          ),
        ],
      ),
      body: _isLoading && _historyList.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _loadHistory(refresh: true),
              child: _historyList.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            '暂无直播历史',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _historyList.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _historyList.length) {
                          return _buildLoadMoreButton();
                        }
                        
                        final session = _historyList[index];
                        return _buildHistoryCard(session);
                      },
                    ),
            ),
    );
  }

  Widget _buildHistoryCard(LiveSessionModel session) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    session.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(session.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(session.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              session.description,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoChip(
                  Icons.access_time,
                  session.formattedDuration,
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  Icons.people,
                  session.viewerCount.toString(),
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  Icons.favorite,
                  session.likeCount.toString(),
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  Icons.monetization_on,
                  '¥${session.earnings.toStringAsFixed(2)}',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '开始时间: ${_formatDateTime(session.startTime)}',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                if (session.tags.isNotEmpty)
                  Wrap(
                    spacing: 4,
                    children: session.tags.take(3).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.pink.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            color: Colors.pink,
                            fontSize: 10,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: Colors.white70,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: () => _loadHistory(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                ),
                child: const Text('加载更多'),
              ),
      ),
    );
  }

  Color _getStatusColor(LiveStatus status) {
    switch (status) {
      case LiveStatus.live:
        return Colors.green;
      case LiveStatus.ended:
        return Colors.grey;
      case LiveStatus.paused:
        return Colors.orange;
      case LiveStatus.preparing:
        return Colors.blue;
    }
  }

  String _getStatusText(LiveStatus status) {
    switch (status) {
      case LiveStatus.live:
        return '直播中';
      case LiveStatus.ended:
        return '已结束';
      case LiveStatus.paused:
        return '已暂停';
      case LiveStatus.preparing:
        return '准备中';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}