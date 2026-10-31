import 'package:flutter/material.dart';
import '../data/mock_data.dart';

/// 应用卡片（详情弹窗：简介/版本/多源下载/截图占位）
class AppCard extends StatelessWidget {
  final StoreApp app;
  final VoidCallback onTap;
  const AppCard({super.key, required this.app, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 44, height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: scheme.primary.withValues(alpha: .1), borderRadius: BorderRadius.circular(12)),
                  child: Text(app.icon, style: const TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(app.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(app.category, style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
                  ]),
                ),
                if (app.hasUpdate)
                  Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: scheme.tertiaryContainer, borderRadius: BorderRadius.circular(6)), child: Text('可更新', style: TextStyle(fontSize: 10, color: scheme.onTertiaryContainer))),
              ]),
              const SizedBox(height: 10),
              Text(app.summary, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, height: 1.4, color: scheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              Wrap(spacing: 4, runSpacing: 4, children: app.versions.keys.map((s) => Chip(
                label: Text('$s ${app.versions[s]}', style: const TextStyle(fontSize: 10)),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: EdgeInsets.zero,
                backgroundColor: scheme.surfaceContainerHigh,
              )).toList()),
            ],
          ),
        ),
      ),
    );
  }
}

/// 应用详情底部弹窗：多源下载选项 + 截图区 + 简介
void showAppDetail(BuildContext context, StoreApp app) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _AppDetailSheet(app: app),
  );
}

class _AppDetailSheet extends StatefulWidget {
  final StoreApp app;
  const _AppDetailSheet({required this.app});
  @override
  State<_AppDetailSheet> createState() => _AppDetailSheetState();
}

class _AppDetailSheetState extends State<_AppDetailSheet> {
  String? _selSource;
  String _autoPick() {
    const order = ['apt', 'flathub', 'spark', 'linglong', 'appimage'];
    for (final s in order) {
      if (widget.app.versions.containsKey(s)) return s;
    }
    return widget.app.versions.keys.first;
  }

  @override
  void initState() {
    super.initState();
    _selSource = _autoPick();
  }

  void _install() {
    final v = widget.app.versions[_selSource];
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('已加入下载队列：${widget.app.name}（$_selSource $v）'),
      action: SnackBarAction(label: '查看', onPressed: () {}),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final app = widget.app;
    return SafeArea(
      child: Container(
        height: 560,
        decoration: BoxDecoration(color: scheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 10), decoration: BoxDecoration(color: scheme.outlineVariant, borderRadius: BorderRadius.circular(2))),
          Expanded(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(22, 12, 22, 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 64, height: 64, alignment: Alignment.center, decoration: BoxDecoration(color: scheme.primary.withValues(alpha: .1), borderRadius: BorderRadius.circular(16)), child: Text(app.icon, style: const TextStyle(fontSize: 32))),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(app.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('${app.category} · ${app.versions.length} 个来源', style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant)),
              ])),
            ]),
            const SizedBox(height: 16),
            const Text('简介', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(app.summary, style: TextStyle(fontSize: 13, height: 1.5, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            const Text('截图', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Container(
              height: 120,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: scheme.surfaceContainerHigh),
              alignment: Alignment.center,
              child: Text('暂无截图', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            ),
            const SizedBox(height: 16),
            const Text('选择安装来源', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            RadioGroup<String>(
              groupValue: _selSource,
              onChanged: (v) => setState(() => _selSource = v),
              child: Column(children: [
                for (final e in app.versions.entries)
                  RadioListTile<String>(
                    value: e.key,
                    title: Text('${e.key} 源', style: const TextStyle(fontSize: 13.5)),
                    subtitle: Text('最新版本 ${e.value}', style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant)),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
              ]),
            ),
          ]))),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
            child: SizedBox(width: double.infinity, child: FilledButton.icon(
              onPressed: _install,
              icon: const Icon(Icons.download_rounded, size: 18),
              label: Text('安装（自动选择 $_selSource 源）'),
            )),
          ),
        ]),
      ),
    );
  }
}
