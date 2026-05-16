import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/card_entry_model.dart';

/// 卡片条目数据状态
class CardDataState {
  final List<CardEntryModel> entries;

  const CardDataState({this.entries = const []});
}

/// 卡片数据 Notifier
class CardDataNotifier extends Notifier<CardDataState> {
  @override
  CardDataState build() => CardDataState(
        entries: [
          CardEntryModel(
            id: '1',
            word: 'example',
            phonetic: '/ɪɡˈzæmp(ə)l/',
            pos: 'n.',
            meaning: '例子；实例',
            example: 'This is an example sentence.',
          ),
        ],
      );

  void setEntries(List<CardEntryModel> entries) {
    state = CardDataState(entries: entries);
  }

  void addEntry(CardEntryModel entry) {
    state = CardDataState(entries: [...state.entries, entry]);
  }

  void removeEntry(String id) {
    state = CardDataState(
      entries: state.entries.where((e) => e.id != id).toList(),
    );
  }

  void clear() {
    state = const CardDataState();
  }
}

/// 卡片数据 Provider
final cardDataProvider =
    NotifierProvider<CardDataNotifier, CardDataState>(CardDataNotifier.new);
