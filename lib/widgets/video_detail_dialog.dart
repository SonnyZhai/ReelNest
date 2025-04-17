import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';
import '../models/video_item.dart';
import '../pages/player_page.dart';

class VideoDetailDialog extends StatefulWidget {
  final VideoItem video;
  final bool needFetchDetail;

  const VideoDetailDialog({
    super.key,
    required this.video,
    this.needFetchDetail = false,
  });

  @override
  State<VideoDetailDialog> createState() => _VideoDetailDialogState();
}

class _VideoDetailDialogState extends State<VideoDetailDialog> {
  late VideoItem _video;
  int _selectedEpisode = 0;
  final bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _video = widget.video;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 模糊背景
          _buildBlurredBackground(),

          // 内容层
          Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            decoration: BoxDecoration(
              color: Colors.grey[900]!.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 封面和基本信息
                  _buildHeader(),

                  // 详细信息和选集
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 简介
                            _buildDescription(),

                            const SizedBox(height: 16),

                            // 选集部分
                            if (_video.episodes.isNotEmpty)
                              _buildEpisodeSelector(),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 底部操作栏
                  _buildActionBar(),
                ],
              ),
            ),
          ),

          // 加载中指示器
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  // 模糊背景，使用剧集封面
  Widget _buildBlurredBackground() {
    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_video.coverUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: _video.coverUrl,
              fit: BoxFit.cover,
              errorWidget:
                  (context, url, error) => Container(color: Colors.black),
            ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(color: Colors.black.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }

  // 封面和基本信息
  Widget _buildHeader() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          height: 200,
          child: Row(
            children: [
              // 封面图
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                ),
                child: SizedBox(
                  width: 140,
                  height: 200,
                  child:
                      _video.coverUrl.isNotEmpty
                          ? CachedNetworkImage(
                            imageUrl: _video.coverUrl,
                            fit: BoxFit.cover,
                            placeholder:
                                (context, url) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                            errorWidget:
                                (context, url, error) =>
                                    const Center(child: Icon(Icons.error)),
                          )
                          : Container(
                            color: Colors.grey[800],
                            child: const Icon(Icons.movie, size: 50),
                          ),
                ),
              ),

              // 基本信息
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _video.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      if (_video.type != null)
                        Chip(
                          label: Text(_video.type!),
                          backgroundColor: Colors.blue.withValues(alpha: 0.2),
                          visualDensity: VisualDensity.compact,
                        ),
                      const SizedBox(height: 8),
                      if (_video.info != null)
                        Text(
                          _video.info!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange[300],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (_video.last != null)
                        Text(
                          '更新: ${_video.last}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // 关闭按钮 - 现在正确地放在了 Stack 内部
        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }

  // 剧情简介
  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '剧情简介',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          _video.description ?? '暂无简介',
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
      ],
    );
  }

  // 改进集数选择器
  Widget _buildEpisodeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '选集',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '共${_video.episodes.length}集',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 使用GridView使集数显示更整齐
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            childAspectRatio: 1.5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _video.episodes.length,
          itemBuilder: (context, index) {
            final isSelected = index == _selectedEpisode;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedEpisode = index;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? Colors.purpleAccent : Colors.grey[800],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    _video.episodes[index].title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[300],
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // 底部操作栏：播放按钮
  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('立即播放'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                if (_video.episodes.isEmpty) {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlayerPage(video: _video),
                    ),
                  );
                } else {
                  // 如果有多集，创建一个带有所选集数的VideoItem
                  final selectedVideo = _video.copyWith(
                    currentEpisode: _selectedEpisode,
                  );
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlayerPage(video: selectedVideo),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
