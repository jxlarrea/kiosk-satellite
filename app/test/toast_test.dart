import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kiosk_satellite/ui/theme.dart';
import 'package:kiosk_satellite/ui/toast.dart';

void main() {
  Widget host() => MaterialApp(
    theme: buildTheme(Brightness.dark),
    home: const Scaffold(body: SizedBox.expand()),
  );

  testWidgets('shows title, message and kind icon, then auto-dismisses', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    showToast(
      tester.element(find.byType(Scaffold)),
      title: 'Download failed',
      message: 'report.pdf',
      kind: ToastKind.error,
      duration: const Duration(seconds: 2),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Download failed'), findsOneWidget);
    expect(find.text('report.pdf'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Download failed'), findsNothing);
  });

  testWidgets('a new toast replaces the current one', (tester) async {
    await tester.pumpWidget(host());
    final context = tester.element(find.byType(Scaffold));
    showToast(context, title: 'First', sticky: true);
    await tester.pump();
    showToast(context, title: 'Second', sticky: true);
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('First'), findsNothing);
    expect(find.text('Second'), findsOneWidget);
    dismissToast();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Second'), findsNothing);
  });

  testWidgets('toast without an action lets taps pass through', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    showToast(
      tester.element(find.byType(Scaffold)),
      title: 'Hold mode on',
      duration: const Duration(seconds: 1),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    final ignore = tester.widget<IgnorePointer>(
      find.ancestor(
        of: find.text('Hold mode on'),
        matching: find.byType(IgnorePointer),
      ),
    );
    expect(ignore.ignoring, isTrue);
    await tester.pump(const Duration(milliseconds: 1500));
  });

  testWidgets('action button fires the callback and dismisses', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    var opened = false;
    showToast(
      tester.element(find.byType(Scaffold)),
      title: 'Download complete',
      message: 'manual.pdf',
      kind: ToastKind.success,
      sticky: true,
      actionLabel: 'Open',
      onAction: () => opened = true,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(opened, isTrue);
    expect(find.text('Download complete'), findsNothing);
  });
}
