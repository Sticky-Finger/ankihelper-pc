import 'package:audioplayers/audioplayers.dart';

/// 发音源枚举
enum PronunciationSource {
  youdaoBrE,
  youdaoAmE,
}

/// 发音源元数据
extension PronunciationSourceMeta on PronunciationSource {
  String get label {
    switch (this) {
      case PronunciationSource.youdaoBrE:
        return '有道英音';
      case PronunciationSource.youdaoAmE:
        return '有道美音';
    }
  }

  /// 发音 URL 模板，{word} 为占位符
  String get urlTemplate {
    switch (this) {
      case PronunciationSource.youdaoBrE:
        return 'https://dict.youdao.com/dictvoice?audio={word}&type=0';
      case PronunciationSource.youdaoAmE:
        return 'https://dict.youdao.com/dictvoice?audio={word}&type=1';
    }
  }
}

/// 发音服务：提供 URL 拼装功能
class PronunciationService {
  /// 根据单词和发音源生成发音 URL
  static String getUrl(String word, PronunciationSource source) {
    final encoded = Uri.encodeComponent(word);
    return source.urlTemplate.replaceAll('{word}', encoded);
  }
}

/// 发音播放器：封装 AudioPlayer 的播放逻辑
class PronunciationPlayer {
  PronunciationPlayer._();

  static final AudioPlayer _player = AudioPlayer();

  /// 播放指定单词的发音
  /// [word] 为空时使用 "test" 作为测试词
  static Future<void> play(String word, PronunciationSource source) async {
    final targetWord = word.isEmpty ? 'test' : word.trim();
    final url = PronunciationService.getUrl(targetWord, source);
    await _player.stop();
    await _player.play(UrlSource(url));
  }

  /// 释放播放器资源
  static void dispose() {
    _player.dispose();
  }
}
