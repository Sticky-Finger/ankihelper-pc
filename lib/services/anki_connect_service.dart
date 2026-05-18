import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// AnkiConnect 调用异常
class AnkiConnectException implements Exception {
  final String message;
  AnkiConnectException(this.message);

  @override
  String toString() => 'AnkiConnectException: $message';
}

/// AnkiConnect JSON-RPC 服务封装
class AnkiConnectService {
  final String baseUrl;
  final http.Client _client;

  AnkiConnectService({
    this.baseUrl = 'http://localhost:8765',
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// 统一 JSON-RPC 调用方法
  Future<dynamic> invoke(String action, [Map<String, dynamic>? params]) async {
    final request = {
      'action': action,
      'version': 6,
      'params': params ?? {},
    };

    try {
      final response = await _client
          .post(
            Uri.parse(baseUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(request),
          )
          .timeout(const Duration(seconds: 5));

      final responseBody = jsonDecode(utf8.decode(response.bodyBytes));

      if (responseBody['error'] != null) {
        throw AnkiConnectException('AnkiConnect 错误: ${responseBody['error']}');
      }

      return responseBody['result'];
    } on TimeoutException {
      throw AnkiConnectException('连接超时，请确保 Anki 正在运行且 AnkiConnect 已安装');
    } on http.ClientException catch (e) {
      throw AnkiConnectException('网络错误: ${e.message}');
    }
  }

  /// 获取 AnkiConnect 版本号
  Future<int> getVersion() async {
    final result = await invoke('version');
    return result as int;
  }

  /// 添加笔记到 Anki
  Future<int> addNote({
    required String deckName,
    required String modelName,
    required Map<String, String> fields,
    List<String> tags = const ['ankihelper'],
  }) async {
    final note = {
      'deckName': deckName,
      'modelName': modelName,
      'fields': fields,
      'tags': tags,
      'options': {
        'allowDuplicate': false,
      },
    };

    final result = await invoke('addNote', {'note': note});
    return result as int;
  }

  /// 释放资源
  void dispose() {
    _client.close();
  }
}
