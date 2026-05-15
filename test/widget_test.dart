import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ankihelper/app.dart';

void main() {
  testWidgets('App should render MainScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: AnkiHelperApp()));
    expect(find.byType(MainScreen), findsOneWidget);
  });
}
