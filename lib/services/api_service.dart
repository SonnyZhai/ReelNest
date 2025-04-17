// ignore_for_file: prefer_interpolation_to_compose_strings

import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../config/site_config.dart';
import '../models/video_item.dart';
import '../models/api_site.dart';
import 'storage_service.dart';
import 'cache_service.dart';

class ApiService {
  /// 构建代理API的URI
  static Uri buildProxyUri({
    required String siteKey,
    required String path,
    required String query,
  }) {
    return Uri(
      scheme: SiteConfig.proxyScheme,
      host: SiteConfig.proxyHost,
      port: SiteConfig.proxyPort,
      path: SiteConfig.proxyPath,
      queryParameters: {'site': siteKey, 'path': path, 'query': query},
    );
  }

  /// 构建特殊详情API的URI
  static Uri buildSpecialDetailUri({
    required String id,
    required String source,
  }) {
    return Uri(
      scheme: SiteConfig.proxyScheme,
      host: SiteConfig.proxyHost,
      port: SiteConfig.proxyPort,
      path: SiteConfig.proxySpecialDetailPath,
      queryParameters: {'id': id, 'source': source},
    );
  }

  /// 获取当前应使用的 API 站点列表（根据成人模式过滤）
  static Future<List<ApiSite>> _getAvailableSites() async {
    final adultModeEnabled = await StorageService.getAdultMode();
    return apiSites.where((site) => site.adult == adultModeEnabled).toList();
  }

