import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        body: ToastOverlay(child: MainScreen(tokens: tokens)),
      ),
    );
  }
}

class MainScreen extends StatelessWidget {
  final FluentTokens tokens;

  const MainScreen({super.key, required this.tokens});

  @override
  Widget build(BuildContext context) {
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
                  ClipboardSection(),
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
          StatusBar(),
        ],
      ),
    );
  }
}
