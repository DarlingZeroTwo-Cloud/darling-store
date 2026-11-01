import 'dart:convert';
import 'dart:io';

/// 简介中文翻译（Agnes AI API，带本地缓存，离线回退原文）
class TranslateService {
  static final TranslateService instance = TranslateService();
  static const _apiBase = 'https://apihub.agnes-ai.com/v1';
  static const _apiKey = 'sk-IFKW2LI932S0zH9Dv0KBLatIax6mEzOObhRZhtTHhGkMrtBM';
  static const _model = 'agnes-3.0-flash';

  final Map<String, String> _cache = {};
  bool _loading = false;

  bool isChinese(String s) => RegExp(r'[\u4e00-\u9fff]').hasMatch(s);

  Future<String> translate(String text) async {
    if (text.trim().isEmpty) return '';
    if (isChinese(text)) return text; // 本来就是中文
    _loadCache();
    if (_cache.containsKey(text)) return _cache[text]!;
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 6)
        ..findProxy = (uri) => 'DIRECT'; // 绕过环境代理（云主机坏代理陷阱）
      final req = await client.postUrl(Uri.parse('$_apiBase/chat/completions')).timeout(const Duration(seconds: 8));
      req.headers.contentType = ContentType.json;
      req.headers.set('Authorization', 'Bearer $_apiKey');
      req.write(jsonEncode({
        'model': _model,
        'messages': [
          {'role': 'user', 'content': '请把下面的英文应用简介翻译成简体中文，只输出译文，不要解释：\n$text'}
        ],
        'max_tokens': 200,
        'temperature': 0.2,
      }));
      final resp = await req.close().timeout(const Duration(seconds: 20));
      final body = await resp.transform(utf8.decoder).join().timeout(const Duration(seconds: 20));
      client.close();
      if (resp.statusCode == 200) {
        final j = jsonDecode(body);
        final out = (j['choices'] as List).first['message']['content'].toString().trim();
        if (out.isNotEmpty) {
          _cache[text] = out;
          _saveCache();
          return out;
        }
      }
    } catch (_) {}
    return text; // 失败回退原文
  }

  void _loadCache() {
    if (_cache.isNotEmpty || _loading) return;
    _loading = true;
    try {
      final f = File('${Platform.environment['HOME']}/.cache/darling-store/translations.json');
      if (f.existsSync()) {
        final d = jsonDecode(f.readAsStringSync());
        if (d is Map) _cache.addAll(d.cast<String, String>());
      }
    } catch (_) {}
    _loading = false;
  }

  void _saveCache() {
    try {
      Directory('${Platform.environment['HOME']}/.cache/darling-store').createSync(recursive: true);
      File('${Platform.environment['HOME']}/.cache/darling-store/translations.json')
          .writeAsStringSync(jsonEncode(_cache.take(500)));
    } catch (_) {}
  }
}

extension _Take on Map<String, String> {
  Map<String, String> take(int n) => Map.fromEntries(entries.take(n));
}
