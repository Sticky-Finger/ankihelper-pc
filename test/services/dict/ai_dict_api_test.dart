import 'package:ankihelper/services/dict/ai_dict_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('renderDictUserPrompt — 占位符替换', () {
    test('替换 text/context，页面级字段填空', () {
      final prompt = renderDictUserPrompt(
        text: 'library',
        context: 'I borrowed a book from the library.',
      );
      expect(prompt.contains('{{'), isFalse);
      expect(prompt, contains('I borrowed a book from the library.'));
      expect(prompt, endsWith('library'));
      expect(prompt, contains('Document title: \n'));
    });

    test('空语境也合法', () {
      final prompt = renderDictUserPrompt(text: 'go', context: '');
      expect(prompt, contains('[Target]'));
      expect(prompt, endsWith('go'));
    });
  });

  group('defaultDictSystemPrompt — 输出契约', () {
    test('包含智能路由与中文标签', () {
      final prompt = defaultDictSystemPrompt;
      expect(prompt, contains('Smart routing'));
      expect(prompt, contains('词条'));
      expect(prompt, contains('词性与核心义项'));
      expect(prompt, contains('语料库双解例句'));
      expect(prompt, contains('Dictionary mode'));
      expect(prompt, contains('Pure translation mode'));
    });
  });

  group('AiDictConfig', () {
    test('isConfigured 判定', () {
      expect(const AiDictConfig().isConfigured, isFalse);
      expect(
        const AiDictConfig(
                baseUrl: 'https://api.deepseek.com',
                apiKey: 'sk-x',
                model: 'deepseek-chat')
            .isConfigured,
        isTrue,
      );
      expect(
        const AiDictConfig(baseUrl: 'https://x', apiKey: '', model: 'm')
            .isConfigured,
        isFalse,
      );
    });

    test('chatCompletionsUrl 规范化', () {
      expect(
        const AiDictConfig(baseUrl: 'https://api.deepseek.com')
            .chatCompletionsUrl,
        'https://api.deepseek.com/chat/completions',
      );
      expect(
        const AiDictConfig(baseUrl: 'https://api.x.com/v1/')
            .chatCompletionsUrl,
        'https://api.x.com/v1/chat/completions',
      );
      expect(
        const AiDictConfig(baseUrl: 'https://api.x.com/v1/chat/completions')
            .chatCompletionsUrl,
        'https://api.x.com/v1/chat/completions',
      );
    });
  });

  group('extractStreamDelta', () {
    test('OpenAI 兼容 delta 提取', () {
      const json = {
        'id': 'x',
        'choices': [
          {
            'delta': {'content': '词'}
          }
        ]
      };
      expect(extractStreamDelta(json), '词');
    });

    test('无 content / 结构异常返回空串', () {
      expect(extractStreamDelta({'choices': []}), '');
      expect(extractStreamDelta({
        'choices': [
          {'delta': {}}
        ]
      }), '');
      expect(extractStreamDelta({}), '');
      expect(extractStreamDelta({'choices': 'bad'}), '');
    });
  });

  group('extractSsePayloads — 分块容错', () {
    test('完整块解析', () {
      final (payloads, remain) =
          extractSsePayloads('data: {"a":1}\n\ndata: [DONE]\n\n');
      expect(payloads, ['{"a":1}', '[DONE]']);
      expect(remain, '');
    });

    test('半截行留待下个块', () {
      // 模拟流在 JSON 行中间被切开：第一块无换行，第二块无前导换行
      final (p1, r1) = extractSsePayloads('data: {"choices":[{"del');
      expect(p1, isEmpty);
      expect(r1, 'data: {"choices":[{"del');

      final (p2, r2) = extractSsePayloads('$r1''ta":{"content":"x"}}]\n\n');
      expect(p2, ['{"choices":[{"delta":{"content":"x"}}]']);
      expect(r2, '');
    });

    test('忽略非 data 行', () {
      final (payloads, _) =
          extractSsePayloads(': keep-alive\n event: message\ndata: x\n\n');
      expect(payloads, ['x']);
    });
  });

  group('stripMarkdownCodeBlock', () {
    test('剥开头围栏（含语言标记）', () {
      expect(stripMarkdownCodeBlock('```markdown\n# 词条'), '# 词条');
      expect(stripMarkdownCodeBlock('```\n内容'), '内容');
    });

    test('startOnly 不剥结尾围栏', () {
      const text = '# 词条\n```';
      expect(stripMarkdownCodeBlock(text, startOnly: true), text);
      expect(stripMarkdownCodeBlock(text), '# 词条');
    });

    test('无围栏原样返回 / 空串安全', () {
      expect(stripMarkdownCodeBlock('普通文本'), '普通文本');
      expect(stripMarkdownCodeBlock(''), '');
    });
  });
}
