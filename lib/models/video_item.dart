class VideoItem {
  final String id;
  final String name;
  final String? playUrl; // 可空，因为搜索结果中可能没有
  final String coverUrl;
  final String? info;
  final String? type;
  final String? last; // 更新时间
  final String? siteKey; // 添加站点标识，用于后续获取详情
  final bool needDetail; // 标记是否需要获取详情
  // 多集视频
  final List<Episode> episodes; // 集数列表
  final int currentEpisode; // 当前选中的集数索引
  final String? description; // 描述

  VideoItem({
    required this.id,
    required this.name,
    this.playUrl,
    required this.coverUrl,
    this.info,
    this.type,
    this.last,
    this.siteKey,
    this.needDetail = false,
    this.episodes = const [],
    this.currentEpisode = 0,
    this.description,
  });

  factory VideoItem.fromJson(Map<String, dynamic> json, {String? siteName}) {
    // 解析播放地址
    String? playUrl;
    List<Episode> episodes = [];
    // 添加解析剧情描述
    String? description = json['vod_content'] ?? json['vod_blurb'];

    if (json.containsKey('vod_play_url') &&
        json['vod_play_url'] != null &&
        json['vod_play_url'].toString().isNotEmpty) {
      final raw = json['vod_play_url'].toString();

      // 解析多集视频格式: "第1集$http://url1#第2集$http://url2"
      final rawEpisodes = raw.split('#');

      if (rawEpisodes.isNotEmpty) {
        // 处理每一集
        for (int i = 0; i < rawEpisodes.length; i++) {
          final parts = rawEpisodes[i].split('\$');
          if (parts.length > 1) {
            final title = parts[0].trim();
            final url = parts[1].trim();
            episodes.add(Episode(title: title, url: url));
          }
        }

        // 第一集作为默认播放地址
        playUrl = episodes.isNotEmpty ? episodes[0].url : null;
      }
    }

    // 判断是否需要后续获取详情
    bool needDetail =
        (playUrl == null || playUrl.isEmpty) ||
        (json['vod_pic'] == null || json['vod_pic'].toString().isEmpty);

    return VideoItem(
      id: json['vod_id']?.toString() ?? '0',
      name: json['vod_name'] ?? '未知',
      playUrl: playUrl,
      coverUrl: json['vod_pic']?.toString() ?? '',
      info: json['vod_remarks'] ?? '',
      type: json['type_name'] ?? '未知分类',
      last: json['vod_time'] ?? '',
      siteKey: siteName, // 记录站点标识
      needDetail: needDetail, // 标记是否需要获取详情
      episodes: episodes, // 保存所有集数
      description: description, // 添加描述
    );
  }

  // 创建新的实例但更改当前集数
  VideoItem copyWith({int? currentEpisode}) {
    return VideoItem(
      id: id,
      name: name,
      playUrl:
          currentEpisode != null &&
                  episodes.isNotEmpty &&
                  currentEpisode < episodes.length
              ? episodes[currentEpisode].url
              : playUrl,
      coverUrl: coverUrl,
      info: info,
      type: type,
      last: last,
      siteKey: siteKey,
      needDetail: needDetail,
      episodes: episodes,
      currentEpisode: currentEpisode ?? this.currentEpisode,
      description: description,
    );
  }
}

// 新增集数类
class Episode {
  final String title; // 集数标题，如"第1集"
  final String url; // 播放地址

  Episode({required this.title, required this.url});
}
