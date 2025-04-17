import 'dart:collection';

// 一个简单的内存缓存服务，用于缓存视频详情数据
class CacheService {
  // 视频详情缓存，键为视频ID
  static final Map<String, dynamic> _detailCache = HashMap<String, dynamic>();

  // 缓存大小限制
  static const int maxCacheSize = 100;

  // 添加详情到缓存
  static void addDetail(String videoId, dynamic detail) {
    // 如果缓存已满，移除最早添加的条目
    if (_detailCache.length >= maxCacheSize) {
      final oldestKey = _detailCache.keys.first;
      _detailCache.remove(oldestKey);
    }

    _detailCache[videoId] = detail;
  }

  // 从缓存获取详情
  static dynamic getDetail(String videoId) {
    return _detailCache[videoId];
  }

  // 检查缓存中是否有此详情
  static bool hasDetail(String videoId) {
    return _detailCache.containsKey(videoId);
  }

  // 清除缓存
  static void clearCache() {
    _detailCache.clear();
  }
}
