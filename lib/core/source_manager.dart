import 'dart:io';
import 'appimage_source.dart';
import 'apt_source.dart';
import 'flatpak_source.dart';
import 'source.dart';
import 'spark_linglong_source.dart';

/// 聚合源管理器：多源搜索/列表/已装/刷新
class SourceManager {
  final List<SourceAdapter> sources = [
    AptSource(),
    FlatpakSource(),
    SparkSource(),
    LinglongSource(),
    AppImageSource(),
  ];

  static final SourceManager instance = SourceManager();

  List<SourceAdapter> get availableSources => sources.where((s) => s.available).toList();

  /// 全源搜索（按名称去重，同应用保留多源）
  Future<List<AppEntry>> searchAll(String query) async {
    final results = <AppEntry>[];
    final seen = <String>{};
    for (final s in availableSources) {
      final apps = query.trim().isEmpty ? await s.listApps() : await s.search(query);
      for (final a in apps) {
        final key = a.name.toLowerCase();
        if (seen.add(key)) results.add(a);
      }
    }
    return results;
  }

  /// 已安装列表（来自 apt + flatpak）
  Future<List<AppEntry>> installedApps() async {
    final all = await searchAll('');
    return all.where((a) => a.installed).toList();
  }

  /// 清空缓存强制刷新
  void clearCache() {
    for (final s in sources) {
      try {
        File('${Platform.environment['HOME']}/.cache/darling-store/${s.id}.json').deleteSync();
      } catch (_) {}
    }
  }
}
