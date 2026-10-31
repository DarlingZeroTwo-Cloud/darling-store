import 'package:flutter/material.dart';
import '../core/install_manager.dart';

/// 正在安装：真实安装队列（先下载 → 串行安装），进度实时
class InstallQueuePage extends StatelessWidget {
  final InstallState installs;
  const InstallQueuePage({super.key, required this.installs});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: installs,
      builder: (ctx, _) {
        if (installs.items.isEmpty) {
          return Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.download_done_rounded, size: 40, color: scheme.primary),
              const SizedBox(height: 10),
              Text('没有正在安装的任务', style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
              const SizedBox(height: 4),
              Text('从应用详情点击「安装」后，任务会出现在这里', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            ]),
          );
        }
        return ListView(padding: const EdgeInsets.fromLTRB(22, 18, 22, 24), children: [
          Row(children: [
            const Text('正在安装', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const Spacer(),
            Text('${installs.doneCount}/${installs.total} 完成', style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant)),
          ]),
          const SizedBox(height: 4),
          Text('先下载全部 → 再排队安装（apt 同一时间只能装一个）', style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant)),
          const SizedBox(height: 14),
          for (final it in installs.items)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(it.stage == InstallStage.done ? Icons.check_circle_rounded : Icons.apps_rounded, size: 18, color: it.stage == InstallStage.done ? scheme.tertiary : scheme.primary),
                    const SizedBox(width: 10),
                    Expanded(child: Text('${it.app.name}（${it.app.source} 源）', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: it.stage == InstallStage.done
                            ? scheme.tertiaryContainer
                            : it.stage == InstallStage.queued
                                ? scheme.surfaceContainerHigh
                                : it.stage == InstallStage.failed
                                    ? scheme.errorContainer
                                    : scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(it.stageName, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: it.stage == InstallStage.failed ? scheme.onErrorContainer : scheme.onPrimaryContainer)),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  if (it.stage == InstallStage.queued)
                    Text(it.detail, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant))
                  else if (it.stage == InstallStage.done || it.stage == InstallStage.failed)
                    Text(it.detail, style: TextStyle(fontSize: 12, color: it.stage == InstallStage.failed ? scheme.error : scheme.onSurfaceVariant))
                  else
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(value: it.progress, minHeight: 7),
                    ),
                ]),
              ),
            ),
        ]);
      },
    );
  }
}
