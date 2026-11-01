import 'dart:io';

/// AppStream 本地元数据：从系统 app-info XML（gnome-software 数据）解析
/// 应用截图（远程 URL）与英文描述，供详情页展示。
class AppInfoParser {
  static final AppInfoParser instance = AppInfoParser();

  final Map<String, List<String>> _screenshots = {};
  final Map<String, String> _descriptions = {};
  bool _loaded = false;

  void _ensureLoaded() {
    if (_loaded) return;
    _loaded = true;
    for (final dir in ['/usr/share/app-info/xmls', '/var/lib/app-info/xmls']) {
      try {
        final d = Directory(dir);
        if (!d.existsSync()) continue;
        for (final f in d.listSync().whereType<File>().where((e) => e.path.endsWith('.xml.gz') || e.path.endsWith('.xml'))) {
          _parse(f);
        }
      } catch (_) {}
    }
  }

  void _parse(File f) {
    try {
      final raw = f.path.endsWith('.gz') ? _gunzip(f) : f.readAsStringSync();
      final lines = raw.split('\n');
      String currentPkg = '';
      for (var i = 0; i < lines.length; i++) {
        final l = lines[i];
        final pkg = RegExp(r'<pkgname>([^<]+)</pkgname>').firstMatch(l);
        if (pkg != null) {
          currentPkg = pkg.group(1)!.toLowerCase();
          continue;
        }
        if (currentPkg.isEmpty) continue;
        final sc = RegExp(r'<screenshot[^>]*>\s*<image[^>]*>([^<]+)</image>').firstMatch(l);
        if (sc != null) {
          _screenshots.putIfAbsent(currentPkg, () => []).add(sc.group(1)!.trim());
        }
        final desc = RegExp(r'<description>\s*<p>([^<]+)</p>').firstMatch(l);
        if (desc != null) {
          _descriptions.putIfAbsent(currentPkg, () => desc.group(1)!.trim());
        }
      }
    } catch (_) {}
  }

  String _gunzip(File f) {
    try {
      final p = Process.runSync('gzip', ['-dc', f.path]);
      if (p.exitCode == 0) return p.stdout as String;
    } catch (_) {}
    return '';
  }

  /// 按包名/应用名取截图 URL 列表
  List<String> screenshotsFor(String package, {String? flatpakId}) {
    _ensureLoaded();
    if (flatpakId != null) {
      final hit = _screenshots[flatpakId.toLowerCase()];
      if (hit != null && hit.isNotEmpty) return hit;
    }
    return _screenshots[package.toLowerCase()] ?? [];
  }

  /// 按包名取英文描述（供翻译）
  String descriptionFor(String package) {
    _ensureLoaded();
    return _descriptions[package.toLowerCase()] ?? '';
  }
}
