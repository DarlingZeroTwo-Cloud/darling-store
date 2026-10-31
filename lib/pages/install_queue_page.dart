import 'dart:async';
import 'package:flutter/material.dart';

/// 正在安装：下载队列（并行）→ 安装队列（串行，apt 锁），逐项进度
class InstallQueuePage extends StatefulWidget {
  const InstallQueuePage({super.key});
  @override
  State<InstallQueuePage> createState() => _InstallQueuePageState();
}

class _InstallQueuePageState extends State<InstallQueuePage> {
  final List<Map<String, dynamic>> _items = [
    {'name': '微信', 'source': 'spark', 'stage': '安装中', 'progress': 0.72, 'icon': '💬'},
    {'name': 'WPS Office', 'source': 'spark', 'stage': '下载中', 'progress': 0.41, 'icon': '📄'},
    {'name': '钉钉', 'source': 'spark', 'stage': '排队中', 'progress': 0.0, 'icon': '📌'},
  ];
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(milliseconds: 900), (_) {
      if (!mounted) return;
      setState(() {
        for (final it in _items) {
          if (it['stage'] == '排队中') continue;
          final p = (it['progress'] as double) + 0.02;
          if (p >= 1) {
            it['progress'] = 1.0;
            it['stage'] = '已完成';
          } else {
            it['progress'] = p;
          }
        }
        // 队列推进：完成/下载完 → 下一项进安装
        for (var i = 1; i < _items.length; i++) {
          if (_items[i]['stage'] == '排队中' && _items[i - 1]['stage'] == '已完成') {
            _items[i]['stage'] = '下载中';
          } else if (_items[i]['stage'] == '下载中' && _items[i - 1]['stage'] == '已完成') {
            _items[i]['stage'] = '安装中';
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final done = _items.where((x) => x['stage'] == '已完成').length;
    return ListView(padding: const EdgeInsets.fromLTRB(22, 18, 22, 24), children: [
      Row(children: [
        const Text('正在安装', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const Spacer(),
        Text('$done/${_items.length} 完成', style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant)),
      ]),
      const SizedBox(height: 4),
      Text('先下载全部 → 再排队安装（apt 同一时间只能装一个）', style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant)),
      const SizedBox(height: 14),
      for (final it in _items)
        Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(it['icon'], style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(child: Text('${it['name']}（${it['source']} 源）', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: it['stage'] == '已完成'
                        ? scheme.tertiaryContainer
                        : it['stage'] == '排队中'
                            ? scheme.surfaceContainerHigh
                            : scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${it['stage']}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: it['stage'] == '已完成' ? scheme.onTertiaryContainer : scheme.onPrimaryContainer)),
                ),
              ]),
              const SizedBox(height: 10),
              if (it['stage'] == '排队中')
                Text('等待前面任务完成…', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant))
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(value: it['progress'], minHeight: 7),
                ),
            ]),
          ),
        ),
    ]);
  }
}
