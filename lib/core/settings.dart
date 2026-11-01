import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'distro.dart';

/// 主题模式
enum ThemeModeChoice { system, light, dark }

/// 语言
enum LangChoice { followSystem, zh, en }

/// 单个软件源
class SourceInfo {
  final String id;
  final String name;
  String icon; // emoji/svg 标识
  bool enabled;
  bool available; // 系统探测是否可用
  String mirror;
  int latencyMs;
  SourceInfo({required this.id, required this.name, required this.icon, this.enabled = true, this.available = true, this.mirror = '自动', this.latencyMs = -1});
}

/// 全局设置（持久化到 ~/.config/darling-store/settings.json）
class SettingsController extends ChangeNotifier {
  static const _file = '.config/darling-store/settings.json';

  ThemeModeChoice themeMode = ThemeModeChoice.system;
  LangChoice lang = LangChoice.followSystem;
  int maxParallelDownloads = 3;
  bool autoMirror = true; // 按速度自动切换镜像
  bool autoInstallDeps = true; // 自动补全依赖
  bool showScreenshots = true;
  bool notifyOnDone = true;
  String appImageDir = '~/Downloads/AppImage';

  /// 按发行版生成（Arch→pacman，Debian 系→apt）
  final List<SourceInfo> sources = Distro.instance.isArch
      ? [
          SourceInfo(id: 'pacman', name: 'Arch 官方源', icon: '🔷', mirror: '国内镜像'),
          SourceInfo(id: 'flathub', name: 'Flatpak / Flathub', icon: '🟦', mirror: '中科大镜像'),
          SourceInfo(id: 'spark', name: '星火应用商店', icon: '🔥', mirror: '原生国内'),
          SourceInfo(id: 'linglong', name: '玲珑应用商店', icon: '💎', mirror: '原生国内', available: false),
          SourceInfo(id: 'appimage', name: 'AppImage 目录', icon: '🖼️', mirror: 'GitHub 镜像'),
        ]
      : [
          SourceInfo(id: 'apt', name: 'APT 官方源', icon: '🟧', mirror: '清华镜像'),
          SourceInfo(id: 'flathub', name: 'Flatpak / Flathub', icon: '🟦', mirror: '中科大镜像'),
          SourceInfo(id: 'spark', name: '星火应用商店', icon: '🔥', mirror: '原生国内'),
          SourceInfo(id: 'linglong', name: '玲珑应用商店', icon: '💎', mirror: '原生国内', available: false),
          SourceInfo(id: 'appimage', name: 'AppImage 目录', icon: '🖼️', mirror: 'GitHub 镜像'),
        ];

  static Future<SettingsController> load() async {
    final c = SettingsController();
    try {
      final f = File('${Platform.environment['HOME']}/$_file');
      if (f.existsSync()) {
        final j = jsonDecode(f.readAsStringSync());
        c.themeMode = ThemeModeChoice.values.byName(j['themeMode'] ?? 'system');
        c.lang = LangChoice.values.byName(j['lang'] ?? 'followSystem');
        c.maxParallelDownloads = j['maxParallelDownloads'] ?? 3;
        c.autoMirror = j['autoMirror'] ?? true;
        c.autoInstallDeps = j['autoInstallDeps'] ?? true;
        c.showScreenshots = j['showScreenshots'] ?? true;
        c.notifyOnDone = j['notifyOnDone'] ?? true;
        c.appImageDir = j['appImageDir'] ?? '~/Downloads/AppImage';
        final srcs = j['sources'] as List?;
        if (srcs != null) {
          for (final s in srcs) {
            final m = s as Map<String, dynamic>;
            final idx = c.sources.indexWhere((x) => x.id == m['id']);
            if (idx >= 0) c.sources[idx].enabled = m['enabled'] ?? true;
          }
        }
      }
    } catch (_) {}
    return c;
  }

  Future<void> save() async {
    try {
      final dir = File('${Platform.environment['HOME']}/.config/darling-store');
      dir.createSync(recursive: true);
      File('${Platform.environment['HOME']}/$_file').writeAsStringSync(jsonEncode({
        'themeMode': themeMode.name,
        'lang': lang.name,
        'maxParallelDownloads': maxParallelDownloads,
        'autoMirror': autoMirror,
        'autoInstallDeps': autoInstallDeps,
        'showScreenshots': showScreenshots,
        'notifyOnDone': notifyOnDone,
        'appImageDir': appImageDir,
        'sources': sources.map((s) => {'id': s.id, 'enabled': s.enabled}).toList(),
      }));
    } catch (_) {}
  }

  void set(ThemeModeChoice? tm, LangChoice? lg) {
    if (tm != null) themeMode = tm;
    if (lg != null) lang = lg;
    save();
    notifyListeners();
  }

  void toggleNotify(bool v) { notifyOnDone = v; save(); notifyListeners(); }
  void setParallel(int n) { maxParallelDownloads = n; save(); notifyListeners(); }
  void toggleDeps(bool v) { autoInstallDeps = v; save(); notifyListeners(); }
  void toggleMirror(bool v) { autoMirror = v; save(); notifyListeners(); }
  void toggleScreenshots(bool v) { showScreenshots = v; save(); notifyListeners(); }
}
