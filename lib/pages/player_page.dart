import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../models/video_item.dart';
import '../services/storage_service.dart';
import '../models/history_item.dart';
import '../widgets/custom_video_controls.dart';

class PlayerPage extends StatefulWidget {
  final VideoItem video;

  const PlayerPage({super.key, required this.video});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;
  set isPlaying(bool value) {
    setState(() {
      _isPlaying = value;
    });
  }

  bool _isInitialized = false;
  bool _isLoading = false;
  bool _isFullScreen = false;
  late VideoItem _currentVideo;

  @override
  void initState() {
    super.initState();
    _currentVideo = widget.video;
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    setState(() {
      _isInitialized = false;
      _isLoading = true;
    });

    // 确保有播放地址
    if (_currentVideo.playUrl == null || _currentVideo.playUrl!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('无效的播放地址')));
      }
      setState(() => _isLoading = false);
      return;
    }

    // 释放旧控制器资源
    if (_isInitialized) {
      await _controller.dispose();
    }

    try {
      final uri = Uri.parse(_currentVideo.playUrl!);
      _controller = VideoPlayerController.networkUrl(uri);

      await _controller.initialize();
      await _controller.play();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isPlaying = true;
          _isLoading = false;
        });

        // 更新历史记录
        StorageService.addHistory(
          HistoryItem(
            id: _currentVideo.id,
            name: _currentVideo.name,
            playUrl: _currentVideo.playUrl!,
            time: DateTime.now().toString(),
          ),
        );
      }
    } catch (e) {
      print('播放器初始化失败: $e');
      if (mounted) {
        setState(() => _isLoading = false);

        // 提供更友好的错误提示
        final String errorMessage =
            e.toString().contains('byte range')
                ? '无法正确加载视频。请尝试其他视频源。'
                : '视频播放失败: $e';

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    // 确保退出全屏
    if (_isFullScreen) {
      // 使用延迟确保iOS有足够时间处理方向变化
      Future.delayed(const Duration(milliseconds: 100), () {
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      });
    }
    super.dispose();
  }

  // 切换全屏模式
  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;

      if (_isFullScreen) {
        // 全屏模式：横屏并隐藏状态栏
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        // 退出全屏：竖屏并显示状态栏
        // 对于iOS，使用一个延迟来处理方向变化
        Future.delayed(const Duration(milliseconds: 100), () {
          SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        });
      }
    });
  }

  // 切换集数
  void _changeEpisode(int index) {
    if (index < 0 || index >= _currentVideo.episodes.length) return;

    // 如果在全屏模式下切换集数，先退出全屏
    if (_isFullScreen) {
      _toggleFullScreen();
    }

    setState(() {
      _currentVideo = _currentVideo.copyWith(currentEpisode: index);
    });

    _initializePlayer();
  }

  // 构建集数选择器下拉菜单
  Widget _buildEpisodeSelector() {
    if (_currentVideo.episodes.isEmpty) {
      return const SizedBox.shrink();
    }

    return PopupMenuButton<int>(
      icon: const Icon(Icons.playlist_play),
      tooltip: '选集',
      itemBuilder: (context) {
        return List.generate(_currentVideo.episodes.length, (index) {
          final isSelected = index == _currentVideo.currentEpisode;
          return PopupMenuItem<int>(
            value: index,
            child: Row(
              children: [
                if (isSelected)
                  const Icon(
                    Icons.play_arrow,
                    color: Colors.purpleAccent,
                    size: 16,
                  ),
                const SizedBox(width: 4),
                Text(
                  _currentVideo.episodes[index].title,
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.purpleAccent : null,
                  ),
                ),
              ],
            ),
          );
        });
      },
      onSelected: _changeEpisode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appBar =
        _isFullScreen
            ? null
            : AppBar(
              backgroundColor: Colors.black,
              title: Text(_currentVideo.name),
              elevation: 0,
              // 添加返回按钮的处理逻辑
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [_buildEpisodeSelector()],
            );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: appBar,
      body: SafeArea(
        // 全屏模式禁用SafeArea
        bottom: !_isFullScreen,
        top: !_isFullScreen,
        left: !_isFullScreen,
        right: !_isFullScreen,
        child: Container(
          color: Colors.black,
          width: double.infinity,
          // 视频播放器高度占满可用空间
          height: double.infinity,
          child:
              _isInitialized
                  ? CustomVideoControls(
                    controller: _controller,
                    isFullScreen: _isFullScreen,
                    onToggleFullScreen: _toggleFullScreen,
                  )
                  : Center(
                    child:
                        _isLoading
                            ? const CircularProgressIndicator()
                            : const Text(
                              '加载中...',
                              style: TextStyle(color: Colors.white),
                            ),
                  ),
        ),
      ),
    );
  }
}
