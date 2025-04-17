import 'package:flutter/material.dart';
import '../models/history_item.dart';
import '../services/storage_service.dart';
import 'player_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<HistoryItem> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // 使用 Future.microtask 延迟加载，避免在构建期间触发状态更新
    Future.microtask(_loadHistory);
  }

  Future<void> _loadHistory() async {
    try {
      final history = await StorageService.getHistory();

      if (mounted) {
        setState(() {
          _history = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('加载历史记录失败: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 添加安全检查来防止布局问题
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('观看历史'),
          actions: [
            if (_history.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete_sweep),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('清空历史记录'),
                          content: const Text('确定要清空所有观看历史吗？'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('取消'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('确定'),
                            ),
                          ],
                        ),
                  );

                  if (confirm == true) {
                    await StorageService.clearHistory();
                    setState(() => _history = []);
                  }
                },
              ),
          ],
        ),
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _history.isEmpty
                ? const Center(child: Text('暂无观看历史'))
                : ListView.builder(
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final item = _history[index];
                    return ListTile(
                      leading: const Icon(Icons.play_circle_filled),
                      title: Text(item.name),
                      subtitle: Text('观看时间: ${_formatTime(item.time)}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _openVideo(item),
                    );
                  },
                ),
      ),
    );
  }

  String _formatTime(String time) {
    try {
      final dateTime = DateTime.parse(time);
      return '${dateTime.year}-${dateTime.month}-${dateTime.day} ${dateTime.hour}:${dateTime.minute}';
    } catch (e) {
      return time;
    }
  }

  void _openVideo(HistoryItem item) {
    final video = item.toVideoItem();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PlayerPage(video: video)),
    );
  }
}
