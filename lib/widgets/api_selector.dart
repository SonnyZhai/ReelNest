import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../models/api_site.dart';
import '../services/storage_service.dart';

class ApiSelector extends StatefulWidget {
  final bool adultMode;
  const ApiSelector({super.key, required this.adultMode});

  @override
  State<ApiSelector> createState() => _ApiSelectorState();
}

class _ApiSelectorState extends State<ApiSelector> {
  late List<ApiSite> _filteredApis;
  ApiSite? _selectedApi;

  @override
  void initState() {
    super.initState();
    _filterAndLoadApis();
  }

  @override
  void didUpdateWidget(covariant ApiSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.adultMode != widget.adultMode) {
      _filterAndLoadApis();
    }
  }

  void _filterAndLoadApis() {
    _filteredApis =
        apiSites.where((site) => site.adult == widget.adultMode).toList();
    _loadSelectedApi();
  }

  Future<void> _loadSelectedApi() async {
    final savedKey = await StorageService.getSelectedApi();
    ApiSite? newlySelected;

    if (_filteredApis.isNotEmpty) {
      // 尝试在过滤后的列表中找到保存的 key
      try {
        newlySelected = _filteredApis.firstWhere((api) => api.key == savedKey);
      } catch (e) {
        // 如果找不到，则选择过滤后列表的第一个
        newlySelected = _filteredApis.first;
      }
    } else {
      // 如果过滤后列表为空，则没有可选的
      newlySelected = null;
    }

    // 检查当前 _selectedApi 是否仍然在新的过滤列表中
    // 如果不在，则强制更新为 newlySelected (可能是第一个，也可能是 null)
    if (_selectedApi != null &&
        !_filteredApis.any((api) => api.key == _selectedApi!.key)) {
      // 这种情况通常发生在 adultMode 切换后
      // newlySelected 此时已经是正确的默认值（第一个或 null）
    }

    // 仅当选择发生变化时更新状态和存储
    if (newlySelected?.key != _selectedApi?.key) {
      setState(() {
        _selectedApi = newlySelected;
      });
      if (newlySelected != null) {
        await StorageService.setSelectedApi(newlySelected.key);
      } else {
        // 可选：如果没选中，清空存储
        // await StorageService.setSelectedApi('');
      }
    } else if (_selectedApi == null && newlySelected != null) {
      // 处理初始加载，_selectedApi 从 null 变为有值
      setState(() {
        _selectedApi = newlySelected;
      });
    }
  }

  Future<void> _onApiChanged(ApiSite? api) async {
    if (api == null) return;
    await StorageService.setSelectedApi(api.key);
    setState(() {
      _selectedApi = api;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_filteredApis.isEmpty) {
      return const Padding(
        // 添加一些边距
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Center(
          child: Text('当前模式下无可用数据源', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    // 改进加载状态判断：仅当列表不为空但 _selectedApi 仍为 null 时显示加载指示器
    if (_selectedApi == null && _filteredApis.isNotEmpty) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    return DropdownButtonFormField<ApiSite>(
      value: _selectedApi,
      items:
          _filteredApis
              .map((api) => DropdownMenuItem(value: api, child: Text(api.name)))
              .toList(),
      onChanged: _onApiChanged,
      decoration: const InputDecoration(
        labelText: '当前数据源',
        border: OutlineInputBorder(),
      ),
      // 添加校验，确保选中的值在列表中
      validator: (value) {
        if (value == null && _filteredApis.isNotEmpty) {
          return '请选择一个数据源';
        }
        return null;
      },
    );
  }
}
