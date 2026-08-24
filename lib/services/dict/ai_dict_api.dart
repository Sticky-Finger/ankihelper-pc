import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// AI 词典接口配置（OpenAI 兼容协议）
class AiDictConfig {
  final String baseUrl;
  final String apiKey;
  final String model;

  const AiDictConfig({
    this.baseUrl = '',
    this.apiKey = '',
    this.model = '',
  });

  bool get isConfigured =>
      baseUrl.trim().isNotEmpty &&
      apiKey.trim().isNotEmpty &&
      model.trim().isNotEmpty;

  /// 规范化 chat/completions 端点：允许用户填根地址或完整端点
  String get chatCompletionsUrl {
    final trimmed = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    if (trimmed.endsWith('/chat/completions')) return trimmed;
    return '$trimmed/chat/completions';
  }

  AiDictConfig copyWith({String? baseUrl, String? apiKey, String? model}) =>
      AiDictConfig(
        baseUrl: baseUrl ?? this.baseUrl,
        apiKey: apiKey ?? this.apiKey,
        model: model ?? this.model,
      );
}

// ---------------------------------------------------------------------------
// 提示词模板（逐字移植自 kiss-translator 提取文档 §3.3，中文 labels 参数化）
// ---------------------------------------------------------------------------

/// 专家级 AI 词典系统提示词（输出契约：词典模式 / 纯翻译模式智能路由）
String createEnglishDictionaryPrompt({
  required String targetLanguage,
  required String translationExample,
  required Map<String, String> labels,
}) {
  return '''
# Role
You are an expert English-$targetLanguage lexicographer specializing in contrastive linguistics and modern corpus linguistics. Analyze the user's English text with academic rigor and clear, elegant formatting, or translate it naturally into $targetLanguage when dictionary analysis is not appropriate.

# Execution Rules
1. **Smart routing (CRITICAL)**: Choose the mode strictly from the length and nature of `[Target]`:
   - **Dictionary mode**: Use the dictionary output format only when `[Target]` is clearly a single English word, an idiom, or a fixed collocation of no more than 3 words.
   - **Pure translation mode**: Use pure translation for complete sentences, clauses, natural-language phrases, paragraphs, long text, or any continuous text longer than 3 words. When uncertain, choose pure translation mode.
2. **Context first**: In dictionary mode, if `[Context]` contains useful information, put the contextually correct sense first.
3. **Target-language contract**: All headings, labels, definitions, explanations, usage notes, and example translations in dictionary mode must be written in $targetLanguage. Keep English only for the entry, English examples, pronunciation, and English words being compared.
4. **No extra framing**: Follow the selected format exactly. Do not add greetings, prefaces, or closing summaries.

---

# Pure Translation Output Contract (only for pure translation mode)

Your entire response must contain only the $targetLanguage translation itself:
- Do not output the source text, bilingual comparison, headings, labels, language names, quotation marks, Markdown, or explanations.
- Do not add prefixes such as "Translation:" or include pronunciation, etymology, collocations, examples, or acknowledgements.
- If the source has one paragraph, output one paragraph. Preserve paragraph breaks only when the source has multiple paragraphs.

Example:
- Input: The library for web and native user interfaces
- Correct output: $translationExample

# Output Format (only for dictionary mode)

## ${labels['entry']}: [original word or phrase]
> [If the form is inflected in `[Context]`, provide its lemma in parentheses.]

### 1. ${labels['essentials']}
- **${labels['pronunciation']}**: 🇺🇸 [US IPA] ｜ 🇬🇧 [UK IPA]
- **${labels['meanings']}**:
  - `[part of speech]` ① [primary $targetLanguage definition] ② [secondary $targetLanguage definition]
  - `[part of speech]` ① [primary $targetLanguage definition]

### 2. ${labels['context']} *[include only when useful Context exists]*
- **${labels['contextMeaning']}**: State the part of speech and precise meaning in the given context.
- **${labels['register']}**: Describe sentiment, register, formality, and tone.
- **${labels['replacements']}**: Give 1-2 English synonyms that can replace the entry in this context without changing the meaning.

### 3. ${labels['deepDive']}
- **${labels['etymology']}**: Explain roots, affixes, historical development, or provide a logical memory aid.
- **${labels['collocations']}**:
  * `[collocation 1]` ➔ [precise $targetLanguage translation]
  * `[collocation 2]` ➔ [precise $targetLanguage translation]
- **${labels['synonyms']}**:
  * **[entry] vs [synonym 1] vs [synonym 2]**: Explain their differences in context, intensity, register, or collocation habits in 1-2 sentences.

### 4. ${labels['examples']}
[Provide 2-3 natural examples from publications, news, professional writing, or everyday English.]

1. **[natural English example]**
   - 💡 *${labels['translation']}*: [accurate, idiomatic $targetLanguage translation]
   - 📌 *${labels['scene']}*: `[localized scene label]`''';
}

