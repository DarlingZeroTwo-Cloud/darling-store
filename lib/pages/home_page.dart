import 'package:flutter/material.dart';
import '../core/install_manager.dart';
import '../core/source.dart';
import '../core/source_manager.dart';
import '../core/zh_index.dart';
import '../data/mock_data.dart';
import 'package:file_selector/file_selector.dart';
import '../widgets/app_card.dart';
import '../widgets/entry_card.dart';

/// 首页：真实聚合搜索（apt+flatpak，离线回退 mock）+ 分类 + 导入
class HomePage extends StatefulWidget {
  final InstallState installs;
  const HomePage({super.key, required this.installs});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _kw = '';
  String _cat = '全部';
  late Future<List<AppEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = SourceManager.instance.searchAll(['']);
  }

  void _reload() {
    setState(() => _future = SourceManager.instance.searchAll(ZhIndex.expand(_kw)));
  }

  Future<void> _importLocal() async {
    const groups = <XTypeGroup>[
      XTypeGroup(label: '应用安装包', extensions: ['deb', 'AppImage', 'appimage', 'flatpak', 'flatpakref']),
    ];
    final file = await openFile(acceptedTypeGroups: groups);
    if (file == null) return;
    await widget.installs.importLocal(file.path);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已导入：${file.path.split('/').last}，可在「正在安装」查看进度')));
  }

  List<StoreApp> get _mockList => kMockApps.where((a) =>
      (_cat == '全部' || a.category == _cat) &&
      (_kw.isEmpty || a.name.toLowerCase().contains(_kw.toLowerCase()) || a.summary.contains(_kw))).toList();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CustomScrollView(slivers: [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 8),
        sliver: SliverToBoxAdapter(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Darling 应用商店', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('聚合 APT · Flatpak · 星火 · 玲珑 · AppImage 全源应用', style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: TextField(
              onSubmitted: (_) => _reload(),
              onChanged: (v) => _kw = v.trim(),
              decoration: InputDecoration(
                hintText: '搜索应用（支持中文）…',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: IconButton(icon: const Icon(Icons.search_rounded, size: 20), onPressed: _reload),
                filled: true,
                fillColor: scheme.surfaceContainerHigh,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            )),
            const SizedBox(width: 10),
            FilledButton.tonalIcon(
              onPressed: _importLocal,
              icon: const Icon(Icons.file_open_rounded, size: 18),
              label: const Text('导入'),
            ),
          ]),
          const SizedBox(height: 14),
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
            for (final c in kMockCategories)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(c),
                  selected: _cat == c,
                  onSelected: (_) => setState(() => _cat = c),
                  labelStyle: TextStyle(fontSize: 12.5, fontWeight: _cat == c ? FontWeight.w700 : FontWeight.w400),
                ),
              ),
          ])),
        ])),
      ),
      FutureBuilder<List<AppEntry>>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator()));
          }
          if (snap.hasError || (snap.data?.isEmpty ?? true)) {
            // 离线/无源回退 mock 展示
            return _mockList.isEmpty
                ? const SliverFillRemaining(hasScrollBody: false, child: Center(child: Text('没有找到相关应用')))
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
                    sliver: SliverGrid.builder(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 300, mainAxisExtent: 158, crossAxisSpacing: 12, mainAxisSpacing: 12),
                      itemCount: _mockList.length,
                      itemBuilder: (ctx, i) => AppCard(app: _mockList[i], onTap: () => showAppDetail(ctx, _mockList[i])),
                    ),
                  );
          }
          final list = snap.data!.where((a) => _cat == '全部' || a.category == _cat || a.category.isEmpty).toList();
          if (list.isEmpty) {
            return const SliverFillRemaining(hasScrollBody: false, child: Center(child: Text('没有找到相关应用')));
          }
          return SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 300, mainAxisExtent: 158, crossAxisSpacing: 12, mainAxisSpacing: 12),
              itemCount: list.length,
              itemBuilder: (ctx, i) => EntryCard(app: list[i], onTap: () => showEntryDetail(ctx, list[i], widget.installs)),
            ),
          );
        },
      ),
    ]);
  }
}
