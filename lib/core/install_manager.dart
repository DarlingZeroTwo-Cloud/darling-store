import 'package:flutter/foundation.dart';
import 'dart:io';
import 'appimage_source.dart';
import 'apt_source.dart';
import 'source.dart';
import 'source_manager.dart';

/// 队列任务阶段
enum InstallStage { queued, downloading, installing, done, failed }

/// 单个队列任务
class QueueItem {
  final AppEntry app;
  InstallStage stage;
  double progress; // 0-1
  String detail;
  QueueItem(this.app, {this.stage = InstallStage.queued, this.progress = 0, this.detail = '排队中'});

  String get stageName => switch (stage) {
        InstallStage.queued => '排队中',
        InstallStage.downloading => '下载中',
        InstallStage.installing => '安装中',
        InstallStage.done => '已完成',
        InstallStage.failed => '失败',
      };
}

/// 安装队列状态（UI 监听）
class InstallState extends ChangeNotifier {
  final List<QueueItem> items = [];
  bool get active => items.any((i) => i.stage == InstallStage.downloading || i.stage == InstallStage.installing || i.stage == InstallStage.queued);
  int get doneCount => items.where((i) => i.stage == InstallStage.done).length;
  int get total => items.length;

  /// 本地导入：按后缀路由（deb→dpkg / appimage→注册 / flatpak→bundle）
  Future<QueueItem> importLocal(String path) async {
    final name = path.split('/').last;
    final item = QueueItem(AppEntry(id: name, source: 'local', name: name, summary: '本地导入', category: '本地导入'), stage: InstallStage.queued);
    items.add(item);
    notifyListeners();
    if (path.endsWith('.AppImage') || path.endsWith('.appimage')) {
      item.stage = InstallStage.installing;
      item.detail = '注册 AppImage';
      notifyListeners();
      final app = await AppImageSource().importLocal(path);
      item.stage = app != null ? InstallStage.done : InstallStage.failed;
      item.detail = app != null ? '已导入' : '导入失败';
      notifyListeners();
      return item;
    }
    if (path.endsWith('.deb')) {
      item.stage = InstallStage.installing;
      item.detail = 'dpkg 安装（需授权）';
      notifyListeners();
      final r = await Process.run('pkexec', ['dpkg', '-i', path]);
      item.stage = r.exitCode == 0 ? InstallStage.done : InstallStage.failed;
      item.detail = r.exitCode == 0 ? '已完成' : '安装失败';
      notifyListeners();
      return item;
    }
    if (path.endsWith('.flatpak') || path.endsWith('.flatpakref')) {
      item.stage = InstallStage.installing;
      item.detail = 'flatpak bundle 安装';
      notifyListeners();
      var r = await Process.run('flatpak', ['install', '-y', path]);
      if (r.exitCode != 0) r = await Process.run('flatpak', ['--user', 'install', '-y', path]);
      item.stage = r.exitCode == 0 ? InstallStage.done : InstallStage.failed;
      item.detail = r.exitCode == 0 ? '已完成' : '安装失败';
      notifyListeners();
      return item;
    }
    item.stage = InstallStage.failed;
    item.detail = '不支持的文件格式';
    notifyListeners();
    return item;
  }

  /// 加入队列：下载阶段（伪进度推进）→ 串行安装
  Future<void> enqueue(AppEntry app, {int maxParallel = 3}) async {
    final item = QueueItem(app);
    items.add(item);
    notifyListeners();
    final adapter = SourceManager.instance.sources.firstWhere((s) => s.id == app.source, orElse: () => AptSource());
    if (!adapter.available) {
      item.stage = InstallStage.failed;
      item.detail = '源不可用';
      notifyListeners();
      return;
    }
    // 下载阶段（Flatpak/apt 各自负责真实下载，这里驱动阶段显示）
    item.stage = InstallStage.downloading;
    for (double p = 0.05; p < 1.0; p += 0.15) {
      await Future.delayed(const Duration(milliseconds: 260));
      if (item.stage == InstallStage.failed) return;
      item.progress = p.clamp(0.0, 0.95);
      item.detail = '下载中 ${(item.progress * 100).toStringAsFixed(0)}%';
      notifyListeners();
    }
    item.progress = 1.0;
    item.detail = '等待安装';
    // 串行安装（apt 锁：同一时间只能装一个）
    while (items.any((o) => o != item && o.stage == InstallStage.installing)) {
      await Future.delayed(const Duration(milliseconds: 500));
    }
    item.stage = InstallStage.installing;
    item.detail = '安装中';
    notifyListeners();
    final ok = await adapter.install(app, onStage: (s) {
      item.detail = s;
      notifyListeners();
    });
    item.stage = ok ? InstallStage.done : InstallStage.failed;
    item.progress = ok ? 1.0 : 0.0;
    item.detail = ok ? '已完成' : '安装失败';
    notifyListeners();
  }
}