/// 默认系统提示词（中文目标语言）
final String defaultDictSystemPrompt = createEnglishDictionaryPrompt(
  targetLanguage: 'Chinese',
  translationExample: '用于 Web 和原生用户界面的库',
  labels: const {
    'entry': '词条',
    'essentials': '基础形态与音标',
    'pronunciation': '发音标注',
    'meanings': '词性与核心义项',
    'context': '语境精析',
    'contextMeaning': '当前语义锁定',
    'register': '语境色调',
    'replacements': '原句平替词',
    'deepDive': '词源深度解构与辨析',
    'etymology': '词源与记忆锚点',
    'collocations': '高频搭配',
    'synonyms': '同义词微观辨析',
    'examples': '语料库双解例句',
    'translation': '中文翻译',
    'scene': '场景标签',
  },
);

/// 用户提示词模板（{{xxx}} 占位符）
const String defaultDictUserPromptTemplate = '''
# Input Data

## [Context] (Optional)
> Use this information to identify the target text's meaning in context:
- Document title: {{title}}
- Document description: {{description}}
- Document summary: {{summary}}
- Surrounding paragraph: {{context}}

## [Target] (Required)
> Use this text to choose between dictionary mode and pure translation mode:
{{text}}''';

/// 渲染用户提示词：{{text}} = 查询单词，{{context}} = 剪贴板原句，
/// 页面级字段（title/description/summary）桌面端无概念，填空串。
String renderDictUserPrompt({required String text, required String context}) {
  return defaultDictUserPromptTemplate
      .replaceAll('{{title}}', '')
      .replaceAll('{{description}}', '')
      .replaceAll('{{summary}}', '')
      .replaceAll('{{context}}', context)
      .replaceAll('{{text}}', text);
}

// ---------------------------------------------------------------------------
// SSE 流式解析（纯函数，便于单测）
// ---------------------------------------------------------------------------

/// 从 SSE 帧的 JSON 中提取文本增量（OpenAI 兼容协议）
String extractStreamDelta(Map<String, dynamic> json) {
  final choices = json['choices'];
  if (choices is List<dynamic> && choices.isNotEmpty) {
    final first = choices[0];
    if (first is Map<String, dynamic>) {
      final delta = first['delta'];
      if (delta is Map<String, dynamic>) {
        return (delta['content'] ?? '').toString();
      }
    }
  }
  return '';
}

/// 从原始流文本块中提取完整的 `data: ` 载荷列表
///
/// 输入为按块到达的原始文本，函数负责按 SSE 事件（空行分隔）切分并缓冲半截事件。
/// [buffer] 为上一次调用后的未完成尾巴，返回 [payloads, remain]。
(List<String>, String) extractSsePayloads(String buffer) {
  final payloads = <String>[];
  final remain = StringBuffer();
  final lines = buffer.split('\n');

  for (var i = 0; i < lines.length; i++) {
    final isLastLine = i == lines.length - 1;
    final line = lines[i];
    // 最后一行没有后续换行 → 属于未完成事件，留待下个块
    if (isLastLine && line.isNotEmpty && !buffer.endsWith('\n')) {
      remain.write(line);
      break;
    }
    final trimmed = line.trimRight();
    if (trimmed.startsWith('data:')) {
      payloads.add(trimmed.substring(5).trim());
    }
    // 其余行（event:/注释/空行）忽略
  }
  return (payloads, remain.toString());
}

/// 剥离 Markdown 代码围栏（模型偶尔把输出包进 ``` 围栏）
///
/// [startOnly] 为 true 时只剥开头围栏（流式期间调用，结尾围栏等流结束再剥）。
String stripMarkdownCodeBlock(String text, {bool startOnly = false}) {
  if (text.isEmpty) return text;
  var result = text.replaceFirst(RegExp(r'^```[a-zA-Z]*[ \t]*\r?\n?'), '');
  if (!startOnly) {
    result = result.replaceFirst(RegExp(r'\r?\n?```$'), '');
  }
  return result;
}

// ---------------------------------------------------------------------------
// AI 词典查询
// ---------------------------------------------------------------------------

/// AI 词典查询（OpenAI 兼容 chat/completions）
///
/// 优先 SSE 流式（[onStreamChunk] 每次推送累积后的全量 Markdown），
/// 流式协议异常时自动降级为非流式请求。
class AiDictApi {
  AiDictApi._();

