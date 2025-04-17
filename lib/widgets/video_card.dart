import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/video_item.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';

class VideoCard extends StatefulWidget {
  final VideoItem video;
  final VoidCallback? onTap; // 添加点击回调

  const VideoCard({super.key, required this.video, this.onTap});

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> {
  VideoItem? _detailedVideo;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDetailIfNeeded();
  }

  Future<void> _loadDetailIfNeeded() async {
    // 如果没有封面，获取详情
    if (widget.video.coverUrl.isEmpty && !_isLoading) {
      // 先检查缓存
      if (widget.video.siteKey != null &&
          CacheService.hasDetail(widget.video.id)) {
        if (mounted) {
          setState(() {
            _detailedVideo = CacheService.getDetail(widget.video.id);
            _isLoading = false;
          });
        }
        return;
      }

      setState(() => _isLoading = true);

      try {
        if (widget.video.siteKey != null) {
          final detail = await ApiService.getVideoDetail(
            widget.video.id,
            widget.video.siteKey!,
          );

          if (detail != null) {
            // 添加到缓存
            CacheService.addDetail(detail.id, detail);

            if (mounted) {
              setState(() {
                _detailedVideo = detail;
                _isLoading = false;
              });
            }
          }
        }
      } catch (e) {
        print('加载详情失败: $e');
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 使用详情数据或原始数据
    final video = _detailedVideo ?? widget.video;

    return GestureDetector(
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 封面图
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 100,
                height: 140,
                child: _buildCoverImage(video),
              ),
            ),
            const SizedBox(width: 12),
            // 信息区
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (video.type != null)
                    Text(
                      video.type!,
                      style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                    ),
                  const SizedBox(height: 8),
                  if (video.info != null && video.info!.isNotEmpty)
                    Text(
                      video.info!,
                      style: TextStyle(fontSize: 13, color: Colors.orange[300]),
                    ),
                  const SizedBox(height: 4),
                  if (video.episodes.isNotEmpty)
                    Text(
                      '共${video.episodes.length}集',
                      style: const TextStyle(fontSize: 12, color: Colors.green),
                    ),
                ],
              ),
            ),
            // 播放按钮
            const Icon(
              Icons.play_circle_outline,
              color: Colors.white70,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverImage(VideoItem video) {
    if (video.coverUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: video.coverUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildLoadingPlaceholder(),
        errorWidget: (context, url, error) => _buildPlaceholder(),
      );
    } else if (_isLoading) {
      return _buildLoadingPlaceholder();
    } else {
      return _buildPlaceholder();
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[800],
      child: const Center(
        child: Icon(Icons.movie, size: 40, color: Colors.grey),
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      color: Colors.grey[900],
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}
