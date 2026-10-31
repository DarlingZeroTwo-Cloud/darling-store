import 'dart:io';
import 'source.dart';

/// 星火应用商店源（spk/apm 格式）
/// 需系统安装 spk 工具（星火应用商店）。未安装时 available=false，由 UI 置灰。
class SparkSource implements SourceAdapter {
  @override
  String get id => 'spark';
  @override
  String get displayName => '星火应用商店';
  @override
  bool get available =>
      File('/usr/bin/spk').existsSync() ||
      File('/opt/durapps/spark-store/bin/spark-store').existsSync() ||
      _which('spark-store').isNotEmpty;

  String _which(String name) {
    try {
      final r = Process.runSync('which', [name]);
      if (r.exitCode == 0) return (r.stdout as String).trim();
    } catch (_) {}
    return '';
  }

  final _cache = JsonCache('spark');

  @override
  Future<List<AppEntry>> listApps() async {
    if (!available) return [];
    final cached = _cache.read();
    if (cached.isNotEmpty) return cached.map(AppEntry.fromJson).toList();
    // spk 仓库列表：优先 ll/spk 命令行；无则返回空（等待星火镜像接入）
    final out = await runCmd('spk', ['list']);
    final apps = <AppEntry>[];
    for (final line in out.split('\n')) {
      final p = line.split('\t');
      if (p.length < 2) continue;
      apps.add(AppEntry(
        id: p[0], source: id, name: p.length > 1 && p[1].isNotEmpty ? p[1] : p[0],
        summary: p.length > 2 ? p[2] : '', category: '其他', version: p.length > 3 ? p[3] : '',
      ));
    }
    _cache.write(apps.map((e) => e.toJson()).toList());
    return apps;
  }

  @override
  Future<List<AppEntry>> search(String query) async {
    final all = await listApps();
    if (query.trim().isEmpty) return all;
    final q = query.toLowerCase();
    return all.where((a) => a.name.toLowerCase().contains(q) || a.summary.toLowerCase().contains(q)).toList();
  }

  @override
  Future<String> latestVersion(String id) async => '';

  @override
  Future<bool> install(AppEntry app, {void Function(String stage)? onStage}) async {
    if (!available) return false;
    onStage?.call('星火安装中');
    final r = await Process.run('pkexec', ['spk', '-i', app.id]);
    onStage?.call(r.exitCode == 0 ? '完成' : '失败');
    return r.exitCode == 0;
  }
}

/// 玲珑源（ll-cli 命令）
class LinglongSource implements SourceAdapter {
  @override
  String get id => 'linglong';
  @override
  String get displayName => '玲珑应用';
  @override
  bool get available => File('/usr/bin/ll-cli').existsSync() || _which('ll-cli').isNotEmpty;

  String _which(String name) {
    try {
      final r = Process.runSync('which', [name]);
      if (r.exitCode == 0) return (r.stdout as String).trim();
    } catch (_) {}
    return '';
  }

  final _cache = JsonCache('linglong');

  @override
  Future<List<AppEntry>> listApps() async {
    if (!available) return [];
    final cached = _cache.read();
    if (cached.isNotEmpty) return cached.map(AppEntry.fromJson).toList();
    final out = await runCmd('ll-cli', ['list']);
    final apps = <AppEntry>[];
    for (final line in out.split('\n')) {
      final p = line.split('\t');
      if (p.length < 2) continue;
      apps.add(AppEntry(
        id: p[0], source: id, name: p.length > 1 && p[1].isNotEmpty ? p[1] : p[0],
        summary: p.length > 2 ? p[2] : '', category: '其他', version: p.length > 3 ? p[3] : '',
      ));
    }
    _cache.write(apps.map((e) => e.toJson()).toList());
    return apps;
  }

  @override
  Future<List<AppEntry>> search(String query) async {
    final all = await listApps();
    if (query.trim().isEmpty) return all;
    final q = query.toLowerCase();
    return all.where((a) => a.name.toLowerCase().contains(q) || a.summary.toLowerCase().contains(q)).toList();
  }

  @override
  Future<String> latestVersion(String id) async => '';

  @override
  Future<bool> install(AppEntry app, {void Function(String stage)? onStage}) async {
    if (!available) return false;
    onStage?.call('玲珑安装中');
    final r = await Process.run('ll-cli', ['install', app.id]);
    onStage?.call(r.exitCode == 0 ? '完成' : '失败');
    return r.exitCode == 0;
  }
}
