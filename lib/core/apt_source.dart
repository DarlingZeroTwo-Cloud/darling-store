import 'dart:io';
import 'source.dart';

/// APT 源：apt-cache 查询 + dpkg 已装状态 + 系统图标
class AptSource implements SourceAdapter {
  @override
  String get id => 'apt';
  @override
  String get displayName => 'APT 官方源';
  @override
  bool get available => File('/usr/bin/apt-cache').existsSync();

  final _cache = JsonCache('apt');

  static const _categories = <String, String>{
    'games': '游戏', 'science': '教育', 'editors': '开发工具', 'utils': '系统工具',
    'web': '浏览器', 'net': '网络', 'graphics': '图形', 'sound': '影音',
    'video': '影音', 'office': '办公', 'comm': '社交', 'mail': '效率',
    'libs': '开发工具', 'python': '开发工具', 'javascript': '开发工具',
    'devel': '开发工具', 'x11': '系统工具', 'admin': '系统工具', 'misc': '其他',
  };

  @override
  Future<List<AppEntry>> listApps() async {
    final cached = _cache.read();
    if (cached.isNotEmpty) return cached.map(AppEntry.fromJson).toList();
    final out = await runCmd('apt-cache', ['search', '.', '--names-only']);
    final names = out.split('\n').where((l) => l.trim().isNotEmpty).take(300).toList();
    final list = <AppEntry>[];
    for (final line in names) {
      final name = line.split(' - ').first.trim();
      if (name.isEmpty) continue;
      final app = await _detail(name);
      if (app != null) list.add(app);
    }
    _cache.write(list.map((e) => e.toJson()).toList());
    return list;
  }

  Future<AppEntry?> _detail(String pkg) async {
    final show = await runCmd('apt-cache', ['show', pkg]);
    if (show.isEmpty) return null;
    final lines = show.split('\n');
    String summary = '', category = '', version = '', section = '';
    int size = 0;
    for (final l in lines) {
      if (l.startsWith('Description: ')) { summary = l.substring(13); }
      else if (l.startsWith('Version: ')) { version = l.substring(9); }
      else if (l.startsWith('Section: ')) { section = l.substring(9); }
      else if (l.startsWith('Installed-Size: ')) { size = int.tryParse(l.substring(16)) ?? 0; }
    }
    category = _categories[section] ?? '其他';
    return AppEntry(
      id: pkg, source: id, name: pkg, summary: summary, version: version,
      category: category, sizeBytes: size * 1024,
      iconPath: await _findIcon(pkg), installed: await _isInstalled(pkg),
    );
  }

  Future<bool> _isInstalled(String pkg) async {
    final r = await runCmd('dpkg-query', ['-W', '-f=\${db:Status-Status}', pkg]);
    return r.contains('installed');
  }

  Future<String> _findIcon(String pkg) async {
    const iconDirs = [
      '/usr/share/icons/hicolor/48x48/apps',
      '/usr/share/icons/hicolor/64x64/apps',
      '/usr/share/icons/hicolor/scalable/apps',
      '/usr/share/pixmaps',
    ];
    for (final dir in iconDirs) {
      for (final ext in ['png', 'svg', 'xpm']) {
        final f = File('$dir/$pkg.$ext');
        if (f.existsSync()) return f.path;
        // 部分包图标带版本后缀，模糊匹配
      }
      try {
        final d = Directory(dir);
        if (d.existsSync()) {
          final hit = d.listSync().where((e) => e.path.contains(pkg) && (e.path.endsWith('.png') || e.path.endsWith('.svg'))).toList();
          if (hit.isNotEmpty) return hit.first.path;
        }
      } catch (_) {}
    }
    return '';
  }

  @override
  Future<List<AppEntry>> search(String query) async {
    if (query.trim().isEmpty) return listApps();
    final out = await runCmd('apt-cache', ['search', query]);
    final names = out.split('\n').where((l) => l.trim().isNotEmpty).take(50).toList();
    final list = <AppEntry>[];
    for (final line in names) {
      final name = line.split(' - ').first.trim();
      if (name.isEmpty) continue;
      final app = await _detail(name);
      if (app != null) list.add(app);
    }
    return list;
  }

  @override
  Future<String> latestVersion(String id) async => (await _detail(id))?.version ?? '';

  @override
  Future<bool> install(AppEntry app, {void Function(String stage)? onStage}) async {
    onStage?.call('解析依赖');
    if (app.id.isEmpty) return false;
    // 用 pkexec 提权安装（polkit 弹系统密码框）
    onStage?.call('安装中');
    final r = await Process.run('pkexec', ['apt-get', 'install', '-y', app.id]);
    onStage?.call(r.exitCode == 0 ? '完成' : '失败');
    return r.exitCode == 0;
  }
}
