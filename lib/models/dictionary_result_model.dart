/// 词典查询结果
class DictionaryResult {
  /// 原始 JSON 响应字符串
  final String rawResponse;

  /// 错误信息（查询失败时非空）
  final String errorMessage;

  const DictionaryResult({
    this.rawResponse = '',
    this.errorMessage = '',
  });

  /// 查询是否成功
  bool get isSuccess => errorMessage.isEmpty && rawResponse.isNotEmpty;

  /// 空结果
  static const empty = DictionaryResult();

  /// 从有道词典 API 响应创建结果
  factory DictionaryResult.fromYoudaoResponse(String responseBody) {
    final errorCode = _parseErrorCode(responseBody);
    if (errorCode == null || errorCode != 0) {
      return DictionaryResult(
        rawResponse: responseBody,
        errorMessage: _getYoudaoErrorMessage(errorCode),
      );
    }
    return DictionaryResult(rawResponse: responseBody);
  }

  /// 解析 JSON 响应中的 errorCode 字段
  static int? _parseErrorCode(String responseBody) {
    try {
      // 简单的 JSON 解析，不引入额外依赖
      final trimmed = responseBody.trim();
      if (!trimmed.startsWith('{')) return null;
      final key = '"errorCode"';
      final keyIndex = trimmed.indexOf(key);
      if (keyIndex == -1) return null;
      final afterKey = trimmed.substring(keyIndex + key.length);
      final colonIndex = afterKey.indexOf(':');
      if (colonIndex == -1) return null;
      final afterColon = afterKey.substring(colonIndex + 1).trim();
      final commaIndex = afterColon.indexOf(',');
      final bracketIndex = afterColon.indexOf('}');
      final endIndex = commaIndex == -1
          ? bracketIndex
          : (bracketIndex == -1
              ? commaIndex
              : commaIndex < bracketIndex
                  ? commaIndex
                  : bracketIndex);
      final codeStr = endIndex == -1 ? afterColon : afterColon.substring(0, endIndex);
      return int.tryParse(codeStr.trim().replaceAll('"', ''));
    } catch (_) {
      return null;
    }
  }

  /// 将有道 API 错误码映射为中文错误信息
  static String _getYoudaoErrorMessage(int? errorCode) {
    switch (errorCode) {
      case 0:
        return '';
      case 101:
        return '缺少必填参数';
      case 102:
        return '不支持的语言类型';
      case 103:
        return '查询文本过长';
      case 108:
        return '应用ID无效';
      case 110:
        return '应用未开通词典服务，请在有道智云控制台开启「词典服务」';
      case 111:
        return '未知错误';
      case 202:
        return '签名非法';
      case 203:
        return '访问IP地址不在可访问IP列表';
      case 301:
        return '词典查询失败';
      case 401:
        return '账户已经欠费';
      case 411:
        return '请求频率超过限制';
      default:
        return '未知错误码：$errorCode';
    }
  }

  @override
  String toString() =>
      'DictionaryResult(success: $isSuccess, errorMessage: "$errorMessage")';
}
