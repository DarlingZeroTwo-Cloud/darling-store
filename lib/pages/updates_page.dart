import 'package:flutter/material.dart';
import '../data/mock_data.dart';

/// 更新中心：聚合所有可更新应用 + 一键更新 + 立即刷新源
class UpdatesPage extends StatefulWidget {
  const UpdatesPage({super.key});
  @override
  State<UpdatesPage> createState() => _UpdatesPageState();
}

class _UpdatesPageState extends State<UpdatesPage> {
  bool _refreshing = false;

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _refreshing = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('源已刷新，应用版本已是最新')));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final upd = kMockInstalled.where((a) => a.hasUpdate).toList();
    return ListView(padding: const EdgeInsets.fromLTRB(22, 18, 22, 24), children: [
      Row(children: [
        const Text('更新中心', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const Spacer(),
        FilledButton.tonalIcon(
          onPressed: _refreshing ? null : _refresh,
          icon: _refreshing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.refresh_rounded, size: 18),
          label: Text(_refreshing ? '刷新中…' : '立即刷新'),
        ),
      ]),
      const SizedBox(height: 4),
      Text(upd.isEmpty ? '所有应用都是最新版本' : '发现 ${upd.length} 个应用可更新（实时比对各源最新版）', style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant)),
      const SizedBox(height: 14),
      if (upd.isEmpty)
        Container(
          height: 120, alignment: Alignment.center,
          decoration: BoxDecoration(color: scheme.surfaceContainerHigh.withValues(alpha: .5), borderRadius: BorderRadius.circular(16)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.task_alt_rounded, color: scheme.primary, size: 30),
            const SizedBox(height: 8),
            Text('一切最新', style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
          ]),
        )
      else
        for (final a in upd)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: Container(width: 42, height: 42, alignment: Alignment.center, decoration: BoxDecoration(color: scheme.primary.withValues(alpha: .1), borderRadius: BorderRadius.circular(12)), child: Text(a.icon, style: const TextStyle(fontSize: 20))),
              title: Text(a.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              subtitle: Text('检测到新版本，来自各源实时比对', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
              trailing: FilledButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已加入更新队列：${a.name}'))),
                child: const Text('更新'),
              ),
            ),
          ),
    ]);
  }
}
