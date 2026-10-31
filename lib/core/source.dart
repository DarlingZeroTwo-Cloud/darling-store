import 'dart:convert';
import 'dart:io';

/// 统一应用条目（来自任意源）
class AppEntry {
  final String id; // 源内唯一
  final String source; // apt / flathub / spark / linglong / appimage
  final String name;
  final String summary;
  final String iconPath; // 空 = 用默认
  final String category;
  final String version;
  final int sizeBytes;
  final bool installed;
  const AppEntry({
    required this.id,
    required this.source,
    required this.name,
    this.summary = '',
    this.iconPath = '',
    this.category = '',
    this.version = '',
    this.sizeBytes = 0,
    this.installed = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id, 'source': source, 'name': name, 'summary': summary,
        'iconPath': iconPath, 'category': category, 'version': version,
        'sizeBytes': sizeBytes, 'installed': installed,
      };

  factory AppEntry.fromJson(Map<String, dynamic> j) => AppEntry(
        id: j['id'] ?? '',
        source: j['source'] ?? '',
        name: j['name'] ?? '',
        summary: j['summary'] ?? '',
        iconPath: j['iconPath'] ?? '',
        category: j['category'] ?? '',
        version: j['version'] ?? '',
        sizeBytes: j['sizeBytes'] ?? 0,
        installed: j['installed'] ?? false,
      );
}

/// 源适配器统一接口
abstract class SourceAdapter {
  String get id;
  String get displayName;
  bool get available;
  Future<List<AppEntry>> listApps();
  Future<List<AppEntry>> search(String query);
  Future<String> latestVersion(String id);
  Future<bool> install(AppEntry app, {void Function(String stage)? onStage});
}

/// 简易 JSON 文件缓存
class JsonCache {
  final String name;
  JsonCache(this.name);
  String get _dir => '${Platform.environment['HOME']}/.cache/darling-store';
  String get _file => '$_dir/$name.json';

  List<Map<String, dynamic>> read() {
    try {
      final f = File(_file);
      if (!f.existsSync()) return [];
      final d = jsonDecode(f.readAsStringSync());
      return (d is List) ? d.cast<Map<String, dynamic>>() : [];
    } catch (_) {
      return [];
    }
  }

  void write(List<Map<String, dynamic>> data) {
    try {
      Directory(_dir).createSync(recursive: true);
      File(_file).writeAsStringSync(jsonEncode(data));
    } catch (_) {}
  }
}

/// 运行命令（不抛异常，返回 stdout 或空串；自带超时，超时杀进程）
Future<String> runCmd(String cmd, List<String> args, {Duration timeout = const Duration(seconds: 25)}) async {
  try {
    final p = await Process.start(cmd, args);
    final outF = p.stdout.transform(utf8.decoder).join();
    final errF = p.stderr.transform(utf8.decoder).join();
    final code = await p.exitCode.timeout(timeout, onTimeout: () {
      p.kill();
      return -1;
    });
    if (code == 0) return (await outF).trim();
    await errF;
  } catch (_) {}
  return '';
}
