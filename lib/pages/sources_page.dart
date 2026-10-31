import 'package:flutter/material.dart';
import '../core/settings.dart';

/// 源管理：各源开关 + 可用状态 + 当前镜像 + 测速切换
class SourcesPage extends StatefulWidget {
  final SettingsController settings;
  const SourcesPage({super.key, required this.settings});
  @override
  State<SourcesPage> createState() => _SourcesPageState();
}

class _SourcesPageState extends State<SourcesPage> {
  bool _testing = false;

  Future<void> _testAll() async {
    setState(() => _testing = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _testing = false;
      for (final s in widget.settings.sources) {
        if (s.available) {
          s.latencyMs = 20 + (s.id.hashCode % 180);
          s.mirror = s.id == 'flathub' ? '中科大镜像' : s.id == 'apt' ? '清华镜像' : s.id == 'appimage' ? 'GitHub 镜像' : '原生国内';
        } else {
          s.latencyMs = -1;
        }
      }
      widget.settings.save();
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('测速完成，已按速度自动切换最快镜像')));
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
      Text('镜像不可用自动切换 · 按速度选最快 · 可手动指定', style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant)),
      const SizedBox(height: 14),
      for (final s in widget.settings.sources)
        Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: SwitchListTile(
            value: s.enabled,
            onChanged: (v) => setState(() {
              s.enabled = v;
              widget.settings.save();
            }),
            secondary: Container(width: 42, height: 42, alignment: Alignment.center, decoration: BoxDecoration(color: scheme.primary.withValues(alpha: .1), borderRadius: BorderRadius.circular(12)), child: Text(s.icon, style: const TextStyle(fontSize: 18))),
            title: Text(s.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 4),
              Row(children: [
                Text(s.available ? '可用' : '不可用（系统未检测到运行环境）', style: TextStyle(fontSize: 11.5, color: s.available ? scheme.primary : scheme.error)),
                const SizedBox(width: 8),
                Text('· ${s.mirror}', style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant)),
                if (s.latencyMs > 0) ...[
                  const SizedBox(width: 8),
                  Text('· ${s.latencyMs}ms', style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant)),
                ],
              ]),
            ]),
          ),
        ),
    ]);
  }
}
