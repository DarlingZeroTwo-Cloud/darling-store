/// 应用条目（聚合模型：同一应用可来自多个源）
class StoreApp {
  final String id;
  final String name;
  final String summary; // 中文简介
  final String icon; // emoji 占位，后续接真实图标
  final String category;
  final Map<String, String> versions; // 源ID -> 版本
  final bool system; // 系统应用不可卸载
  final bool hasUpdate;
  const StoreApp({
    required this.id,
    required this.name,
    required this.summary,
    required this.icon,
    required this.category,
    this.versions = const {},
    this.system = false,
    this.hasUpdate = false,
  });
}

/// 展示用示例数据（后续由聚合核心替换）
const List<StoreApp> kMockApps = [
  StoreApp(id: 'firefox', name: 'Firefox', summary: '自由开源的网页浏览器，支持扩展与隐私保护', icon: '🦊', category: '浏览器', versions: {'apt': '131.0', 'flathub': '131.0', 'appimage': '131.0'}),
  StoreApp(id: 'code', name: 'Visual Studio Code', summary: '微软出品的代码编辑器，支持海量插件', icon: '🧩', category: '开发工具', versions: {'flathub': '1.95.0', 'appimage': '1.95.0'}),
  StoreApp(id: 'steam', name: 'Steam', summary: '游戏发行与联机平台', icon: '🎮', category: '游戏', versions: {'flathub': '1.0.0.81', 'apt': '1.0.0.81'}),
  StoreApp(id: 'wechat', name: '微信', summary: '国民级即时通讯与支付应用', icon: '💬', category: '社交', versions: {'spark': '4.0.0', 'appimage': '4.0.0'}),
  StoreApp(id: 'netease-music', name: '网易云音乐', summary: '海量音乐曲库与个性化推荐', icon: '🎵', category: '音乐', versions: {'spark': '3.0.0', 'appimage': '3.0.0'}),
  StoreApp(id: 'wps', name: 'WPS Office', summary: '国产办公套件，兼容 Word/Excel/PPT', icon: '📄', category: '办公', versions: {'spark': '12.1.0'}),
  StoreApp(id: 'dingtalk', name: '钉钉', summary: '企业办公沟通与协同平台', icon: '📌', category: '办公', versions: {'spark': '7.6.0'}),
  StoreApp(id: 'obsidian', name: 'Obsidian', summary: '本地优先的 Markdown 知识库', icon: '💎', category: '效率', versions: {'flathub': '1.7.0', 'appimage': '1.7.0'}),
];

const List<String> kMockCategories = ['全部', '浏览器', '社交', '办公', '音乐', '开发工具', '游戏', '效率', '系统工具', '影音', '图形'];

/// 已安装（系统应用不可卸载）
const List<StoreApp> kMockInstalled = [
  StoreApp(id: 'files', name: '文件管理器', summary: 'Darling OS 内置文件管理', icon: '📁', category: '系统工具', system: true),
  StoreApp(id: 'terminal', name: '终端', summary: '系统终端', icon: '🖥️', category: '系统工具', system: true),
  StoreApp(id: 'firefox', name: 'Firefox', summary: '网页浏览器', icon: '🦊', category: '浏览器', hasUpdate: true),
  StoreApp(id: 'obsidian', name: 'Obsidian', summary: '知识库', icon: '💎', category: '效率'),
];
