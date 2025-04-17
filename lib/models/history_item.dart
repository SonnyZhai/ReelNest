import 'video_item.dart';

class HistoryItem {
  final String id;
  final String name;
  final String playUrl;
  final String time; // 观看时间字符串

  HistoryItem({
    required this.id,
    required this.name,
    required this.playUrl,
    required this.time,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      playUrl: json['playUrl'] ?? '',
      time: json['time'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'playUrl': playUrl,
    'time': time,
  };

  VideoItem toVideoItem() {
    return VideoItem(
      id: id,
      name: name,
      playUrl: playUrl,
      coverUrl: '', // 历史中通常不存封面
    );
  }
}
