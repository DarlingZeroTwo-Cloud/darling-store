import 'dart:io';

/// 发行版检测：Darling OS 已转向 Arch Linux，需同时兼容 Ubuntu/Debian
class Distro {
  static final Distro instance = Distro();
  String? _id;
  bool _checked = false;

  String get id {
    if (!_checked) {
      _checked = true;
      try {
        final f = File('/etc/os-release');
        if (f.existsSync()) {
          for (final l in f.readAsLinesSync()) {
            if (l.startsWith('ID=')) {
              _id = l.substring(3).trim().replaceAll('"', '');
              break;
            }
          }
        }
      } catch (_) {}
      _id ??= 'unknown';
    }
    return _id!;
  }

  /// 是否 Arch 系（arch/manjaro/endeavouros 等）
  bool get isArch => id == 'arch' || id == 'manjaro' || id == 'endeavouros' || id == 'archarm';

  /// 是否 Debian 系（ubuntu/debian）
  bool get isDebian => id == 'ubuntu' || id == 'debian' || id == 'linuxmint' || id == 'pop';

  /// 主包管理器名（apt / pacman）
  String get pkgManager => isArch ? 'pacman' : 'apt';
}
