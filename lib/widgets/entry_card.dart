import 'dart:io';
import 'package:flutter/material.dart';
import '../core/install_manager.dart';
import '../core/source.dart';

/// AppEntry 卡片（真实源条目）：图标/名称/简介/来源/版本/已装
class EntryCard extends StatelessWidget {
  final AppEntry app;
  final VoidCallback onTap;
  const EntryCard({super.key, required this.app, required this.onTap});

  Widget _icon(BuildContext context, double size) {
    final scheme = Theme.of(context).colorScheme;
    final Widget inner;
    if (app.iconPath.isNotEmpty) {
      inner = ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.27),
        child: Image.file(File(app.iconPath), width: size, height: size, fit: BoxFit.cover, errorBuilder: (_, _, _) => Icon(Icons.apps_rounded, size: size * 0.5, color: scheme.primary)),
      );
    } else {
      inner = Icon(Icons.apps_rounded, size: size * 0.5, color: scheme.primary);
    }
    return Container(
      width: size, height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: scheme.primary.withValues(alpha: .1), borderRadius: BorderRadius.circular(size * 0.27)),
      child: inner,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _icon(context, 44),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(app.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('${app.category.isEmpty ? '其他' : app.category} · ${app.source} 源', style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
                ]),
              ),
              if (app.installed)
                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: scheme.tertiaryContainer, borderRadius: BorderRadius.circular(6)), child: Text('已安装', style: TextStyle(fontSize: 10, color: scheme.onTertiaryContainer))),
            ]),
            const SizedBox(height: 10),
            Text(app.summary.isEmpty ? '暂无简介' : app.summary, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, height: 1.4, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Row(children: [
              Chip(label: Text('版本 ${app.version.isEmpty ? '未知' : app.version}', style: const TextStyle(fontSize: 10)), visualDensity: VisualDensity.compact, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, padding: EdgeInsets.zero, backgroundColor: scheme.surfaceContainerHigh),
              const Spacer(),
              if (app.sizeBytes > 0) Text(_fmtSize(app.sizeBytes), style: TextStyle(fontSize: 10.5, color: scheme.onSurfaceVariant)),
            ]),
          ]),
        ),
      ),
    );
  }

  static String _fmtSize(int b) {
    if (b >= 1073741824) return '${(b / 1073741824).toStringAsFixed(1)} GB';
    if (b >= 1048576) return '${(b / 1048576).toStringAsFixed(0)} MB';
    if (b >= 1024) return '${(b / 1024).toStringAsFixed(0)} KB';
    return '$b B';
  }
}

/// AppEntry 详情底部弹窗：简介 + 来源 + 版本 + 安装（真实入队）
void showEntryDetail(BuildContext context, AppEntry app, InstallState installs) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _EntryDetailSheet(app: app, installs: installs),
  );
}

class _EntryDetailSheet extends StatefulWidget {
  final AppEntry app;
  final InstallState installs;
  const _EntryDetailSheet({required this.app, required this.installs});
  @override
  State<_EntryDetailSheet> createState() => _EntryDetailSheetState();
}

class _EntryDetailSheetState extends State<_EntryDetailSheet> {
  bool _submitting = false;

  void _install() {
    setState(() => _submitting = true);
    Navigator.pop(context);
    widget.installs.enqueue(widget.app);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('已加入安装队列：${widget.app.name}（${widget.app.source} 源）'),
      action: SnackBarAction(label: '查看进度', onPressed: () {}),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final app = widget.app;
    return SafeArea(
      child: Container(
        height: 520,
        decoration: BoxDecoration(color: scheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 10), decoration: BoxDecoration(color: scheme.outlineVariant, borderRadius: BorderRadius.circular(2))),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(width: 64, height: 64, alignment: Alignment.center, decoration: BoxDecoration(color: scheme.primary.withValues(alpha: .1), borderRadius: BorderRadius.circular(16)), child: app.iconPath.isNotEmpty
                      ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(app.iconPath), width: 52, height: 52, fit: BoxFit.cover, errorBuilder: (_, _, _) => Icon(Icons.apps_rounded, color: scheme.primary)))
                      : Icon(Icons.apps_rounded, size: 30, color: scheme.primary)),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(app.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('${app.source} 源 · 版本 ${app.version.isEmpty ? '未知' : app.version} · ${app.category.isEmpty ? '其他' : app.category}', style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant)),
                  ])),
                ]),
                const SizedBox(height: 16),
                const Text('简介', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(app.summary.isEmpty ? '暂无简介（后续自动翻译）' : app.summary, style: TextStyle(fontSize: 13, height: 1.5, color: scheme.onSurfaceVariant)),
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
                Row(children: [
                  const Text('来源', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  Chip(label: Text(app.source, style: const TextStyle(fontSize: 11)), visualDensity: VisualDensity.compact, backgroundColor: scheme.primaryContainer),
                  if (app.installed) ...[
                    const SizedBox(width: 8),
                    Chip(label: const Text('已安装', style: TextStyle(fontSize: 11)), visualDensity: VisualDensity.compact, backgroundColor: scheme.tertiaryContainer),
                  ],
                ]),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
            child: SizedBox(width: double.infinity, child: FilledButton.icon(
              onPressed: _submitting || app.installed ? null : _install,
              icon: const Icon(Icons.download_rounded, size: 18),
              label: Text(app.installed ? '已安装' : '安装（${app.source} 源 · ${app.version.isEmpty ? '最新' : app.version}）'),
            )),
          ),
        ]),
      ),
    );
  }
}
