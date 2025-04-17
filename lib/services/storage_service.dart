import 'package:shared_preferences/shared_preferences.dart';
import '../models/history_item.dart';

class StorageService {
  static const _keySelectedApi = 'selectedApi';
  static const _keyAdultMode = 'adultMode';
  static const _keyHistory = 'history';
  static const String _aggregatedSearchKey = 'aggregated_search_enabled';


  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    // 初始化聚合搜索状态
    if (!prefs.containsKey(_aggregatedSearchKey)) {
      await prefs.setBool(_aggregatedSearchKey, false);
    }
    // 初始化成人模式状态
    if (!prefs.containsKey(_keyAdultMode)) {
      await prefs.setBool(_keyAdultMode, false);
    }
    // 初始化观看历史
    if (!prefs.containsKey(_keyHistory)) {
      await prefs.setStringList(_keyHistory, []);
    }
    // 初始化选中的API
    if (!prefs.containsKey(_keySelectedApi)) {
      await prefs.setString(_keySelectedApi, '');
    }
  }

  // 选中的API
  static Future<String?> getSelectedApi() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySelectedApi);
  }

  static Future<void> setSelectedApi(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySelectedApi, key);
  }

  // 成人模式
  static Future<bool> getAdultMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAdultMode) ?? false;
  }

  static Future<void> setAdultMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAdultMode, value);
  }

  // 观看历史
  static Future<List<HistoryItem>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyHistory) ?? [];
    return list
        .map(
          (e) => HistoryItem.fromJson(
            Map<String, dynamic>.from(
              e.isNotEmpty
                  ? Map<String, dynamic>.from(Uri.splitQueryString(e))
                  : {},
            ),
          ),
        )
        .toList();
  }

  static Future<void> addHistory(HistoryItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyHistory) ?? [];
    final jsonStr = Uri(queryParameters: item.toJson()).query;
    // 保证唯一性，移除旧的
    list.removeWhere((e) => e.contains('id=${item.id}'));
    list.insert(0, jsonStr);
    // 最多保存50条
    while (list.length > 50) {
      list.removeLast();
    }
    await prefs.setStringList(_keyHistory, list);
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyHistory);
  }

  static Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  /// 获取聚合搜索状态
  static Future<bool> getAggregatedSearchEnabled() async {
    final prefs = await _getPrefs();
    // 默认开启聚合搜索
    return prefs.getBool(_aggregatedSearchKey) ?? false;
  }

  /// 设置聚合搜索状态
  static Future<void> setAggregatedSearchEnabled(bool enabled) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_aggregatedSearchKey, enabled);
  }
}
