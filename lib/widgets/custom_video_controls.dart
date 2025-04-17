import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class CustomVideoControls extends StatefulWidget {
  final VideoPlayerController controller;
  final VoidCallback? onToggleFullScreen;
  final bool isFullScreen;

  const CustomVideoControls({
    super.key,
    required this.controller,
    this.onToggleFullScreen,
    this.isFullScreen = false,
  });

  @override
  State<CustomVideoControls> createState() => _CustomVideoControlsState();
}

class _CustomVideoControlsState extends State<CustomVideoControls> {
  bool _showControls = true;
  bool _dragging = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _startHideTimer();

    // 确保重建时控制器同步
    widget.controller.addListener(_controllerListener);
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    widget.controller.removeListener(_controllerListener);
    super.dispose();
  }

  void _controllerListener() {
    if (mounted) setState(() {});
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_dragging) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
      if (_showControls) {
        _startHideTimer();
      }
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return GestureDetector(
      onTap: _toggleControls,
      child: Stack(
        children: [
          // 视频层
          Center(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
          ),

          // 控制层 (有动画)
          AnimatedOpacity(
            opacity: _showControls ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: IgnorePointer(
              ignoring: !_showControls,
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 顶部栏：标题和返回按钮
                    _buildTopBar(),

                    // 中央播放按钮
                    _buildCenterControls(),

                    // 底部栏：进度条和控制按钮
                    _buildBottomBar(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 顶部栏
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // 移除这个返回按钮
          // IconButton(
          //   icon: Icon(
          //     widget.isFullScreen ? Icons.arrow_back : Icons.keyboard_arrow_left,
          //     color: Colors.white,
          //   ),
          //   onPressed: () {
          //     if (widget.isFullScreen) {
          //       widget.onToggleFullScreen?.call();
          //     } else {
          //       Navigator.pop(context);
          //     }
          //   },
          // ),

          // 如果在全屏模式下，添加一个退出全屏按钮
          if (widget.isFullScreen)
            IconButton(
              icon: const Icon(Icons.fullscreen_exit, color: Colors.white),
              onPressed: widget.onToggleFullScreen,
            ),

          // 视频标题或其他信息可以添加在这里
          const Spacer(),
        ],
      ),
    );
  }

  // 中央播放/暂停按钮
  Widget _buildCenterControls() {
    final controller = widget.controller;
    return Center(
      child: IconButton(
        icon: Icon(
          controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
          size: 60,
        ),
        onPressed: () {
          setState(() {
            if (controller.value.isPlaying) {
              controller.pause();
            } else {
              controller.play();
              _startHideTimer();
            }
          });
        },
      ),
    );
  }

  // 底部栏：进度条、时间和控制按钮
  Widget _buildBottomBar() {
    final controller = widget.controller;
    final duration = controller.value.duration;
    final position = controller.value.position;
    final progress =
        duration.inMilliseconds > 0
            ? position.inMilliseconds / duration.inMilliseconds
            : 0.0;

    return Container(
      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 进度条
          GestureDetector(
            onHorizontalDragStart: (details) {
              _dragging = true;
            },
            onHorizontalDragUpdate: (details) {
              final box = context.findRenderObject() as RenderBox;
              final width = box.size.width - 24; // 减去内边距
              final newPosition = details.localPosition.dx.clamp(0, width);
              final percentage = newPosition / width;

              final newTime = duration * percentage;
              controller.seekTo(newTime);
            },
            onHorizontalDragEnd: (details) {
              _dragging = false;
              _startHideTimer();
            },
            child: Container(
              height: 40, // 增大点击区域
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // 背景条
                  Container(
                    height: 4,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // 进度条
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // 进度点
                  Positioned(
                    left:
                        progress *
                        (MediaQuery.of(context).size.width - 24 - 12),
                    child: Container(
                      height: 12,
                      width: 12,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 时间和控制按钮
          Row(
            children: [
              // 当前时间 / 总时间
              Text(
                '${_formatDuration(position)} / ${_formatDuration(duration)}',
                style: const TextStyle(color: Colors.white),
              ),

              const Spacer(),

              // 倍速按钮
              PopupMenuButton<double>(
                icon: const Icon(Icons.speed, color: Colors.white),
                tooltip: '播放速度',
                onSelected: (speed) {
                  controller.setPlaybackSpeed(speed);
                },
                itemBuilder:
                    (context) => [
                      const PopupMenuItem(value: 0.5, child: Text('0.5x')),
                      const PopupMenuItem(value: 1.0, child: Text('1.0x')),
                      const PopupMenuItem(value: 1.5, child: Text('1.5x')),
                      const PopupMenuItem(value: 2.0, child: Text('2.0x')),
                    ],
              ),

              // 全屏按钮
              IconButton(
                icon: Icon(
                  widget.isFullScreen
                      ? Icons.fullscreen_exit
                      : Icons.fullscreen,
                  color: Colors.white,
                ),
                onPressed: widget.onToggleFullScreen,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
