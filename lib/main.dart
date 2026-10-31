import 'package:flutter/material.dart';
import 'core/settings.dart';
import 'core/theme.dart';
import 'core/window_shell.dart';
import 'pages/categories_page.dart';
import 'pages/home_page.dart';
import 'pages/install_queue_page.dart';
import 'pages/installed_page.dart';
import 'pages/settings_page.dart';
import 'pages/sources_page.dart';
import 'pages/updates_page.dart';
import 'widgets/title_bar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WindowShell.init();
  final settings = await SettingsController.load();
  runApp(DarlingStoreApp(settings: settings));
}

class DarlingStoreApp extends StatelessWidget {
  final SettingsController settings;
  const DarlingStoreApp({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (ctx, _) => MaterialApp(
        title: 'Darling Store',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: settings.themeMode == ThemeModeChoice.system
            ? ThemeMode.system
            : settings.themeMode == ThemeModeChoice.dark
                ? ThemeMode.dark
                : ThemeMode.light,
        home: MainShell(settings: settings),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  final SettingsController settings;
  const MainShell({super.key, required this.settings});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  // 正在安装角标：队列非空时显示（后续由安装管理器驱动）
  final bool _installing = true;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pages = [
      const HomePage(),
      const CategoriesPage(),
      const InstalledPage(),
      const InstallQueuePage(),
      const UpdatesPage(),
      SourcesPage(settings: widget.settings),
      SettingsPage(settings: widget.settings),
    ];
    return Scaffold(
      body: Column(children: [
        const TitleBar(title: 'Darling Store'),
        Expanded(
          child: Row(children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: [
                const NavigationRailDestination(icon: Icon(Icons.home_rounded), label: Text('首页')),
                const NavigationRailDestination(icon: Icon(Icons.grid_view_rounded), label: Text('分类')),
                const NavigationRailDestination(icon: Icon(Icons.check_circle_outline_rounded), selectedIcon: Icon(Icons.check_circle_rounded), label: Text('已安装')),
                NavigationRailDestination(
                  icon: _installing
                      ? const Badge(smallSize: 8, child: Icon(Icons.downloading_rounded))
                      : const Icon(Icons.downloading_rounded),
                  label: const Text('正在安装'),
                ),
                const NavigationRailDestination(icon: Icon(Icons.system_update_rounded), label: Text('更新')),
                const NavigationRailDestination(icon: Icon(Icons.storage_rounded), label: Text('源管理')),
                const NavigationRailDestination(icon: Icon(Icons.settings_rounded), label: Text('设置')),
              ],
            ),
            VerticalDivider(width: 1, color: scheme.outlineVariant.withValues(alpha: .4)),
            Expanded(child: IndexedStack(index: _index, children: pages)),
          ]),
        ),
      ]),
    );
  }
}
