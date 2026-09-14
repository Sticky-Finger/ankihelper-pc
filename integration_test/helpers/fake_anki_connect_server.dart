import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// 本地假 AnkiConnect 服务（E2E 测试专用）
///
/// 在 127.0.0.1 随机端口起一个 JSON-RPC HTTP 服务，模拟 AnkiConnect 的
/// 常用 actions。测试通过 `AnkiConnectService(baseUrl: ...)` 指向本服务，
/// 走真实 HTTP 路径（序列化/反序列化/错误分支全覆盖），无需安装 Anki。
class FakeAnkiConnectServer {
  HttpServer? _server;

  /// 返回给 deckNames 的牌组列表
  List<String> decks = ['Default', 'ankihelper-e2e'];

  /// 返回给 modelNames 的模板名列表（为空会触发应用侧 createModel）
  List<String> models = [];

  /// 模板名 → 字段列表（modelFieldNames 响应）
  final Map<String, List<String>> modelFields = {};

  /// 已收到的 addNote 笔记（fields 为笔记字段）
  final List<Map<String, dynamic>> addedNotes = [];

  /// 已收到的全部 action（用于断言调用链）
  final List<String> receivedActions = [];

  /// 下一个 addNote 返回该错误（模拟 AnkiConnect 业务错误），用后自动清除
  String? errorForNextAddNote;

  /// 服务是否已启动
  bool get isRunning => _server != null;

  /// 服务基地址（注入 AnkiConnectService.baseUrl）
  String get baseUrl => 'http://127.0.0.1:${_server!.port}';

  /// 启动服务（随机可用端口）
  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server!.listen(_handle);
  }

  /// 停止服务
  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  Future<void> _handle(HttpRequest request) async {
    final body =
        await utf8.decoder.bind(request).join(); // 仅接受本机测试进程的回环请求
    try {
      final Map<String, dynamic> payload = jsonDecode(body);
      final action = payload['action'] as String? ?? '';
      final params = (payload['params'] as Map?)?.cast<String, dynamic>() ?? {};
      receivedActions.add(action);

      final response = _dispatch(action, params);
      _respond(request, response);
    } catch (e) {
      _respond(request, {'result': null, 'error': '假服务内部错误: $e'});
    }
  }

  Map<String, dynamic> _dispatch(String action, Map<String, dynamic> params) {
    switch (action) {
      case 'version':
        return {'result': 6, 'error': null};
      case 'deckNames':
        return {'result': decks, 'error': null};
      case 'createDeck':
        final deck = params['deck'] as String?;
        if (deck != null && !decks.contains(deck)) {
          decks.add(deck);
        }
        return {'result': decks.length, 'error': null};
      case 'modelNames':
        return {'result': models, 'error': null};
      case 'modelFieldNames':
        final modelName = params['modelName'] as String? ?? '';
        return {'result': modelFields[modelName] ?? const [], 'error': null};
      case 'createModel':
        final modelName = params['modelName'] as String? ?? '';
        if (!models.contains(modelName)) {
          models.add(modelName);
        }
        // AnkiConnect 返回包含模型 ID 的对象，应用侧不读取具体内容
        return {
          'result': {
            'name': modelName,
            'id': 1607392319000 + models.length,
            'flds': modelFields[modelName] ?? const [],
          },
          'error': null,
        };
      case 'addNote':
        if (errorForNextAddNote != null) {
          final error = errorForNextAddNote;
          errorForNextAddNote = null;
          return {'result': null, 'error': error};
        }
        final note = (params['note'] as Map?)?.cast<String, dynamic>() ?? {};
        addedNotes.add(note);
        return {'result': 1700000000000 + addedNotes.length, 'error': null};
      default:
        return {'result': null, 'error': '未知 action: $action'};
    }
  }

  void _respond(HttpRequest request, Map<String, dynamic> response) {
    final data = utf8.encode(jsonEncode(response));
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..contentLength = data.length
      ..add(data);
    request.response.close();
  }
}
