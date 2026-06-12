// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mandato_novo/main.dart';
import 'package:mandato_novo/services/app_state.dart';

void main() {
  testWidgets('Login page is displayed', (WidgetTester tester) async {
    final appState = AppState();
    await tester.pumpWidget(MandatoApp(appState: appState));

    expect(find.text('Acesse o ecossistema digital de notícias políticas e legislativas.'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });
}
