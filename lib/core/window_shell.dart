import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// 窗口管理与 Hyprland 适配：
/// - 无边框自绘标题栏，解决平铺 WM 下无关闭按钮/关不掉窗口的问题
/// - 窗口大小、缩放跟随系统，无 XWayland 缩放异常
class WindowShell {
  static Future<void> init() async {
    await windowManager.ensureInitialized();
    const opts = WindowOptions(
      size: Size(1180, 760),
      minimumSize: Size(940, 620),
      center: true,
      title: 'Darling Store',
      titleBarStyle: TitleBarStyle.hidden,
      backgroundColor: Colors.transparent,
    );
    await windowManager.waitUntilReadyToShow(opts, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  /// Hyprland 平铺窗口下若最大化状态异常，重置为正常窗口
  static Future<void> repairWindowState() async {
    try {
      if (await windowManager.isMaximized()) {
        await windowManager.unmaximize();
        await windowManager.maximize();
      }
    } catch (_) {}
  }
}
