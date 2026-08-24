import '../services/dict/ai_dict_api.dart' show AiDictConfig;

export '../services/dict/ai_dict_api.dart' show AiDictConfig;

/// 词典源偏好
enum DictSourcePreference {
  /// 自动：Bing → 有道 → AI（配置了才启用）回退链
  auto,

  /// 指定必应词典优先
  bing,

  /// 指定有道词典优先
  youdao,

  /// 指定 AI 词典优先
  ai,
}

extension DictSourcePreferenceLabel on DictSourcePreference {
  String get label => switch (this) {
        DictSourcePreference.auto => '自动（必应优先）',
        DictSourcePreference.bing => '必应词典',
        DictSourcePreference.youdao => '有道词典',
        DictSourcePreference.ai => 'AI 词典',
      };
}

/// 词典设置（持久化于 SharedPreferences）
class DictSettings {
  final DictSourcePreference preferredSource;
  final AiDictConfig aiConfig;

  const DictSettings({
    this.preferredSource = DictSourcePreference.auto,
    this.aiConfig = const AiDictConfig(),
  });

  DictSettings copyWith({
    DictSourcePreference? preferredSource,
    AiDictConfig? aiConfig,
  }) =>
      DictSettings(
        preferredSource: preferredSource ?? this.preferredSource,
        aiConfig: aiConfig ?? this.aiConfig,
      );

  Map<String, dynamic> toJson() => {
        'preferredSource': preferredSource.name,
        'aiConfig': {
          'baseUrl': aiConfig.baseUrl,
          'apiKey': aiConfig.apiKey,
          'model': aiConfig.model,
        },
      };

  factory DictSettings.fromJson(Map<String, dynamic> json) {
    DictSourcePreference parseSource(String? value) {
      switch (value) {
        case 'bing':
          return DictSourcePreference.bing;
        case 'youdao':
          return DictSourcePreference.youdao;
        case 'ai':
          return DictSourcePreference.ai;
        default:
          return DictSourcePreference.auto;
      }
    }

    final ai = json['aiConfig'];
    return DictSettings(
      preferredSource: parseSource(json['preferredSource'] as String?),
      aiConfig: ai is Map<String, dynamic>
          ? AiDictConfig(
              baseUrl: (ai['baseUrl'] ?? '').toString(),
              apiKey: (ai['apiKey'] ?? '').toString(),
              model: (ai['model'] ?? '').toString(),
            )
          : const AiDictConfig(),
    );
  }
}
