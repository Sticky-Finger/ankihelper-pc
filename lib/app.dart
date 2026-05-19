import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/anki_connect_provider.dart';
import 'providers/toast_provider.dart';
import 'theme/fluent_tokens.dart';
import 'theme/theme_provider.dart';
import 'widgets/clipboard_section.dart';
import 'widgets/results_list.dart';
import 'widgets/status_bar.dart';
import 'widgets/title_bar.dart';
import 'widgets/toast_notification.dart';
import 'widgets/word_blocks_section.dart';

class AnkiHelperApp extends ConsumerWidget {
  const AnkiHelperApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ref.watch(fluentTokensProvider);

    return MaterialApp(
      title: 'Anki划词助手',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: tokens.bgApp,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: tokens.bgApp,
      ),
      themeMode: tokens.isDark ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        backgroundColor: tokens.bgApp,
        body: ToastOverlay(child: MainScreen()),
      ),
    );
  }
}

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ref.watch(fluentTokensProvider);
    final ankiStatus = ref.watch(ankiConnectionStatusProvider);

    // 根据连接状态构建 StatusItem
    final ankiStatusItem = ankiStatus.when(
      loading: () => const StatusItem(
        label: 'AnkiConnect: 检测中…',
        level: StatusLevel.warning,
      ),
      data: (status) => status.connected
          ? const StatusItem(
              label: 'AnkiConnect: 已连接',
              level: StatusLevel.success,
            )
          : StatusItem(
              label: 'AnkiConnect: ${status.errorMessage ?? '未连接'}',
              level: StatusLevel.danger,
            ),
      error: (error, _) => StatusItem(
        label: 'AnkiConnect: 错误',
        level: StatusLevel.danger,
      ),
    );

    return Container(
      color: tokens.bgApp,
      width: double.infinity,
      height: double.infinity,
      child: Column(
        children: [
          TitleBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(FluentTokens.spaceL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipboardSection(
                    onRefreshTranslation: () =>
                        ref.read(toastProvider.notifier).show('翻译已刷新'),
                  ),
                  const SizedBox(height: FluentTokens.spaceL),
                  WordBlocksSection(),
                  const SizedBox(height: FluentTokens.spaceXs),
                  // 分隔线
                  Container(
                    height: FluentTokens.strokeWidthThin,
                    color: tokens.stroke3,
                    margin: const EdgeInsets.symmetric(
                      vertical: FluentTokens.spaceXs,
                    ),
                  ),
                  const SizedBox(height: FluentTokens.spaceM),
                  ResultsList(),
                ],
              ),
            ),
          ),
          StatusBar(
            ankiStatus: ankiStatusItem,
            onAnkiStatusTap: () {
              ref.read(ankiConnectionStatusProvider.notifier).refresh();
            },
          ),
        ],
      ),
    );
  }
}
