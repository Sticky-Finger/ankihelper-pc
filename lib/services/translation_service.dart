import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../models/translation_config_model.dart';

/// 翻译服务异常
class TranslationException implements Exception {
  final String message;
  TranslationException(this.message);

  @override
  String toString() => 'TranslationException: $message';
}

/// 翻译服务
class TranslationService {
  final TranslationConfig config;

  TranslationService(this.config);

  /// 调用翻译 API 获取中文翻译
  Future<String> translate(String text) async {
    if (!config.isConfigured) {
      throw TranslationException('翻译 API 未配置，请在设置中填写 API 凭证');
    }

    if (text.trim().isEmpty) {
      return '';
    }

    switch (config.provider) {
      case TranslationProvider.baidu:
        return _translateBaidu(text);
      case TranslationProvider.youdao:
        return _translateYoudao(text);
    }
  }

  /// 百度翻译 API 实现
  /// 文档: https://api.fanyi.baidu.com/doc/21
  Future<String> _translateBaidu(String text) async {
    const apiUrl = 'https://fanyi-api.baidu.com/api/trans/vip/translate';

    final salt = DateTime.now().millisecondsSinceEpoch.toString();
    final sign = _generateBaiduSign(text, salt);

    final uri = Uri.parse(apiUrl).replace(queryParameters: {
      'q': text,
      'from': 'en',
      'to': 'zh',
      'appid': config.appId,
      'salt': salt,
      'sign': sign,
    });

    try {
      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw TranslationException('百度翻译 API 请求失败: ${response.statusCode}');
      }

      final data = json.decode(response.body);

      if (data.containsKey('error_code')) {
        final errorCode = data['error_code'];
        final errorMsg = data['error_msg'] ?? '未知错误';
        throw TranslationException('百度翻译错误 [$errorCode]: $errorMsg');
      }

      final paragraphs = data['trans_result'] as List;
      if (paragraphs.isEmpty) {
        return '';
      }

      // 合并所有段落
      return paragraphs.map((p) => p['dst'] as String).join('\n');
    } on TranslationException {
      rethrow;
    } catch (e) {
      throw TranslationException('百度翻译请求失败: $e');
    }
  }

  /// 生成百度翻译签名
  /// MD5(appid + q + salt + 密钥)
  String _generateBaiduSign(String text, String salt) {
    final input = '${config.appId}$text$salt${config.appSecret}';
    final bytes = utf8.encode(input);
    final hash = md5.convert(bytes);
    return hash.toString();
  }

  /// 有道翻译 API 实现
  /// 文档: https://ai.youdao.com/DOCSIRMA/html/自然语言翻译/API文档/文本翻译服务/文本翻译服务-API文档.html
  Future<String> _translateYoudao(String text) async {
    const apiUrl = 'https://openapi.youdao.com/api';

    final salt = DateTime.now().millisecondsSinceEpoch.toString();
    final curtime = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final sign = _generateYoudaoSign(text, salt, curtime);

    final uri = Uri.parse(apiUrl).replace(queryParameters: {
      'q': text,
      'from': 'en',
      'to': 'zh-CHS',
      'appKey': config.appId,
      'salt': salt,
      'sign': sign,
      'signType': 'v3',
      'curtime': curtime,
    });

    try {
      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw TranslationException('有道翻译 API 请求失败: ${response.statusCode}');
      }

      final data = json.decode(response.body);

      final errorCode = data['errorCode'];
      if (errorCode != '0') {
        final errorMsg = _getYoudaoErrorMessage(errorCode);
        throw TranslationException('有道翻译错误: $errorMsg');
      }

      final paragraphs = data['translation'] as List?;
      if (paragraphs == null || paragraphs.isEmpty) {
        return '';
      }

      return paragraphs.join('');
    } on TranslationException {
      rethrow;
    } catch (e) {
      throw TranslationException('有道翻译请求失败: $e');
    }
  }

  /// 生成有道翻译签名 (SHA-256)
  /// SHA256(appKey + input(q) + salt + curtime + appSecret)
  String _generateYoudaoSign(String text, String salt, String curtime) {
    final input = text.length > 20
        ? '${text.substring(0, 10)}${text.length}${text.substring(text.length - 10)}'
        : text;

    final inputStr = '${config.appId}$input$salt$curtime${config.appSecret}';
    final bytes = utf8.encode(inputStr);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// 有道翻译错误码映射
  String _getYoudaoErrorMessage(String errorCode) {
    const errorMap = {
      '101': '缺少必填参数',
      '102': '不支持的语言',
      '103': '翻译文本过长',
      '104': '不支持的API类型',
      '105': '不支持的签名类型',
      '106': '不支持的响应类型',
      '107': '不支持的传输加密类型',
      '108': 'appKey无效',
      '109': 'batchLog格式不正确',
      '110': '无相关服务的有效实例',
      '111': '开发者账号无效',
      '201': '解密失败',
      '202': '签名检验失败',
      '203': '访问IP地址不在可访问IP列表',
      '301': '辞典查询失败',
      '302': '翻译查询失败',
      '303': '服务端的其它异常',
      '401': '账户已经欠费',
      '411': '访问频率受限',
      '412': '长请求过于频繁',
    };
    return errorMap[errorCode] ?? '未知错误 ($errorCode)';
  }
}
