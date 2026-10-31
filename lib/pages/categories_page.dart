import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../widgets/app_card.dart';

/// 分类页：分类网格 + 该分类应用列表
class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});
  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  String _sel = '全部';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cats = kMockCategories.where((c) => c != '全部').toList();
    final list = kMockApps.where((a) => _sel == '全部' || a.category == _sel).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('分类', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        Expanded(
          child: ListView(children: [
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final c in cats)
                ChoiceChip(label: Text(c), selected: _sel == c, onSelected: (_) => setState(() => _sel = c)),
            ]),
            const SizedBox(height: 16),
            Text('$_sel 应用（${list.length}）', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 10),
            for (final a in list)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(app: a, onTap: () => showAppDetail(context, a)),
              ),
          ]),
        ),
      ]),
    );
  }
}
