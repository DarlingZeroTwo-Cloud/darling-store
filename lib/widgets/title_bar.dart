import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// 自绘无边框标题栏：最小化/最大化/关闭按钮全部真实绑定，
/// Hyprland 等平铺 WM 下不会出现"关不掉窗口"的问题。
class TitleBar extends StatelessWidget {
  final String title;
  const TitleBar({super.key, required this.title});

  Future<void> _minimize() => windowManager.minimize();
  Future<void> _maximize() async {
    if (await windowManager.isMaximized()) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  }

  Future<void> _close() => windowManager.close();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border(bottom: BorderSide(color: scheme.outlineVariant.withValues(alpha: .5))),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Icon(Icons.storefront_rounded, size: 17, color: scheme.primary),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: scheme.onSurface)),
          const Spacer(),
          _TBtn(icon: Icons.remove_rounded, tooltip: '最小化', onTap: _minimize),
          _TBtn(icon: Icons.crop_square_rounded, tooltip: '最大化', onTap: _maximize),
          _TBtn(icon: Icons.close_rounded, tooltip: '关闭', danger: true, onTap: _close),
        ],
      ),
    );
  }
}

class _TBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool danger;
  final VoidCallback onTap;
  const _TBtn({required this.icon, required this.tooltip, this.danger = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        hoverColor: danger ? scheme.error.withValues(alpha: .15) : scheme.primary.withValues(alpha: .08),
        child: SizedBox(
          width: 46,
          height: 40,
          child: Icon(icon, size: 16, color: danger ? scheme.error : scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
