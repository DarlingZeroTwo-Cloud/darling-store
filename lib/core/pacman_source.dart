import 'dart:io';
import 'source.dart';
import 'distro.dart';

/// Arch Linux 源（pacman 包管理器）
/// listApps: pacman -Sl（仓库包列表，秒回）；搜索/详情：pacman -Si
class PacmanSource implements SourceAdapter {
  @override
  String get id => 'pacman';
  @override
  String get displayName => 'Arch 官方源';
  @override
  bool get available => Distro.instance.isArch && _which('pacman').isNotEmpty;

  String _which(String name) {
    try {
      final r = Process.runSync('which', [name]);
      if (r.exitCode == 0) return (r.stdout as String).trim();
    } catch (_) {}
    return '';
  }

  final _cache = JsonCache('pacman');
  static const _repos = ['core', 'extra', 'multilib'];

  @override
  Future<List<AppEntry>> listApps() async {
    if (!available) return [];
    final cached = _cache.read();
    if (cached.isNotEmpty) return cached.map(AppEntry.fromJson).toList();
    // pacman -Sl：`core linux 6.6.1-1`，无描述（描述走 -Si 按需查）
    final out = await runCmd('pacman', ['-Sl'] + _repos);
    final installed = await _installedSet();
    final apps = <AppEntry>[];
    for (final line in out.split('\n')) {
      final p = line.trim().split(RegExp(r'\s+'));
      if (p.length < 3) continue;
      final name = p[1];
      apps.add(AppEntry(
        id: name, source: id, name: name,
        summary: p[0], // 暂存仓库名，详情时 -Si 补充
        version: p[2], category: _catFor(p[0]),
        installed: installed.contains(name),
      ));
    }
    _cache.write(apps.map((e) => e.toJson()).toList());
    return apps;
  }

  Future<Set<String>> _installedSet() async {
    try {
      final out = await runCmd('pacman', ['-Qq']);
      return out.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
    } catch (_) {
      return {};
    }
  }

  String _catFor(String repo) => switch (repo) {
        'core' => '核心', 'extra' => '扩展', 'multilib' => '多库', _ => '其他',
      };

  @override
  Future<List<AppEntry>> search(String query) async {
    final all = await listApps();
    if (query.trim().isEmpty) return all;
    final q = query.toLowerCase();
    final hits = all.where((a) => a.name.toLowerCase().contains(q)).toList();
    // pacman -Ss 补充模糊匹配（含描述）
    if (hits.length < 8) {
      try {
        final out = await runCmd('pacman', ['-Ss', q]);
        for (final line in out.split('\n')) {
          final m = RegExp(r'^(core|extra|multilib)/([\w.+-]+)\s+([\w.:~-]+)\s*(.*)$').firstMatch(line.trim());
          if (m != null && !hits.any((h) => h.name == m.group(2))) {
            hits.add(AppEntry(
              id: m.group(2)!, source: id, name: m.group(2)!,
              summary: m.group(4) ?? '', version: m.group(3)!,
              category: _catFor(m.group(1)!), installed: (await _installedSet()).contains(m.group(2)),
            ));
          }
        }
      } catch (_) {}
    }
    return hits;
  }

  @override
  Future<String> latestVersion(String id) async {
    try {
      final out = await runCmd('pacman', ['-Si', id]);
      for (final l in out.split('\n')) {
        if (l.startsWith('版本') || l.startsWith('Version')) {
          return l.split(':').last.trim();
        }
      }
    } catch (_) {}
    return '';
  }

  @override
  Future<bool> install(AppEntry app, {void Function(String stage)? onStage}) async {
    if (!available) return false;
    onStage?.call('pacman 安装（需授权）');
    final r = await Process.run('pkexec', ['pacman', '-S', '--noconfirm', '--needed', app.id]);
    onStage?.call(r.exitCode == 0 ? '完成' : '失败');
    return r.exitCode == 0;
  }
}
