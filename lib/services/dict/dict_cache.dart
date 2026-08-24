import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/dictionary_result_model.dart';

/// 缓存有效期：7 天（对齐 kiss-translator 的 DEFAULT_CACHE_TIMEOUT）
const Duration kDictCacheTtl = Duration(days: 7);

const String _prefsPrefix = 'dict_cache_';

class _CacheEntry {
  final DictionaryResult result;
  final DateTime expiry;

  const _CacheEntry({required this.result, required this.expiry});

  bool get isExpired => DateTime.now().isAfter(expiry);

  Map<String, dynamic> toJson() => {
        'expiry': expiry.millisecondsSinceEpoch,
        'result': result.toJson(),
      };

  factory _CacheEntry.fromDictionaryResult(DictionaryResult result) =>
      _CacheEntry(
        result: result,
        expiry: DateTime.now().add(kDictCacheTtl),
      );

  factory _CacheEntry.fromJson(Map<String, dynamic> json) => _CacheEntry(
        result: DictionaryResult.fromJson(
            json['result'] as Map<String, dynamic>? ?? {}),
        expiry: DateTime.fromMillisecondsSinceEpoch(
            (json['expiry'] as num?)?.toInt() ?? 0),
      );
}

/// 词典结果 KV 缓存：内存层 + SharedPreferences 持久化层
///
/// 键 = sha256(source|word|contextSig)：
/// 传统词典 contextSig 恒为空串；AI 词典的 contextSig 为剪贴板原句
/// SHA-256 前 16 位（同词不同语境独立缓存）。
class DictCache {
  DictCache({DateTime Function()? clock}) : _now = clock ?? DateTime.now;

  final DateTime Function() _now;
  final Map<String, _CacheEntry> _memory = {};
  bool _loaded = false;

  /// 全局共享实例（服务与设置面板共用）
  static final DictCache shared = DictCache();

  static String buildKey(
          String source, String word, String contextSig) =>
      sha256.convert(utf8.encode('$source|$word|$contextSig')).toString();

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in prefs.getKeys()) {
        if (!key.startsWith(_prefsPrefix)) continue;
        final raw = prefs.getString(key);
        if (raw == null) continue;
        final json = jsonDecode(raw);
        if (json is Map<String, dynamic>) {
          _memory[key.substring(_prefsPrefix.length)] =
              _CacheEntry.fromJson(json);
        }
      }
    } catch (_) {
      // 持久化层损坏时静默降级为纯内存缓存
    }
  }

  /// 读取缓存；过期视为未命中并清除
  Future<DictionaryResult?> get(
      String source, String word, String contextSig) async {
    await _ensureLoaded();
    final key = buildKey(source, word, contextSig);
    final entry = _memory[key];
    if (entry == null) return null;
    if (_now().isAfter(entry.expiry)) {
      _memory.remove(key);
      _removePersisted(key);
      return null;
    }
    return entry.result;
  }

  Future<void> put(
      String source, String word, String contextSig, DictionaryResult result,
      {bool persist = true}) async {
    await _ensureLoaded();
    final key = buildKey(source, word, contextSig);
    final entry = _CacheEntry.fromDictionaryResult(result);
    _memory[key] = entry;
    if (!persist) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          '$_prefsPrefix$key', jsonEncode(entry.toJson()));
    } catch (_) {
      // 持久化失败不影响内存缓存
    }
  }

  Future<void> clearAll() async {
    await _ensureLoaded();
    final keys = List<String>.from(_memory.keys);
    _memory.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in keys) {
        await prefs.remove('$_prefsPrefix$key');
      }
    } catch (_) {
      // 忽略持久化层错误
    }
  }

  Future<void> _removePersisted(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_prefsPrefix$key');
    } catch (_) {
      // 忽略持久化层错误
    }
  }
}
