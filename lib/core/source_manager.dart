import 'dart:io';
import 'appimage_source.dart';
import 'apt_source.dart';
import 'distro.dart';
import 'flatpak_source.dart';
import 'pacman_source.dart';
import 'source.dart';
import 'spark_linglong_source.dart';

/// 聚合源管理器：多源搜索/列表/已装/刷新
class SourceManager {
  /// 按发行版动态选主包管理器源（Arch→pacman，Debian 系→apt）
  final List<SourceAdapter> sources = Distro.instance.isArch
      ? [PacmanSource(), FlatpakSource(), SparkSource(), LinglongSource(), AppImageSource()]
      : [AptSource(), FlatpakSource(), SparkSource(), LinglongSource(), AppImageSource()];

  static final SourceManager instance = SourceManager();

  List<SourceAdapter> get availableSources => sources.where((s) => s.available).toList();

  /// 全源搜索（按名称去重，同应用保留多源；支持多关键词合并）
  Future<List<AppEntry>> searchAll(List<String> queries) async {
    if (queries.isEmpty) queries = [''];
    final results = <AppEntry>[];
    final seen = <String>{};
    for (final q in queries) {
      for (final s in availableSources) {
        final apps = q.trim().isEmpty ? await s.listApps() : await s.search(q);
        for (final a in apps) {
          final key = a.name.toLowerCase();
          if (seen.add(key)) results.add(a);
        }
      }
    }
    return results;
  }

  /// 已安装列表（来自 apt + flatpak）
  Future<List<AppEntry>> installedApps() async {
    final all = await searchAll(['']);
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
