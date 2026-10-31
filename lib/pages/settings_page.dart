import 'package:flutter/material.dart';
import '../core/settings.dart';

/// 设置页：通用 / 下载与安装 / 源与镜像 / 界面 / 关于 全分组
class SettingsPage extends StatelessWidget {
  final SettingsController settings;
  const SettingsPage({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = settings;
    return ListenableBuilder(
      listenable: s,
      builder: (ctx, _) => ListView(padding: const EdgeInsets.fromLTRB(22, 18, 22, 24), children: [
        const Text('设置', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        _Group(title: '通用', children: [
          ListTile(
            leading: const Icon(Icons.language_rounded),
            title: const Text('语言'),
            subtitle: Text(_langName(s.lang), style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            trailing: DropdownButton<LangChoice>(
              value: s.lang,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: LangChoice.followSystem, child: Text('跟随系统')),
                DropdownMenuItem(value: LangChoice.zh, child: Text('简体中文')),
                DropdownMenuItem(value: LangChoice.en, child: Text('English')),
              ],
              onChanged: (v) => s.set(null, v),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_rounded),
            title: const Text('安装完成通知'),
            value: s.notifyOnDone,
            onChanged: (v) => s.toggleNotify(v),
          ),
        ]),
        _Group(title: '下载与安装', children: [
          ListTile(
            leading: const Icon(Icons.downloading_rounded),
            title: const Text('并行下载数'),
            trailing: DropdownButton<int>(
              value: s.maxParallelDownloads,
              underline: const SizedBox.shrink(),
              items: [for (final n in [1, 2, 3, 4]) DropdownMenuItem(value: n, child: Text('$n 个'))],
              onChanged: (v) => s.setParallel(v ?? 3),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.extension_rounded),
            title: const Text('自动补全依赖'),
            subtitle: const Text('安装时自动解析并安装缺少的依赖与运行时'),
            value: s.autoInstallDeps,
            onChanged: (v) => s.toggleDeps(v),
          ),
          ListTile(
            leading: const Icon(Icons.folder_open_rounded),
            title: const Text('AppImage 保存目录'),
            subtitle: Text(s.appImageDir, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            trailing: const Icon(Icons.chevron_right_rounded, size: 18),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('目录选择即将支持'))),
          ),
        ]),
        _Group(title: '源与镜像', children: [
          SwitchListTile(
            secondary: const Icon(Icons.bolt_rounded),
            title: const Text('按速度自动切换镜像'),
            subtitle: const Text('镜像不可用自动换下一个，选最快的'),
            value: s.autoMirror,
            onChanged: (v) => s.toggleMirror(v),
          ),
          ListTile(
            leading: const Icon(Icons.cloud_sync_rounded),
            title: const Text('源自动刷新间隔'),
            trailing: DropdownButton<String>(
              value: '6 小时',
              underline: const SizedBox.shrink(),
              items: const ['1 小时', '6 小时', '12 小时', '每天'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (_) {},
            ),
          ),
        ]),
        _Group(title: '界面', children: [
          ListTile(
            leading: const Icon(Icons.dark_mode_rounded),
            title: const Text('主题'),
            trailing: DropdownButton<ThemeModeChoice>(
              value: s.themeMode,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: ThemeModeChoice.system, child: Text('跟随系统')),
                DropdownMenuItem(value: ThemeModeChoice.light, child: Text('浅色')),
                DropdownMenuItem(value: ThemeModeChoice.dark, child: Text('深色')),
              ],
              onChanged: (v) => s.set(v, null),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.image_rounded),
            title: const Text('显示应用截图'),
            value: s.showScreenshots,
            onChanged: (v) => s.toggleScreenshots(v),
          ),
        ]),
        _Group(title: '关于', children: [
          const ListTile(
            leading: Icon(Icons.storefront_rounded),
            title: Text('Darling Store'),
            subtitle: Text('v0.1.0 · 聚合 APT / Flatpak / 星火 / 玲珑 / AppImage'),
          ),
        ]),
        const SizedBox(height: 8),
      ]),
    );
  }

  String _langName(LangChoice l) => switch (l) {
        LangChoice.followSystem => '跟随系统',
        LangChoice.zh => '简体中文',
        LangChoice.en => 'English',
      };
}

class _Group extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Group({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(left: 4, bottom: 6), child: Text(title, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: scheme.primary))),
        Card(child: Column(children: [for (var i = 0; i < children.length; i++) ...[
          children[i],
          if (i != children.length - 1) Divider(height: 1, indent: 56, color: scheme.outlineVariant.withValues(alpha: .4)),
        ]])),
      ]),
    );
  }
}
