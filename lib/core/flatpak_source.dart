import 'dart:io';
import 'source.dart';

/// Flatpak / Flathub 源：flatpak CLI（未安装时 available=false）
class FlatpakSource implements SourceAdapter {
  @override
  String get id => 'flathub';
  @override
  String get displayName => 'Flatpak / Flathub';
  @override
  bool get available => File('/usr/bin/flatpak').existsSync();

  final _cache = JsonCache('flathub');

  /// 系统级失败自动回退用户级（容器/无 root 场景）
  Future<List<String>> _remotes({bool user = false}) async {
    final args = user ? ['--user', 'remotes', '--columns=name'] : ['remotes', '--columns=name'];
    final out = await runCmd('flatpak', args);
    if (out.isEmpty && !user) return _remotes(user: true);
    return out.split('\n').where((l) => l.trim().isNotEmpty).toList();
  }

  @override
  Future<List<AppEntry>> listApps() async {
    final cached = _cache.read();
    if (cached.isNotEmpty) return cached.map(AppEntry.fromJson).toList();
    final remotes = await _remotes();
    final apps = <AppEntry>[];
    for (final remote in remotes) {
      var out = await runCmd('flatpak', ['remote-ls', remote, '--columns=application,version,name,description']);
      if (out.isEmpty) out = await runCmd('flatpak', ['--user', 'remote-ls', remote, '--columns=application,version,name,description']);
      for (final line in out.split('\n')) {
        final parts = line.split('\t');
        if (parts.length < 2 || !parts[0].contains('.')) continue;
        apps.add(AppEntry(
          id: parts[0], source: id, name: parts.length > 2 && parts[2].isNotEmpty ? parts[2] : parts[0],
          summary: parts.length > 3 ? parts[3] : '',
          version: parts.length > 1 ? parts[1] : '',
          category: _catOf(parts[0]),
          sizeBytes: int.tryParse(parts.length > 4 ? parts[4].trim() : '') ?? 0,
          installed: await _isInstalled(parts[0]),
        ));
      }
    }
    _cache.write(apps.map((e) => e.toJson()).toList());
    return apps;
  }

  String _catOf(String appId) {
    final l = appId.toLowerCase();
    if (l.contains('org.mozilla') || l.contains('browser')) return '浏览器';
    if (l.contains('chat') || l.contains('telegram') || l.contains('element') || l.contains('discord')) return '社交';
    if (l.contains('code') || l.contains('ide') || l.contains('studio') || l.contains('git')) return '开发工具';
    if (l.contains('game') || l.contains('steam') || l.contains('lutris')) return '游戏';
    if (l.contains('music') || l.contains('audio') || l.contains('spotify')) return '影音';
    if (l.contains('video') || l.contains('player') || l.contains('vlc')) return '影音';
    if (l.contains('office') || l.contains('writer') || l.contains('libre')) return '办公';
    if (l.contains('note') || l.contains('obsidian') || l.contains('task')) return '效率';
    if (l.contains('editor') || l.contains('photo') || l.contains('gimp') || l.contains('paint')) return '图形';
    return '其他';
  }

  Future<bool> _isInstalled(String appId) async {
    final out = await runCmd('flatpak', ['info', appId]);
    return out.isNotEmpty;
  }

  @override
  Future<List<AppEntry>> search(String query) async {
    // 走缓存快照本地过滤（秒回），避免远程 appstream 首次拉取超时
    final all = await listApps();
    if (query.trim().isEmpty) return all;
    final q = query.toLowerCase();
    return all.where((a) =>
        a.name.toLowerCase().contains(q) ||
        a.id.toLowerCase().contains(q) ||
        a.summary.toLowerCase().contains(q)).toList();
  }

  @override
  Future<String> latestVersion(String id) async {
    final out = await runCmd('flatpak', ['info', id]);
    for (final l in out.split('\n')) {
      if (l.startsWith('Version:')) return l.substring(8).trim();
    }
    return '';
  }

  @override
  Future<bool> install(AppEntry app, {void Function(String stage)? onStage}) async {
    onStage?.call('准备运行时');
    // flatpak 用户级安装，无需 root
    onStage?.call('下载并安装');
    var r = await Process.run('flatpak', ['install', '-y', 'flathub', app.id]);
    if (r.exitCode != 0) r = await Process.run('flatpak', ['--user', 'install', '-y', 'flathub', app.id]);
    onStage?.call(r.exitCode == 0 ? '完成' : '失败');
    return r.exitCode == 0;
  }
}
