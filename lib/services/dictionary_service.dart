import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../models/dictionary_result_model.dart';
import '../models/translation_config_model.dart';

/// 有道词典 API 查询服务
///
/// 复用翻译 API 的 appId 和 appSecret（仅支持有道智云）。
/// API 文档：https://ai.youdao.com/DOCSIRMA/html/自然语言翻译/API文档/词典服务/词典服务-API文档.html
class DictionaryService {
  final TranslationConfig config;
  final Duration timeout;

  DictionaryService({
    required this.config,
    this.timeout = const Duration(seconds: 5),
  });

  /// 查询单词释义
  Future<DictionaryResult> query(String word) async {
    if (!config.isConfigured) {
      return DictionaryResult(
        errorMessage: '词典 API 未配置，请在设置中填写有道智云 API 凭证',
      );
    }

    if (word.trim().isEmpty) {
      return DictionaryResult(errorMessage: '查询单词不能为空');
    }

    try {
      return await _queryYoudao(word.trim().toLowerCase());
    } catch (e) {
      return DictionaryResult(errorMessage: '词典查询请求失败: $e');
    }
  }

  /// 调用有道词典 API（使用 POST + form-urlencoded）
  /// 文档：https://ai.youdao.com/DOCSIRMA/html/dictionary/api/ydcd/index.html
  Future<DictionaryResult> _queryYoudao(String word) async {
    const apiUrl = 'https://openapi.youdao.com/v2/dict';

    final salt = DateTime.now().millisecondsSinceEpoch.toString();
    final curtime = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final sign = _generateSign(word, salt, curtime);

    final body = {
      'q': word,
      'langType': 'auto',
      'dicts': 'ec',
      'appKey': config.appId,
      'salt': salt,
      'sign': sign,
      'signType': 'v3',
      'curtime': curtime,
    };

    try {
      final response = await http
          .post(Uri.parse(apiUrl), body: body)
          .timeout(timeout);
      if (response.statusCode != 200) {
        return DictionaryResult(
          errorMessage: '词典 API 请求失败 (HTTP ${response.statusCode})',
        );
      }
      return DictionaryResult.fromYoudaoResponse(response.body);
    } on TimeoutException {
      return DictionaryResult(errorMessage: '词典查询超时（${timeout.inSeconds}秒）');
    } on http.ClientException {
      return DictionaryResult(errorMessage: '网络连接失败，请检查网络');
    }
  }

  /// 生成有道 API 签名 (SHA-256)
  ///
  /// 签名算法：SHA256(appKey + input(q) + salt + curtime + appSecret)
  /// 与翻译服务的签名算法一致。
  String _generateSign(String text, String salt, String curtime) {
    final input = text.length > 20
        ? '${text.substring(0, 10)}${text.length}${text.substring(text.length - 10)}'
        : text;

    final inputStr = '${config.appId}$input$salt$curtime${config.appSecret}';
    final bytes = utf8.encode(inputStr);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }
}
