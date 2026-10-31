import 'dart:io';
import 'dart:math';

/// 镜像条目（实测数据初始化，运行时重测）
class MirrorEntry {
  final String name;
  final String url;
  double latencyMs;
  bool available;
  MirrorEntry(this.name, this.url, {this.latencyMs = 0, this.available = true});
}

/// 镜像测速调度：各源镜像池，HTTP 测速排序、不可用自动跳过
class MirrorManager {
  static final MirrorManager instance = MirrorManager();

  /// GitHub 镜像池（2026-10 实测：直连/gh-proxy/ghfast 可用；ghproxy.com 系列已死）
  final List<MirrorEntry> github = [
    MirrorEntry('GitHub 直连', 'https://github.com', latencyMs: 640),
    MirrorEntry('gh-proxy.com', 'https://gh-proxy.com', latencyMs: 650),
    MirrorEntry('ghfast.top', 'https://ghfast.top', latencyMs: 800),
  ];

  /// Flathub 镜像池（清华/中科大 summary 404，标记不可用由测速确认）
  final List<MirrorEntry> flathub = [
    MirrorEntry('Flathub 官方', 'https://dl.flathub.org', latencyMs: 8000),
    MirrorEntry('清华 TUNA', 'https://mirrors.tuna.tsinghua.edu.cn/flathub'),
    MirrorEntry('中科大 USTC', 'https://mirrors.ustc.edu.cn/flathub'),
  ];

  /// 星火 Spark 镜像池
  final List<MirrorEntry> spark = [
    MirrorEntry('星火官方', 'https://spark-app.store'),
    MirrorEntry('清华 TUNA', 'https://mirrors.tuna.tsinghua.edu.cn/spark-store'),
    MirrorEntry('中科大 USTC', 'https://mirrors.ustc.edu.cn/spark-store'),
  ];

  /// 玲珑 Linglong 镜像池
  final List<MirrorEntry> linglong = [
    MirrorEntry('玲珑官方', 'https://linglong.dev'),
    MirrorEntry('清华 TUNA', 'https://mirrors.tuna.tsinghua.edu.cn/linglong'),
    MirrorEntry('中科大 USTC', 'https://mirrors.ustc.edu.cn/linglong'),
  ];

  List<MirrorEntry> poolFor(String sourceId) => switch (sourceId) {
        'github' => github, 'flathub' => flathub,
        'spark' => spark, 'linglong' => linglong,
        _ => github,
      };

  /// 测速单个镜像：HEAD/GET 前 256 字节计时
  Future<double> _speed(MirrorEntry m) async {
    final sw = Stopwatch()..start();
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final req = await client.getUrl(Uri.parse('${m.url}/')).timeout(const Duration(seconds: 6));
      req.headers.set('Range', 'bytes=0-255');
      final resp = await req.close().timeout(const Duration(seconds: 6));
      await resp.drain<void>().timeout(const Duration(seconds: 4));
      client.close();
      final ms = sw.elapsedMilliseconds.toDouble();
      m.latencyMs = ms;
      m.available = resp.statusCode < 400;
      return ms;
    } catch (_) {
      m.latencyMs = 99999;
      m.available = false;
      return 99999;
    }
  }

  /// 全池测速（并发），返回排序后的可用镜像
  Future<List<MirrorEntry>> test(String sourceId) async {
    final pool = poolFor(sourceId);
    await Future.wait(pool.map(_speed));
    pool.sort((a, b) => a.latencyMs.compareTo(b.latencyMs));
    return pool;
  }

  /// 当前最快可用镜像
  Future<MirrorEntry> best(String sourceId) async {
    final r = await test(sourceId);
    final ok = r.where((m) => m.available).toList();
    return ok.isEmpty ? MirrorEntry('（全部不可用）', '', available: false) : ok.first;
  }

  /// 全源一键测速（用于设置页展示）
  Future<Map<String, List<MirrorEntry>>> testAll() async {
    final map = <String, List<MirrorEntry>>{};
    for (final id in ['github', 'flathub', 'spark', 'linglong']) {
      map[id] = await test(id);
    }
    return map;
  }
}

String fmtLatency(double ms) {
  if (ms >= 99999) return '不可用';
  if (ms >= 1000) return '${(ms / 1000).toStringAsFixed(1)}s';
  return '${max(1, ms.round())}ms';
}
