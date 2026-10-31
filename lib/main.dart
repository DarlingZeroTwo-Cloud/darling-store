import 'package:flutter/material.dart';
import 'core/install_manager.dart';
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
  final InstallState _installs = InstallState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pages = [
      HomePage(installs: _installs),
      const CategoriesPage(),
      const InstalledPage(),
      InstallQueuePage(installs: _installs),
      const UpdatesPage(),
      SourcesPage(settings: widget.settings),
      SettingsPage(settings: widget.settings),
    ];
    return Scaffold(
      body: Column(children: [
        const TitleBar(title: 'Darling Store'),
        Expanded(
          child: Row(children: [
            ListenableBuilder(
              listenable: _installs,
              builder: (ctx, _) => NavigationRail(
                selectedIndex: _index,
                onDestinationSelected: (i) => setState(() => _index = i),
                destinations: [
                  const NavigationRailDestination(icon: Icon(Icons.home_rounded), label: Text('首页')),
                  const NavigationRailDestination(icon: Icon(Icons.grid_view_rounded), label: Text('分类')),
                  const NavigationRailDestination(icon: Icon(Icons.check_circle_outline_rounded), selectedIcon: Icon(Icons.check_circle_rounded), label: Text('已安装')),
                  NavigationRailDestination(
                    icon: _installs.active
                        ? const Badge(smallSize: 8, child: Icon(Icons.downloading_rounded))
                        : const Icon(Icons.downloading_rounded),
                    label: const Text('正在安装'),
                  ),
                  const NavigationRailDestination(icon: Icon(Icons.system_update_rounded), label: Text('更新')),
                  const NavigationRailDestination(icon: Icon(Icons.storage_rounded), label: Text('源管理')),
                  const NavigationRailDestination(icon: Icon(Icons.settings_rounded), label: Text('设置')),
                ],
              ),
            ),
            VerticalDivider(width: 1, color: scheme.outlineVariant.withValues(alpha: .4)),
            Expanded(child: IndexedStack(index: _index, children: pages)),
          ]),
        ),
      ]),
    );
  }
}
