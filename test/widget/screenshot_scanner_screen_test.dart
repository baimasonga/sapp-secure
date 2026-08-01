import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salone_shield/features/message_analysis/application/analysis_controller.dart';
import 'package:salone_shield/features/screenshot_analysis/presentation/screenshot_scanner_screen.dart';
import 'package:salone_shield/l10n/app_localizations.dart';
import 'package:salone_shield/services/risk_engine/models/risk_level.dart';

import '../support/fake_screenshot_pipeline.dart';
import '../support/test_harness.dart';

void main() {
  late AppLocalizations l10n;

  setUp(() async => l10n = await localisationsFor('en'));

  Future<FakeScreenshotPicker> pumpScanner(
    WidgetTester tester, {
    required FakeTextRecogniser recogniser,
    String? imagePath,
    bool pickerThrows = false,
  }) async {
    final picker = FakeScreenshotPicker(
      path: imagePath,
      throwOnPick: pickerThrows,
    );
    await tester.pumpWidget(
      wrapForTest(
        const ScreenshotScannerScreen(),
        preferences: await createOnboardedPreferences(),
        overrides: screenshotOverrides(picker: picker, recogniser: recogniser),
      ),
    );
    await tester.pumpAndSettle();
    return picker;
  }

  Future<void> choose(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, l10n.screenshotChoose));
    await tester.pumpAndSettle();
  }

  testWidgets('promises up front that the picture is not uploaded', (
    tester,
  ) async {
    await pumpScanner(tester, recogniser: FakeTextRecogniser());

    expect(find.text(l10n.screenshotPrivacyNote), findsOneWidget);
  });

  testWidgets(
    'recognised text is shown for review, not analysed straight away',
    (tester) async {
      final image = FakeScreenshotPicker.createTempImage();
      addTearDown(() => image.parent.deleteSync(recursive: true));

      await pumpScanner(
        tester,
        recogniser: FakeTextRecogniser(text: 'Send me the code urgently'),
        imagePath: image.path,
      );
      await choose(tester);

      expect(find.text(l10n.screenshotReviewTitle), findsWidgets);
      expect(find.text('Send me the code urgently'), findsOneWidget);
      // Nothing has been analysed yet.
      expect(
        containerOf(tester).read(analysisControllerProvider),
        isA<AnalysisIdle>(),
      );
    },
  );

  testWidgets('the app deletes its copy of the picture after reading it', (
    tester,
  ) async {
    final image = FakeScreenshotPicker.createTempImage();
    addTearDown(() {
      if (image.parent.existsSync()) image.parent.deleteSync(recursive: true);
    });

    final picker = await pumpScanner(
      tester,
      recogniser: FakeTextRecogniser(text: 'send money'),
      imagePath: image.path,
    );
    await choose(tester);

    expect(picker.deleteCalls, 1);
    expect(image.existsSync(), isFalse);
  });

  testWidgets('the copy is deleted even when recognition fails', (
    tester,
  ) async {
    final image = FakeScreenshotPicker.createTempImage();
    addTearDown(() {
      if (image.parent.existsSync()) image.parent.deleteSync(recursive: true);
    });

    final picker = await pumpScanner(
      tester,
      recogniser: FakeTextRecogniser(throwFailure: true),
      imagePath: image.path,
    );
    await choose(tester);

    expect(find.text(l10n.screenshotFailed), findsOneWidget);
    expect(picker.deleteCalls, 1);
    expect(image.existsSync(), isFalse);
  });

  testWidgets('an unreadable picture says so instead of showing an empty box', (
    tester,
  ) async {
    final image = FakeScreenshotPicker.createTempImage();
    addTearDown(() {
      if (image.parent.existsSync()) image.parent.deleteSync(recursive: true);
    });

    await pumpScanner(
      tester,
      recogniser: FakeTextRecogniser(text: ''),
      imagePath: image.path,
    );
    await choose(tester);

    expect(find.text(l10n.screenshotEmpty), findsOneWidget);
  });

  testWidgets('cancelling the picker changes nothing', (tester) async {
    await pumpScanner(tester, recogniser: FakeTextRecogniser());
    await choose(tester);

    expect(find.text(l10n.screenshotReviewTitle), findsNothing);
    expect(find.text(l10n.screenshotFailed), findsNothing);
  });

  testWidgets('corrected text is what gets analysed', (tester) async {
    final image = FakeScreenshotPicker.createTempImage();
    addTearDown(() {
      if (image.parent.existsSync()) image.parent.deleteSync(recursive: true);
    });

    await pumpScanner(
      tester,
      // OCR mangled the message; the user fixes it before analysing.
      recogniser: FakeTextRecogniser(text: 'Send rne the c0de'),
      imagePath: image.path,
    );
    await choose(tester);

    await tester.enterText(
      find.byType(TextField),
      'Send me the verification code urgently',
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, l10n.screenshotAnalyse));
    await tester.pumpAndSettle();

    final state = containerOf(tester).read(analysisControllerProvider);
    expect(state, isA<AnalysisSuccess>());
    expect((state as AnalysisSuccess).assessment.level, RiskLevel.critical);
  });

  testWidgets('a picker failure is reported without losing the screen', (
    tester,
  ) async {
    await pumpScanner(
      tester,
      recogniser: FakeTextRecogniser(),
      pickerThrows: true,
    );
    await choose(tester);

    expect(find.text(l10n.screenshotUnsupported), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, l10n.screenshotChoose),
      findsOneWidget,
    );
  });
}