  static const Duration defaultTimeout = Duration(seconds: 60);

  /// 查询并返回 Markdown 词典卡片全文
  static Future<String> query({
    required AiDictConfig config,
    required String text,
    required String context,
    Duration timeout = defaultTimeout,
    void Function(String markdown)? onStreamChunk,
    http.Client? client,
  }) async {
    if (!config.isConfigured) {
      throw Exception('AI 词典接口未配置');
    }
    if (text.trim().isEmpty) {
      throw Exception('查询文本不能为空');
    }

    final httpClient = client ?? http.Client();
    try {
      if (onStreamChunk != null) {
        try {
          return await _queryStreamed(
            httpClient: httpClient,
            config: config,
            text: text,
            context: context,
            timeout: timeout,
            onStreamChunk: onStreamChunk,
          );
        } on TimeoutException {
          rethrow; // 超时无意义重试非流式（大概率同样超时）
        } catch (e) {
          // 流式协议异常 → 降级非流式，保住功能可用性
          if (kDebugMode) {
            debugPrint('[AiDict] stream failed, fallback to non-stream: $e');
          }
        }
      }
      return await _queryPlain(
        httpClient: httpClient,
        config: config,
        text: text,
        context: context,
        timeout: timeout,
      );
    } finally {
      if (client == null) httpClient.close();
    }
  }

  static Map<String, String> _buildHeaders(AiDictConfig config) => {
        'authorization': 'Bearer ${config.apiKey}',
        'content-type': 'application/json',
      };

  static Map<String, dynamic> _buildBody({
    required AiDictConfig config,
    required String text,
    required String context,
    required bool stream,
  }) =>
      {
        'model': config.model,
        'messages': [
          {'role': 'system', 'content': defaultDictSystemPrompt},
          {
            'role': 'user',
            'content': renderDictUserPrompt(text: text, context: context),
          },
        ],
        'stream': stream,
      };

  static Future<String> _queryStreamed({
    required http.Client httpClient,
    required AiDictConfig config,
    required String text,
    required String context,
    required Duration timeout,
    required void Function(String markdown) onStreamChunk,
  }) async {
    final request = http.Request('POST', Uri.parse(config.chatCompletionsUrl))
      ..headers.addAll(_buildHeaders(config))
      ..body = jsonEncode(
          _buildBody(config: config, text: text, context: context, stream: true));

    final response = await httpClient.send(request).timeout(timeout);
    if (response.statusCode != 200) {
      throw Exception('AI 接口请求失败 (HTTP ${response.statusCode})');
    }

    var full = '';
    var buffer = '';
    await for (final chunk in response.stream.transform(utf8.decoder)) {
      final (payloads, remain) = extractSsePayloads(buffer + chunk);
      buffer = remain;
      for (final payload in payloads) {
        if (payload == '[DONE]') continue;
        Map<String, dynamic>? json;
        try {
          json = jsonDecode(payload) as Map<String, dynamic>;
        } catch (_) {
          continue; // 忽略无法解析的帧
        }
        final delta = extractStreamDelta(json);
        if (delta.isEmpty) continue;
        full += delta;
        // 边收边剥开头围栏，避免 UI 闪出 ```
        onStreamChunk(stripMarkdownCodeBlock(full, startOnly: true));
      }
    }

    final markdown = stripMarkdownCodeBlock(full).trim();
    if (markdown.isEmpty) {
      throw Exception('AI 词典返回为空');
    }
    return markdown;
  }

  static Future<String> _queryPlain({
    required http.Client httpClient,
    required AiDictConfig config,
    required String text,
    required String context,
    required Duration timeout,
  }) async {
    final response = await httpClient
        .post(
          Uri.parse(config.chatCompletionsUrl),
          headers: _buildHeaders(config),
          body: jsonEncode(
              _buildBody(config: config, text: text, context: context, stream: false)),
        )
        .timeout(timeout);

    if (response.statusCode != 200) {
      throw Exception('AI 接口请求失败 (HTTP ${response.statusCode})');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = json['choices'];
    String content = '';
    if (choices is List<dynamic> && choices.isNotEmpty) {
      final first = choices[0];
      if (first is Map<String, dynamic>) {
        final message = first['message'];
        if (message is Map<String, dynamic>) {
          content = (message['content'] ?? '').toString();
        }
      }
    }
    final markdown = stripMarkdownCodeBlock(content).trim();
    if (markdown.isEmpty) {
      throw Exception('AI 词典返回为空');
    }
    return markdown;
  }
}
