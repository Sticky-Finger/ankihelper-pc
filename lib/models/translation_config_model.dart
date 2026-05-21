/// 翻译服务提供商枚举
enum TranslationProvider {
  baidu('百度翻译'),
  youdao('有道智云');

  final String displayName;
  const TranslationProvider(this.displayName);
}

/// 翻译 API 配置
class TranslationConfig {
  final TranslationProvider provider;
  final String appId; // 百度: APP ID, 有道: 应用ID
  final String appSecret; // 百度: 密钥, 有道: 应用密钥

  const TranslationConfig({
    this.provider = TranslationProvider.baidu,
    this.appId = '',
    this.appSecret = '',
  });

  TranslationConfig copyWith({
    TranslationProvider? provider,
    String? appId,
    String? appSecret,
  }) =>
      TranslationConfig(
        provider: provider ?? this.provider,
        appId: appId ?? this.appId,
        appSecret: appSecret ?? this.appSecret,
      );

  /// 是否已配置（填写了必需的 API 凭证）
  bool get isConfigured => appId.isNotEmpty && appSecret.isNotEmpty;

  /// 转换为 JSON 用于持久化存储
  Map<String, dynamic> toJson() => {
        'provider': provider.name,
        'appId': appId,
        'appSecret': appSecret,
      };

  /// 从 JSON 恢复配置
  static TranslationConfig fromJson(Map<String, dynamic> json) =>
      TranslationConfig(
        provider: TranslationProvider.values.firstWhere(
          (p) => p.name == json['provider'],
          orElse: () => TranslationProvider.baidu,
        ),
        appId: json['appId'] ?? '',
        appSecret: json['appSecret'] ?? '',
      );
}
