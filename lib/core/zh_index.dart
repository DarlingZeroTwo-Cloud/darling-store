/// 中文搜索映射表：中文关键词 → 真实包/应用关键词
/// 用户搜索中文时，扩展为多个英文关键词执行聚合搜索
class ZhIndex {
  static const Map<String, List<String>> map = {
    '浏览器': ['firefox', 'chromium', 'chrome', 'brave', 'opera', 'browser'],
    '微信': ['wechat', 'weixin'],
    '聊天': ['telegram', 'discord', 'chat', 'qq', 'wechat'],
    '音乐': ['spotify', 'music', 'netease', 'audacious'],
    '视频': ['vlc', 'video', 'player', 'mpv', 'kodi'],
    '播放器': ['vlc', 'mpv', 'player'],
    '办公': ['libreoffice', 'office', 'wps'],
    '编辑器': ['code', 'editor', 'vim', 'neovim', 'gedit'],
    '编程': ['python', 'nodejs', 'gcc', 'code'],
    '终端': ['terminal', 'konsole', 'alacritty', 'kitty'],
    '截图': ['screenshot', 'flameshot', 'shutter'],
    '下载': ['download', 'aria2', 'downloader', 'transmission'],
    '邮件': ['thunderbird', 'mail', 'evolution'],
    '游戏': ['steam', 'game', 'lutris', 'mangohud'],
    '绘画': ['gimp', 'krita', 'paint', 'draw'],
    '图片': ['gimp', 'photo', 'image', 'shotwell'],
    '虚拟机': ['virtualbox', 'vm', 'qemu'],
    '容器': ['docker', 'podman'],
    '压缩': ['archive', 'zip', 'rar', 'file-roller'],
    '文件': ['nautilus', 'file', 'dolphin', 'thunar'],
    '系统': ['system', 'monitor', 'htop'],
    '设置': ['settings', 'config'],
    '翻译': ['translate', 'goldendict'],
    '笔记': ['obsidian', 'note', 'joplin', 'cherrytree'],
    '网盘': ['baidunetdisk', 'cloud', 'nextcloud', 'megasync'],
    '录屏': ['obs', 'record', 'simplescreenrecorder'],
    '直播': ['obs', 'live'],
    '杀毒': ['clamav', 'security'],
    '驱动': ['driver', 'firmware'],
    '字体': ['font', 'fonts'],
  };

  static bool hasChinese(String q) => RegExp(r'[\u4e00-\u9fff]').hasMatch(q);

  /// 扩展查询：返回要搜索的关键词列表
  static List<String> expand(String q) {
    final qq = q.trim().toLowerCase();
    if (!hasChinese(qq)) return [qq];
    final hits = <String>{qq};
    for (final e in map.entries) {
      if (qq.contains(e.key)) {
        hits.addAll(e.value);
      }
    }
    return hits.toList();
  }
}