  /// 单个源搜索
  static Future<List<VideoItem>> _searchSingleSource(
    String query,
    String siteKey,
  ) async {
    // 对搜索词进行 URL 编码
    final encodedQuery = Uri.encodeComponent(query);
    final queryString = 'ac=search&wd=$encodedQuery';

    // 使用 Uri 构造器自动处理编码
    // 使用辅助方法构建URI
    final uri = buildProxyUri(
      siteKey: siteKey,
      path: SiteConfig.proxySearchPath,
      query: queryString,
    );

    try {
      final response = await http
          .get(uri)
          .timeout(const Duration(milliseconds: SiteConfig.proxyTimeoutMs));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List list = data['list'] ?? [];
        return list
            .map((e) => VideoItem.fromJson(e, siteName: siteKey))
            .toList();
      }
    } catch (e) {
      print('搜索 $siteKey 失败: $e');
    }
    return [];
  }

  /// 获取视频详情
  static Future<VideoItem?> getVideoDetail(
    String videoId,
    String siteKey,
  ) async {
    // 检查是否是特殊源
    if (siteKey == 'ffzy' || siteKey == 'dbzy') {
      return getSpecialSourceDetail(videoId, siteKey);
    } else if (siteKey == 'jisu') {
      return getJisuSourceDetail(videoId, siteKey);
    }

    // 检查缓存
    if (CacheService.hasDetail(videoId)) {
      return CacheService.getDetail(videoId);
    }

    final queryString = 'ac=videolist&ids=$videoId';

    // 使用辅助方法构建URI
    final uri = buildProxyUri(
      siteKey: siteKey,
      path: SiteConfig.proxySearchPath,
      query: queryString,
    );

    try {
      final response = await http
          .get(uri)
          .timeout(const Duration(milliseconds: SiteConfig.proxyTimeoutMs));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List list = data['list'] ?? [];

        if (list.isNotEmpty) {
          final videoItem = VideoItem.fromJson(list[0], siteName: siteKey);
          // 添加到缓存
          CacheService.addDetail(videoId, videoItem);

          return videoItem;
        }
      }
    } catch (e) {
      print('获取视频详情失败: $e');
    }
    return null;
  }

  /// 统一搜索入口 (供 HomePage 调用)
  static Future<List<VideoItem>> search(String query) async {
    // 获取用户成人模式设置
    final adultMode = await StorageService.getAdultMode();
    // 获取聚合搜索设置
    final useAggregatedSearch =
        await StorageService.getAggregatedSearchEnabled();

    if (useAggregatedSearch) {
      // 聚合搜索 - 过滤成人内容
      final availableSites =
          apiSites.where((site) => !site.adult || adultMode).toList();

      if (availableSites.isEmpty) {
        return [];
      }

      final futures = availableSites.map(
        (site) => _searchSingleSource(query, site.key),
      );
      final results = await Future.wait(futures);

      // 合并并去重结果
      final allVideos = <VideoItem>[];
      for (var list in results) {
        allVideos.addAll(list);
      }

      final uniqueVideos = <VideoItem>[];
      final seenIds = <String>{};

      for (var video in allVideos) {
        if (!seenIds.contains(video.id)) {
          seenIds.add(video.id);
          uniqueVideos.add(video);
        }
      }

      return uniqueVideos;
    } else {
      // 单源搜索
      final selectedApiKey = await StorageService.getSelectedApi();

      // 检查选择的API是否符合成人模式设置
      final matchingSites =
          apiSites
              .where(
                (site) =>
                    site.key == selectedApiKey && (adultMode == site.adult),
              )
              .toList();

      // 如果没有找到合适的站点，选择第一个符合当前成人模式的站点
      final site =
          matchingSites.isNotEmpty
              ? matchingSites.first
              : apiSites.firstWhere(
                (site) => adultMode == site.adult,
                orElse: () => apiSites.first,
              );

      return _searchSingleSource(query, site.key);
    }
  }

  /// 聚合搜索（根据成人模式过滤数据源）
  static Future<List<VideoItem>> searchVideosFiltered(String query) async {
    final availableSites = await _getAvailableSites();
    if (availableSites.isEmpty) return []; // 如果没有可用源，直接返回空

    final futures =
        availableSites
            .map((site) => _searchSingleSource(query, site.key))
            .toList();
    final results = await Future.wait(futures);

    final all = results.expand((x) => x).toList();
    final map = <String, VideoItem>{};
    for (var v in all) {
      map[v.id] = v; // 使用 ID 去重
    }
    return map.values.toList();
  }

  // 获取特殊源的详情
  static Future<VideoItem?> getSpecialSourceDetail(
    String videoId,
    String sourceCode,
  ) async {
    // 检查缓存，避免重复请求
    final cacheKey = "${sourceCode}_$videoId";
    if (CacheService.hasDetail(cacheKey)) {
      return CacheService.getDetail(cacheKey);
    }

    final uri = buildSpecialDetailUri(id: videoId, source: sourceCode);

    try {
      final response = await http
          .get(uri)
          .timeout(const Duration(milliseconds: SiteConfig.proxyTimeoutMs));

      if (response.statusCode == 200) {
        // 显式指定解码为 UTF-8
        final responseBody = utf8.decode(response.bodyBytes);

        // 解析后端返回的原始JSON数据
        final data = json.decode(responseBody);

        // 检查数据结构是否符合预期
        final code =
            data['code'] is int
                ? data['code']
                : int.tryParse(data['code'].toString());
        if (code == 1 && data['list'] != null) {
          final List list = data['list'];

          if (list.isEmpty) {
            print('获取特殊源详情: 数据列表为空');
            return null;
          }

          // 获取第一个视频项
          var videoData = list[0];

          // 提取剧集链接
          String playUrl = videoData['vod_play_url'] ?? '';

          // 构建剧集列表
          List<Episode> episodes = [];

          // 解析播放链接 - 类似 getJisuSourceDetail 的处理
          if (playUrl.contains('\$\$\$')) {
            List<String> parts = playUrl.split('\$\$\$');
            // 优先使用第二部分 (m3u8格式)
            if (parts.length > 1) {
              String m3u8Part = parts[1];
              List<String> episodeEntries = m3u8Part.split('#');

              // 处理每一集
              for (int i = 0; i < episodeEntries.length; i++) {
                String entry = episodeEntries[i];
                if (entry.contains('\$')) {
                  List<String> entryParts = entry.split('\$');
                  if (entryParts.length >= 2) {
                    String title = entryParts[0];
                    String url = entryParts[1];

                    // 验证URL是m3u8格式
                    if (url.endsWith('.m3u8')) {
                      episodes.add(Episode(title: title, url: url));
                    }
                  }
                }
              }
            }
          }

          // 如果没有找到m3u8链接，尝试解析第一部分
          if (episodes.isEmpty && playUrl.isNotEmpty) {
            List<String> parts = playUrl.split('\$\$\$');
            String firstPart = parts[0];
            List<String> allEntries = firstPart.split('#');

            for (int i = 0; i < allEntries.length; i++) {
              String entry = allEntries[i];
              if (entry.contains('\$')) {
                List<String> entryParts = entry.split('\$');
                if (entryParts.length >= 2) {
                  String title = entryParts[0];
                  String url = entryParts[1];
                  episodes.add(Episode(title: title, url: url));
                }
              }
            }
          }

          // 检查是否有剧集
          if (episodes.isEmpty) {
            print('获取特殊源详情: 未找到播放链接');
            return null;
          }

          // 创建VideoItem
          final videoItem = VideoItem(
            id: videoData['vod_id']?.toString() ?? '',
            name: videoData['vod_name'] ?? '',
            coverUrl: videoData['vod_pic'] ?? '',
            info: videoData['vod_remarks'] ?? '',
            type: videoData['type_name'] ?? '',
            last: videoData['vod_time'] ?? '',
            // 使用第一集作为默认播放地址
            playUrl: episodes.isNotEmpty ? episodes[0].url : null,
            siteKey: sourceCode,
            needDetail: false,
            description: videoData['vod_content'] ?? '',
            episodes: episodes,
          );

          // 添加到缓存
          CacheService.addDetail(cacheKey, videoItem);

          print('获取特殊源详情成功: ${episodes.length}集');
          return videoItem;
        } else {
          print('获取特殊源详情: 数据格式不符合预期');
        }
      }
    } catch (e) {
      print('获取特殊源详情失败: $e');
    }
    return null;
  }

  // 为极速源添加的特殊处理方法
  static Future<VideoItem?> getJisuSourceDetail(
    String videoId,
    String siteKey,
  ) async {
    // 特殊缓存键，避免与其他源混淆
    final cacheKey = "jisu_$videoId";

    // 检查缓存
    if (CacheService.hasDetail(cacheKey)) {
      return CacheService.getDetail(cacheKey);
    }

    final queryString = 'ac=videolist&ids=$videoId';

    final uri = buildProxyUri(
      siteKey: siteKey,
      path: SiteConfig.proxySearchPath,
      query: queryString,
    );

    try {
      final response = await http
          .get(uri)
          .timeout(const Duration(milliseconds: SiteConfig.proxyTimeoutMs));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List list = data['list'] ?? [];

        if (list.isNotEmpty) {
          var videoData = list[0];
          String playUrl = videoData['vod_play_url'] ?? '';

          // 拆分并处理播放链接
          List<Episode> episodes = [];

          // 查找m3u8格式链接（通常是第二部分）
          if (playUrl.contains('\$\$\$')) {
            List<String> parts = playUrl.split('\$\$\$');
            // 使用m3u8格式的链接（通常是第二部分）
            if (parts.length > 1) {
              String m3u8Part = parts[1];
              // 解析各集信息
              List<String> episodeEntries = m3u8Part.split('#');

              // 处理每一集
              for (int i = 0; i < episodeEntries.length; i++) {
                String entry = episodeEntries[i];
                if (entry.contains('\$')) {
                  List<String> entryParts = entry.split('\$');
                  if (entryParts.length >= 2) {
                    String title = entryParts[0];
                    String url = entryParts[1];

                    // 验证URL是m3u8格式
                    if (url.endsWith('.m3u8')) {
                      episodes.add(Episode(title: title, url: url));
                    }
                  }
                }
              }
            }
          }

          // 如果没有找到m3u8链接，尝试解析原始链接
          if (episodes.isEmpty && playUrl.isNotEmpty) {
            List<String> allEntries = playUrl.split('#');
            for (int i = 0; i < allEntries.length; i++) {
              String entry = allEntries[i];
              if (entry.contains('\$')) {
                List<String> entryParts = entry.split('\$');
                if (entryParts.length >= 2) {
                  String title = entryParts[0];
                  String url = entryParts[1];
                  episodes.add(Episode(title: title, url: url));
                }
              }
            }
          }

          // 创建VideoItem
          final videoItem = VideoItem(
            id: videoData['vod_id']?.toString() ?? '',
            name: videoData['vod_name'] ?? '',
            coverUrl: videoData['vod_pic'] ?? '',
            info: videoData['vod_remarks'] ?? '',
            type: videoData['type_name'] ?? '',
            last: videoData['vod_time'] ?? '',
            // 使用第一集作为默认播放地址
            playUrl: episodes.isNotEmpty ? episodes[0].url : null,
            siteKey: siteKey,
            needDetail: false,
            description: videoData['vod_content'] ?? '',
            episodes: episodes,
          );

          // 添加到缓存
          CacheService.addDetail(cacheKey, videoItem);

          return videoItem;
        }
      }
    } catch (e) {
      print('获取极速源详情失败: $e');
    }

    return null;
  }
}
