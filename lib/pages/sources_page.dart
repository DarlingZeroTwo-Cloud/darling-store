import 'package:flutter/material.dart';
import '../core/mirror_manager.dart';
import '../core/settings.dart';
import '../core/source_manager.dart';

/// 源管理：各源开关 + 真实可用状态 + 镜像池测速排序 + 一键切换
class SourcesPage extends StatefulWidget {
  final SettingsController settings;
  const SourcesPage({super.key, required this.settings});
  @override
  State<SourcesPage> createState() => _SourcesPageState();
}

class _SourcesPageState extends State<SourcesPage> {
  bool _testing = false;
  Map<String, List<MirrorEntry>> _result = {};

  Future<void> _testAll() async {
    setState(() => _testing = true);
    _result = await MirrorManager.instance.testAll();
    // 真实可用状态覆盖
    for (final s in widget.settings.sources) {
      final real = SourceManager.instance.sources.where((x) => x.id == s.id).toList();
      if (real.isNotEmpty) s.available = real.first.available;
      final pool = _result[s.id];
      if (pool != null && pool.isNotEmpty) {
        s.latencyMs = pool.first.available ? pool.first.latencyMs.round() : -1;
        s.mirror = pool.first.available ? pool.first.name : '全部不可用';
      }
    }
    widget.settings.save();
    if (!mounted) return;
    setState(() => _testing = false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(padding: const EdgeInsets.fromLTRB(22, 18, 22, 24), children: [
      Row(children: [
        const Text('源管理', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const Spacer(),
        FilledButton.tonalIcon(
          onPressed: _testing ? null : _testAll,
          icon: _testing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.speed_rounded, size: 18),
          label: Text(_testing ? '测速中…' : '全部测速'),
        ),
      ]),
      const SizedBox(height: 4),
      Text('镜像不可用自动切换 · 按速度选最快 · 结果来自真实网络测速', style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant)),
      const SizedBox(height: 14),
      for (final s in widget.settings.sources)
        Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ExpansionTile(
            leading: Container(width: 42, height: 42, alignment: Alignment.center, decoration: BoxDecoration(color: scheme.primary.withValues(alpha: .1), borderRadius: BorderRadius.circular(12)), child: Text(s.icon, style: const TextStyle(fontSize: 18))),
            title: Row(children: [
              Text(s.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              if (!s.available)
                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: scheme.errorContainer, borderRadius: BorderRadius.circular(6)), child: Text('不可用', style: TextStyle(fontSize: 10, color: scheme.onErrorContainer))),
            ]),
            subtitle: Text('当前：${s.mirror} · ${s.latencyMs > 0 ? (s.latencyMs >= 1000 ? '${(s.latencyMs / 1000).toStringAsFixed(1)}s' : '${s.latencyMs}ms') : '未测速'}', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            trailing: Switch(
              value: s.enabled,
              onChanged: (v) => setState(() {
                s.enabled = v;
                widget.settings.save();
              }),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  for (final m in (_result[s.id] ?? []))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(children: [
                        Icon(m.available ? Icons.check_circle_rounded : Icons.cancel_rounded, size: 15, color: m.available ? scheme.tertiary : scheme.error),
                        const SizedBox(width: 8),
                        Expanded(child: Text(m.name, style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant))),
                        Text(fmtLatency(m.latencyMs), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: m.available ? scheme.onSurface : scheme.error)),
                      ]),
                    ),
                  if ((_result[s.id] ?? []).isEmpty) Text('点击上方「全部测速」查看镜像池实时状态', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                ]),
              ),
            ],
          ),
        ),
    ]);
  }
}
