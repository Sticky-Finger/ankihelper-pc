import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
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

  AnkiConnectService({this.baseUrl = 'http://localhost:8765'});

  /// 统一 JSON-RPC 调用方法（每次请求使用独立连接，避免连接复用导致 Write failed）
  Future<dynamic> invoke(String action, [Map<String, dynamic>? params]) async {
    final request = {
      'action': action,
      'version': 6,
      'params': params ?? {},
    };

    if (kDebugMode) {
      debugPrint('[AnkiConnect] 发送请求: $action');
      debugPrint('[AnkiConnect] 请求体: ${jsonEncode(request)}');
    }

    try {
      final response = await http
          .post(
            Uri.parse(baseUrl),
            headers: {
              'Content-Type': 'application/json',
              'Connection': 'close',
            },
            body: jsonEncode(request),
          )
          .timeout(const Duration(seconds: 5));

      if (kDebugMode) {
        debugPrint('[AnkiConnect] 响应状态: ${response.statusCode}');
        debugPrint('[AnkiConnect] 响应体: ${response.body}');
      }

      final responseBody = jsonDecode(utf8.decode(response.bodyBytes));

      if (responseBody['error'] != null) {
        throw AnkiConnectException('AnkiConnect 错误: ${responseBody['error']}');
      }

      return responseBody['result'];
    } on TimeoutException {
      if (kDebugMode) {
        debugPrint('[AnkiConnect] 请求超时: $action');
      }
      throw AnkiConnectException('连接超时，请确保 Anki 正在运行且 AnkiConnect 已安装');
    } on http.ClientException catch (e) {
      if (kDebugMode) {
        debugPrint('[AnkiConnect] 网络错误: ${e.message}');
      }
      throw AnkiConnectException('网络错误: ${e.message}');
    }
  }

  /// 获取 AnkiConnect 版本号
  Future<int> getVersion() async {
    if (kDebugMode) {
      debugPrint('[AnkiConnect] 获取版本号...');
    }
    final result = await invoke('version');
    if (kDebugMode) {
      debugPrint('[AnkiConnect] 版本号: $result');
    }
    return result as int;
  }

  /// 添加笔记到 Anki
  Future<int> addNote({
    required String deckName,
    required String modelName,
    required Map<String, String> fields,
    List<String> tags = const ['ankihelper'],
    bool allowDuplicate = false,
  }) async {
    if (kDebugMode) {
      debugPrint('[AnkiConnect] 添加笔记到牌组: $deckName');
      debugPrint('[AnkiConnect] 模型: $modelName');
      debugPrint('[AnkiConnect] 字段: $fields');
    }

    final note = {
      'deckName': deckName,
      'modelName': modelName,
      'fields': fields,
      'tags': tags,
      'options': {
        'allowDuplicate': allowDuplicate,
      },
    };

    final result = await invoke('addNote', {'note': note});

    if (kDebugMode) {
      debugPrint('[AnkiConnect] 笔记已添加，ID: $result');
    }

    return result as int;
  }

  /// 获取所有牌组名称
  Future<List<String>> getDeckNames() async {
    final result = await invoke('deckNames');
    return (result as List).cast<String>();
  }

  /// 创建牌组（若已存在则忽略）
  Future<void> createDeck(String deckName) async {
    await invoke('createDeck', {'deck': deckName});
    if (kDebugMode) {
      debugPrint('[AnkiConnect] 牌组已创建/确认: $deckName');
    }
  }

}
