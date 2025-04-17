import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../widgets/api_selector.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _adultMode = false;
  bool _aggregatedSearchEnabled = true; // 新增状态

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final adult = await StorageService.getAdultMode();
    final aggregated =
        await StorageService.getAggregatedSearchEnabled(); // 加载聚合设置
    setState(() {
      _adultMode = adult;
      _aggregatedSearchEnabled = aggregated;
    });
  }

  Future<void> _toggleAdultMode(bool value) async {
    await StorageService.setAdultMode(value);
    setState(() {
      _adultMode = value;
    });
  }

  // 新增：切换聚合搜索状态
  Future<void> _toggleAggregatedSearch(bool value) async {
    await StorageService.setAggregatedSearchEnabled(value);
    setState(() {
      _aggregatedSearchEnabled = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            '搜索设置',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SwitchListTile(
            title: const Text('启用聚合搜索'),
            value: _aggregatedSearchEnabled,
            onChanged: _toggleAggregatedSearch,
            subtitle: const Text('开启后将同时搜索所有可用数据源'),
          ),
          // 当聚合搜索关闭时，才显示单源选择器
          if (!_aggregatedSearchEnabled) ...[
            const SizedBox(height: 16),
            const Text(
              '数据源选择 (单源模式)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ApiSelector(key: ValueKey(_adultMode), adultMode: _adultMode),
          ],
          const Divider(height: 32),
          const Text(
            '内容偏好',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SwitchListTile(
            title: const Text('开启成人模式'),
            value: _adultMode,
            onChanged: _toggleAdultMode,
            subtitle: const Text('仅搜索和显示成人内容源'),
          ),
        ],
      ),
    );
  }
}
