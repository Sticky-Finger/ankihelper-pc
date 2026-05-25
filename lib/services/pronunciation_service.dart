import 'package:audioplayers/audioplayers.dart';

/// 发音源数据模型
class PronunciationSource {
  final String id;
  final String name;
  final String urlTemplate;
  final bool isBuiltin;

  const PronunciationSource({
    required this.id,
    required this.name,
    required this.urlTemplate,
    this.isBuiltin = false,
  });

  /// 从 JSON 反序列化
  factory PronunciationSource.fromJson(Map<String, dynamic> json) {
    return PronunciationSource(
      id: json['id'] as String,
      name: json['name'] as String,
      urlTemplate: json['urlTemplate'] as String,
      isBuiltin: json['isBuiltin'] as bool? ?? false,
    );
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'urlTemplate': urlTemplate,
        'isBuiltin': isBuiltin,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PronunciationSource &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// 内置发音源列表
const List<PronunciationSource> builtinPronunciationSources = [
  PronunciationSource(
    id: 'youdao_br',
    name: '有道英音',
    urlTemplate: 'https://dict.youdao.com/dictvoice?audio={word}&type=0',
    isBuiltin: true,
  ),
  PronunciationSource(
    id: 'youdao_am',
    name: '有道美音',
    urlTemplate: 'https://dict.youdao.com/dictvoice?audio={word}&type=1',
    isBuiltin: true,
  ),
];

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
