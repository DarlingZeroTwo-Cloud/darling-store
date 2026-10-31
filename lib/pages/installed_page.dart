import 'package:flutter/material.dart';
import '../data/mock_data.dart';

/// 已安装：系统应用（不可卸载）+ 普通应用（卸载/更新），右上转圈入口见侧边栏
class InstalledPage extends StatelessWidget {
  const InstalledPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(padding: const EdgeInsets.fromLTRB(22, 18, 22, 24), children: [
      const Text('已安装应用', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      Text('共 ${kMockInstalled.length} 个 · 系统应用不可卸载', style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant)),
      const SizedBox(height: 14),
      for (final a in kMockInstalled)
        Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: Container(width: 42, height: 42, alignment: Alignment.center, decoration: BoxDecoration(color: scheme.primary.withValues(alpha: .1), borderRadius: BorderRadius.circular(12)), child: Text(a.icon, style: const TextStyle(fontSize: 20))),
            title: Text(a.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            subtitle: Text(a.summary, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            trailing: a.system
                ? Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: scheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(8)), child: Text('系统应用', style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)))
                : Row(mainAxisSize: MainAxisSize.min, children: [
                    if (a.hasUpdate)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilledButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已加入更新队列：${a.name}'))), child: const Text('更新')),
                      ),
                    OutlinedButton(
                      onPressed: () => showDialog(context: context, builder: (ctx) => AlertDialog(
                        title: Text('卸载 ${a.name}？'),
                        content: const Text('将移除该应用及其用户数据。'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
                          FilledButton(onPressed: () { Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已卸载：${a.name}'))); }, child: const Text('卸载')),
                        ],
                      )),
                      child: const Text('卸载'),
                    ),
                  ]),
          ),
        ),
    ]);
  }
}
