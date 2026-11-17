import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ask_jeeves_vmi/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: AskJeevesVaultApp(),
      ),
    );

    // Verify that the app starts
    expect(find.byType(MaterialApp), findsOneWidget);
    
    // Pump frames to let the splash screen timer (1.5s) complete
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump(const Duration(milliseconds: 500));
  });
}
