# Darling Store

为 **Darling OS（Ubuntu 26.04 / Hyprland）** 打造的聚合应用商店。

## 特性

- **六源聚合**：APT / Flatpak(Flathub) / 星火(Spark) / 玲珑(Linglong) / AppImage / 本地导入
- **同应用多版本**：一个应用多个下载入口，默认自动选源（apt > flathub > spark > linglong > appimage）
- **实时更新**：定时刷新源 + 立即刷新，聚合已装应用的新版本提示，一键更新
- **镜像自动测速切换**：GitHub 镜像 + 国内镜像池，不可用自动换、按速度选最快
- **依赖补全**：安装时自动解析并安装缺少的依赖与运行时
- **先下载后安装**：下载并行（默认 3），安装串行排队（apt 锁），逐项进度
- **Hyprland 适配**：无边框自绘标题栏，解决平铺 WM 下关窗/缩放异常
- **中文优先**：简介非中文自动翻译，内置多语言跟随系统
- **本地导入**：支持 .deb / .appimage / .flatpak 等格式直接安装，文件关联打开
- **现代 Flutter UI**：Material 3 圆角风格，跟随系统深浅色

## 开发

```bash
flutter pub get
flutter run -d linux
```

## 构建

```bash
flutter build linux --release
# 产物：build/linux/x64/release/bundle/
```

## 技术栈

- Flutter（Linux 桌面，org `com.darling`）
- window_manager（无边框窗口）
- 设置持久化：`~/.config/darling-store/settings.json`

## 路线图

- [x] 窗口壳 + 侧边栏 + 7 页面 UI（mock 数据）
- [ ] 聚合核心 + APT/Flatpak 源
- [ ] 下载/安装队列真实实现
- [ ] 星火/玲珑/AppImage 源 + 镜像调度
- [ ] 详情翻译 + 截图 + 本地导入 + 中文搜索

MIT License
