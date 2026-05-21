import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/translation_config_model.dart';
import '../providers/translation_provider.dart';

/// 显示设置弹窗
void showSettingsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => const _SettingsDialog(),
  );
}

class _SettingsDialog extends ConsumerStatefulWidget {
  const _SettingsDialog();

  @override
  ConsumerState<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends ConsumerState<_SettingsDialog> {
  late TranslationConfig _config;

  @override
  void initState() {
    super.initState();
    _config = ref.read(translationProvider.notifier).config;
  }

  void _onProviderChanged(TranslationProvider? value) {
    if (value != null) {
      setState(() => _config = _config.copyWith(provider: value));
    }
  }

  void _onAppIdChanged(String value) {
    setState(() => _config = _config.copyWith(appId: value));
  }

  void _onAppSecretChanged(String value) {
    setState(() => _config = _config.copyWith(appSecret: value));
  }

  void _onSave() {
    ref.read(translationProvider.notifier).saveConfig(_config);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('翻译配置已保存')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('设置'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ====== 词典管理 ======
            const Text(
              '词典管理',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text('（暂无词典 — 功能即将上线）',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            // ====== 牌组选择 ======
            const Text(
              '牌组选择',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text('（默认牌组 — 功能即将上线）',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            // ====== 翻译 API 配置 ======
            const Text(
              '翻译 API 配置',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 12),
            // 服务商选择
            DropdownButtonFormField<TranslationProvider>(
              initialValue: _config.provider,
              decoration: const InputDecoration(
                labelText: '翻译服务商',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: TranslationProvider.baidu,
                  child: Text('百度翻译'),
                ),
                DropdownMenuItem(
                  value: TranslationProvider.youdao,
                  child: Text('有道智云'),
                ),
              ],
              onChanged: _onProviderChanged,
            ),
            const SizedBox(height: 12),
            // APP ID / 应用ID
            TextField(
              decoration: InputDecoration(
                labelText: _config.provider == TranslationProvider.baidu
                    ? 'APP ID'
                    : '应用 ID',
                border: const OutlineInputBorder(),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              onChanged: _onAppIdChanged,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            // 密钥 / 应用密钥
            TextField(
              decoration: InputDecoration(
                labelText: _config.provider == TranslationProvider.baidu
                    ? '密钥'
                    : '应用密钥',
                border: const OutlineInputBorder(),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              obscureText: true,
              onChanged: _onAppSecretChanged,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _onSave(),
            ),
            const SizedBox(height: 8),
            // 配置提示
            Text(
              _config.provider == TranslationProvider.baidu
                  ? '获取百度翻译 API 凭证: https://api.fanyi.baidu.com/'
                  : '获取有道智云 API 凭证: https://ai.youdao.com/',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _onSave,
          child: const Text('保存'),
        ),
      ],
    );
  }
}
