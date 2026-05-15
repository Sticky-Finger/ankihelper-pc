import 'package:flutter/material.dart';

class AnkiHelperApp extends StatelessWidget {
  const AnkiHelperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Anki划词助手',
      debugShowCheckedModeBanner: false,
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        // TODO: TitleBar
        // TODO: ClipboardSection
        // TODO: WordBlocksSection
        // TODO: ResultsList
        // TODO: StatusBar
      ],
    );
  }
}
