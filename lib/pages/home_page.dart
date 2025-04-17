// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../widgets/search_bar.dart';
import '../widgets/video_card.dart';
import '../models/video_item.dart';
import '../services/api_service.dart';
import 'settings_page.dart';
import 'history_page.dart';
import 'about_page.dart';
import 'privacy_page.dart';
import 'package:flutter/cupertino.dart';
import '../widgets/video_detail_dialog.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<VideoItem> _videos = [];
  bool _loading = false;
  String _searchQuery = '';
  bool _isSearching = false;

  void _onSearch(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _loading = true;
      _searchQuery = query;
      _isSearching = true;
      _videos = []; // 清空已有结果
    });

    try {
      // 使用统一的 search 方法
      final results = await ApiService.search(query);

      // 不再过滤掉无播放地址的项目
      setState(() {
        _videos = results;
        _loading = false;
      });

      if (results.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('未找到相关视频')));
      }
    } catch (e) {
      print('搜索出错: $e');

      setState(() {
        _loading = false;
      });

      // 显示错误提示
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('搜索出错: $e')));
    }
  }

  // void _openPlayer(VideoItem item) async {
  //   // 判断是否需要先获取详情
  //   if (item.needDetail) {
  //     if (item.siteKey == null || item.id.isEmpty) {
  //       ScaffoldMessenger.of(
  //         context,
  //       ).showSnackBar(const SnackBar(content: Text('无法获取视频详情')));
  //       return;
  //     }

  //     setState(() => _loading = true);

  //     try {
  //       // 获取详情
  //       final videoDetail = await ApiService.getVideoDetail(
  //         item.id,
  //         item.siteKey!,
  //       );

  //       setState(() => _loading = false);

  //       if (videoDetail != null) {
  //         Navigator.push(
  //           context,
  //           MaterialPageRoute(
  //             builder: (context) => PlayerPage(video: videoDetail),
  //           ),
  //         );
  //       } else {
  //         ScaffoldMessenger.of(
  //           context,
  //         ).showSnackBar(const SnackBar(content: Text('无法获取视频详情')));
  //       }
  //     } catch (e) {
  //       setState(() => _loading = false);
  //       ScaffoldMessenger.of(
  //         context,
  //       ).showSnackBar(SnackBar(content: Text('获取详情失败: $e')));
  //     }
  //   } else {
  //     // 直接播放
  //     Navigator.push(
  //       context,
  //       MaterialPageRoute(builder: (context) => PlayerPage(video: item)),
  //     );
  //   }
  // }

  void _openAbout() {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (_) => const AboutPage()),
    );
  }

  void _openPrivacy() {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (_) => const PrivacyPage()),
    );
  }

  // 修改点击处理方法
  void _onVideoTap(VideoItem item) async {
    // 判断是否需要先获取详情
    if (item.needDetail) {
      if (item.siteKey == null || item.id.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('无法获取视频详情')));
        return;
      }

      setState(() => _loading = true);

      try {
        // 获取详情
        final videoDetail = await ApiService.getVideoDetail(
          item.id,
          item.siteKey!,
        );

        setState(() => _loading = false);

        if (videoDetail != null && mounted) {
          // 显示详情弹窗
          showGeneralDialog(
            context: context,
            barrierDismissible: true,
            barrierLabel: '关闭',
            barrierColor: Colors.black87,
            transitionDuration: const Duration(milliseconds: 300),
            pageBuilder: (_, __, ___) => VideoDetailDialog(video: videoDetail),
            transitionBuilder: (context, animation, secondaryAnimation, child) {
              return ScaleTransition(
                scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('无法获取视频详情')));
        }
      } catch (e) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('获取详情失败: $e')));
      }
    } else {
      // 直接显示详情弹窗
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => VideoDetailDialog(video: item),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.tv, color: Colors.white, size: 32),
            const SizedBox(width: 12),
            ShaderMask(
              shaderCallback:
                  (bounds) => const LinearGradient(
                    colors: [Colors.pinkAccent, Colors.lightBlueAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
              child: const Text(
                'ReelNest',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // 使用 Builder 提供正确的 context
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const HistoryPage()),
              );
            },
            // 移除 tooltip 属性，它可能是导致布局问题的原因
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
          Builder(
            builder:
                (context) => IconButton(
                  icon: const Icon(Icons.more_vert),
                  tooltip: '更多',
                  onPressed: () {
                    // 使用 showMenu 手动显示菜单
                    final RenderBox button =
                        context.findRenderObject() as RenderBox;
                    final RenderBox overlay =
                        Navigator.of(
                              context,
                            ).overlay!.context.findRenderObject()
                            as RenderBox;
                    final RelativeRect position = RelativeRect.fromRect(
                      Rect.fromPoints(
                        button.localToGlobal(Offset.zero, ancestor: overlay),
                        button.localToGlobal(
                          button.size.bottomRight(Offset.zero),
                          ancestor: overlay,
                        ),
                      ),
                      Offset.zero & overlay.size,
                    );

                    showMenu<String>(
                      context: context,
                      position: position,
                      items: const [
                        PopupMenuItem(value: 'about', child: Text('关于')),
                        PopupMenuItem(value: 'privacy', child: Text('隐私政策')),
                      ],
                    ).then((value) {
                      if (value == 'about') _openAbout();
                      if (value == 'privacy') _openPrivacy();
                    });
                  },
                ),
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF3A3A60), Color(0xFF6D44B8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: LayoutBuilder(
          // 使用 LayoutBuilder
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 600; // 定义桌面断点
            final appBarHeight =
                kToolbarHeight + MediaQuery.of(context).padding.top;
            final searchBarTop =
                _isSearching
                    ? appBarHeight + 10
                    : constraints.maxHeight / 2 - 60;

            return Stack(
              children: [
                // 搜索结果列表
                if (_isSearching)
                  Positioned.fill(
                    top: appBarHeight + 80,
                    child: Align(
                      // 桌面端居中显示列表
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isDesktop ? 800 : double.infinity,
                        ),
                        child:
                            _loading
                                ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                                : _videos.isEmpty && _searchQuery.isNotEmpty
                                ? const Center(
                                  child: Text(
                                    '未找到相关视频',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                )
                                : ListView.builder(
                                  itemCount: _videos.length,
                                  itemBuilder: (context, index) {
                                    return GestureDetector(
                                      onTap: () => _onVideoTap(_videos[index]),
                                      child: VideoCard(video: _videos[index]),
                                    );
                                  },
                                ),
                      ),
                    ),
                  ),

                // 搜索栏
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  top: searchBarTop,
                  left: 0,
                  right: 0,
                  child: Align(
                    // 桌面端限制搜索栏宽度
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isDesktop ? 600 : 400,
                      ),
                      child: SearchBarWidget(onSearch: _onSearch),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Widget _buildAnimatedListItem(
  //   BuildContext context,
  //   int index,
  //   VideoItem video,
  // ) {
  //   // 动画保持不变
  //   return AnimatedContainer(
  //     duration: Duration(milliseconds: 300 + index * 50),
  //     curve: Curves.easeOut,
  //     transform: Matrix4.translationValues(0, _isSearching ? 0 : 50, 0),
  //     child: Opacity(
  //       opacity: _isSearching ? 1.0 : 0.0,
  //       child: GestureDetector(
  //         onTap: () => _openPlayer(video),
  //         child: VideoCard(video: video),
  //       ),
  //     ),
  //   );
  // }
}
