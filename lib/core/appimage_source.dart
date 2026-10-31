import 'dart:convert';
import 'dart:io';
import 'source.dart';
import 'mirror_manager.dart';

/// AppImage 源：内置实测清单 + 本地导入注册
/// 安装：GitHub 镜像池测速选最快下载 → chmod +x → 注册到 ~/.local/share/darling-store/appimages/
class AppImageSource implements SourceAdapter {
  @override
  String get id => 'appimage';
  @override
  String get displayName => 'AppImage';
  @override
  bool get available => true; // 本地导入总是可用

  final _cache = JsonCache('appimage');

  /// 内置精选清单（下载地址已实测 2026-10：直连 GitHub 200）
  static const _builtin = [
    {'id': 'balena-etcher', 'name': 'balenaEtcher', 'summary': '跨平台 USB 烧录工具（写入系统镜像到 U 盘/SD 卡）', 'version': '1.19.25', 'category': '系统工具', 'url': 'https://github.com/balena-io/etcher/releases/download/v1.19.25/balenaEtcher-1.19.25-x64.AppImage'},
    {'id': 'appimagetool', 'name': 'AppImage Tool', 'summary': '将应用打包为 AppImage 的官方工具', 'version': 'continuous', 'category': '开发工具', 'url': 'https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage'},
  ];

  Directory get _storeDir => Directory('${Platform.environment['HOME']}/.local/share/darling-store/appimages');

  /// 已导入的本地 AppImage（注册表）
  List<Map<String, dynamic>> _imported() {
    try {
      final f = File('${_storeDir.path}/registry.json');
      if (!f.existsSync()) return [];
      final d = jsonDecode(f.readAsStringSync());
      return (d is List) ? d.cast<Map<String, dynamic>>() : [];
    } catch (_) {
      return [];
    }
  }

  void _saveImported(List<Map<String, dynamic>> list) {
    try {
      _storeDir.createSync(recursive: true);
      File('${_storeDir.path}/registry.json').writeAsStringSync(jsonEncode(list));
    } catch (_) {}
  }

  @override
  Future<List<AppEntry>> listApps() async {
    final cached = _cache.read();
    if (cached.isNotEmpty) return cached.map(AppEntry.fromJson).toList();
    final apps = <AppEntry>[
      for (final b in _builtin)
        AppEntry(
          id: b['id']!, source: id, name: b['name']!,
          summary: b['summary']!, version: b['version']!,
          category: b['category']!,
          installed: File('${_storeDir.path}/${b['id']}.AppImage').existsSync(),
        ),
      for (final r in _imported())
        AppEntry(
          id: r['id'] ?? r['name'], source: id, name: r['name'] ?? '本地应用',
          summary: r['summary'] ?? '本地导入的 AppImage', version: r['version'] ?? '',
          category: '本地导入', installed: true,
        ),
    ];
    _cache.write(apps.map((e) => e.toJson()).toList());
    return apps;
  }

  /// 下载地址（带镜像测速选最快前缀）
  String _resolveUrl(String id) {
    final b = _builtin.where((x) => x['id'] == id).toList();
    if (b.isEmpty) return '';
    return b.first['url'] as String;
  }

  @override
  Future<bool> install(AppEntry app, {void Function(String stage)? onStage}) async {
    final url = _resolveUrl(app.id);
    if (url.isEmpty) return false;
    onStage?.call('选择最快镜像');
    final best = await MirrorManager.instance.best('github');
    if (!best.available || best.url.isEmpty) return false;
    final realUrl = best.url == 'https://github.com' ? url : url.replaceFirst('https://github.com', best.url);
    onStage?.call('下载中（${best.name}）');
    try {
      _storeDir.createSync(recursive: true);
      final out = File('${_storeDir.path}/${app.id}.AppImage');
      final req = await HttpClient().getUrl(Uri.parse(realUrl)).timeout(const Duration(seconds: 15));
      final resp = await req.close().timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return false;
      final sink = out.openWrite();
      await resp.pipe(sink).timeout(const Duration(minutes: 15));
      await sink.close();
      await Process.run('chmod', ['+x', out.path]);
      _cache.write([]); // 强制下次刷新
      onStage?.call('完成');
      return true;
    } catch (_) {
      onStage?.call('下载失败');
      return false;
    }
  }

  /// 本地导入 AppImage：复制进商店目录并注册
  Future<AppEntry?> importLocal(String path) async {
    final f = File(path);
    if (!f.existsSync() || !path.endsWith('.AppImage') && !path.endsWith('.appimage')) return null;
    try {
      _storeDir.createSync(recursive: true);
      final name = path.split('/').last;
      final dest = File('${_storeDir.path}/$name');
      await f.copy(dest.path);
      await Process.run('chmod', ['+x', dest.path]);
      final list = _imported();
      list.add({'id': name, 'name': name.replaceAll(RegExp(r'\.AppImage$|\.appimage$', caseSensitive: false), ''), 'summary': '本地导入', 'version': ''});
      _saveImported(list);
      _cache.write([]);
      return AppEntry(id: name, source: id, name: list.last['name'] as String, summary: '本地导入', category: '本地导入', installed: true);
    } catch (_) {
      return null;
    }
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
}
