import 'dart:io';
import 'package:flutter/material.dart';
import '../core/source.dart';
import '../core/source_manager.dart';

/// 已安装：真实已装应用（apt + flatpak），更新/卸载入口
class InstalledPage extends StatefulWidget {
  const InstalledPage({super.key});
  @override
  State<InstalledPage> createState() => _InstalledPageState();
}

class _InstalledPageState extends State<InstalledPage> {
  late Future<List<AppEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = SourceManager.instance.installedApps();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FutureBuilder<List<AppEntry>>(
      future: _future,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = snap.data ?? [];
        return ListView(padding: const EdgeInsets.fromLTRB(22, 18, 22, 24), children: [
          Row(children: [
            const Text('已安装应用', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const Spacer(),
            IconButton(
              tooltip: '刷新',
              onPressed: () => setState(() => _future = SourceManager.instance.installedApps()),
              icon: const Icon(Icons.refresh_rounded, size: 20),
            ),
          ]),
          const SizedBox(height: 4),
          Text(list.isEmpty ? '还没有通过商店安装的应用' : '共 ${list.length} 个 · 系统关键包请在终端谨慎卸载', style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant)),
          const SizedBox(height: 14),
          for (final a in list)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: Container(width: 42, height: 42, alignment: Alignment.center, decoration: BoxDecoration(color: scheme.primary.withValues(alpha: .1), borderRadius: BorderRadius.circular(12)), child: a.iconPath.isNotEmpty
                    ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(a.iconPath), width: 32, height: 32, fit: BoxFit.cover, errorBuilder: (_, _, _) => const Icon(Icons.apps_rounded)))
                    : const Icon(Icons.apps_rounded)),
                title: Text(a.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                subtitle: Text('${a.source} 源 · ${a.version.isEmpty ? '未知版本' : '版本 ${a.version}'} · ${a.summary.isEmpty ? '无简介' : a.summary}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  OutlinedButton(
                    onPressed: () => showDialog(context: context, builder: (dctx) => AlertDialog(
                      title: Text('卸载 ${a.name}？'),
                      content: const Text('将移除该应用。系统关键包卸载可能导致系统异常。'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(dctx), child: const Text('取消')),
                        FilledButton(onPressed: () { Navigator.pop(dctx); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('卸载需要系统授权，将在终端完成'))); }, child: const Text('卸载')),
                      ],
                    )),
                    child: const Text('卸载'),
                  ),
                ]),
              ),
            ),
        ]);
      },
    );
  }
}
