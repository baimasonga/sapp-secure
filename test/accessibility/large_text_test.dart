import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salone_shield/app/theme.dart';
import 'package:salone_shield/features/dashboard/presentation/home_screen.dart';
import 'package:salone_shield/features/message_analysis/presentation/analyse_message_screen.dart';
import 'package:salone_shield/features/notification_monitoring/presentation/notification_monitoring_screen.dart';
import 'package:salone_shield/features/settings/presentation/settings_screen.dart';
import 'package:salone_shield/features/trusted_contacts/presentation/trusted_contacts_screen.dart';

import '../support/test_harness.dart';
import 'contrast_test.dart' show contrastRatio;

/// The app at the font sizes people actually use.
///
/// Android's display settings go to 200%, and the audience for this app skews
/// towards people who turn them up. A layout that overflows at that size is
/// not a cosmetic problem: the overflowing part is usually the end of the
/// sentence, and on these screens the end of the sentence is the advice.
///
/// A RenderFlex overflow raises a Flutter error during paint, so these tests
/// fail by themselves when something breaks — there is nothing to assert
/// beyond getting the frame painted.
///
/// **The surface size is part of the test.** These ran at the default 800x600
/// for a while, which is wider than any phone, and a dashboard that overflowed
/// by 178 pixels on a real handset passed every one of them. A layout bug that
/// depends on width cannot be found on a surface no user has.

/// A 6-inch Android phone: 1080x2400 at 3x, which is 360x800 in logical
/// pixels and close to the middle of the range this app is used on.
void usePhoneSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

Widget atScale(Widget child, double scale, {required dynamic preferences}) =>
    wrapForTest(
      Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child,
        ),
      ),
      preferences: preferences,
    );

void main() {
  // 2.0 is Android's maximum without "even larger" accessibility sizing.
  const scales = [1.3, 2.0];

  for (final scale in scales) {
    group('at ${(scale * 100).round()}% text', () {
      testWidgets('the dashboard survives', (tester) async {
        usePhoneSurface(tester);
        await tester.pumpWidget(
          atScale(
            const HomeScreen(),
            scale,
            preferences: await createOnboardedPreferences(),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(HomeScreen), findsOneWidget);
      });

      testWidgets('the analyser survives', (tester) async {
        usePhoneSurface(tester);
        await tester.pumpWidget(
          atScale(
            const AnalyseMessageScreen(),
            scale,
            preferences: await createTestPreferences(),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(AnalyseMessageScreen), findsOneWidget);
      });

      testWidgets('settings survives', (tester) async {
        usePhoneSurface(tester);
        await tester.pumpWidget(
          atScale(
            const SettingsScreen(),
            scale,
            preferences: await createTestPreferences(),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(SettingsScreen), findsOneWidget);
      });

      testWidgets('trusted contacts survives', (tester) async {
        usePhoneSurface(tester);
        await tester.pumpWidget(
          atScale(
            const TrustedContactsScreen(),
            scale,
            preferences: await createTestPreferences(),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(TrustedContactsScreen), findsOneWidget);
      });

      testWidgets('the notification screen survives', (tester) async {
        usePhoneSurface(tester);
        await tester.pumpWidget(
          atScale(
            const NotificationMonitoringScreen(),
            scale,
            preferences: await createTestPreferences(),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(NotificationMonitoringScreen), findsOneWidget);
      });

      testWidgets('the risk result survives, including the meter', (
        tester,
      ) async {
        usePhoneSurface(tester);
        final preferences = await createTestPreferences();
        final l10n = await localisationsFor('en');
        await tester.pumpWidget(
          atScale(
            const AnalyseMessageScreen(),
            scale,
            preferences: preferences,
          ),
        );
        await tester.enterText(
          find.byType(TextField),
          'I mistakenly sent a six digit code to your phone. Send it urgently.',
        );
        await tester.pump();
        // At this size the button starts below the fold, which is expected;
        // what matters is that it is reachable and the result then paints.
        await scrollTo(
          tester,
          find.widgetWithText(FilledButton, l10n.analyseRun),
        );
        await tester.tap(find.widgetWithText(FilledButton, l10n.analyseRun));
        await tester.pumpAndSettle();

        // The four-segment meter is the tightest row in the app: four labels
        // side by side, each of which grows with the text scale.
        expect(find.text(l10n.riskLevelCritical), findsOneWidget);
      });
    });
  }

  group('touch targets', () {
    testWidgets('the primary action is at least 48dp tall', (tester) async {
      usePhoneSurface(tester);
      await tester.pumpWidget(
        wrapForTest(
          const HomeScreen(),
          preferences: await createOnboardedPreferences(),
        ),
      );
      await tester.pumpAndSettle();

      final button = tester.getSize(find.byType(FilledButton).first);
      // The theme asks for 54, above the 48 platform guidance, because the
      // audience includes people tapping in a hurry on a cheap screen.
      expect(button.height, greaterThanOrEqualTo(48));
      expect(button.height, greaterThanOrEqualTo(AppTheme.minTouchTarget));
    });

    testWidgets('every icon button on the dashboard is reachable', (
      tester,
    ) async {
      usePhoneSurface(tester);
      await tester.pumpWidget(
        wrapForTest(
          const HomeScreen(),
          preferences: await createOnboardedPreferences(),
        ),
      );
      await tester.pumpAndSettle();

      for (final element in find.byType(IconButton).evaluate()) {
        final size = tester.getSize(find.byWidget(element.widget));
        expect(
          size.width,
          greaterThanOrEqualTo(48),
          reason: 'an icon button is only ${size.width}dp wide',
        );
        expect(size.height, greaterThanOrEqualTo(48));
      }
    });
  });

  group('screen readers', () {
    testWidgets('the risk banner reads as one sentence, not scattered parts', (
      tester,
    ) async {
      usePhoneSurface(tester);
      final handle = tester.ensureSemantics();
      final preferences = await createTestPreferences();
      final l10n = await localisationsFor('en');

      await tester.pumpWidget(
        wrapForTest(const AnalyseMessageScreen(), preferences: preferences),
      );
      await tester.enterText(
        find.byType(TextField),
        'I mistakenly sent a six digit code to your phone. Send it urgently.',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, l10n.analyseRun));
      await tester.pumpAndSettle();

      // The level, the score and the summary belong together: read apart,
      // "75" and "critical" and the explanation are three separate noises.
      expect(
        find.bySemanticsLabel(RegExp(r'Critical risk\. Risk score 75')),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('the settings icon says what it is', (tester) async {
      usePhoneSurface(tester);
      final handle = tester.ensureSemantics();
      final l10n = await localisationsFor('en');
      await tester.pumpWidget(
        wrapForTest(
          const HomeScreen(),
          preferences: await createOnboardedPreferences(),
        ),
      );
      await tester.pumpAndSettle();

      // An unlabelled icon button is read out as "button", which tells a
      // screen-reader user nothing. A tooltip is not enough on its own: it is
      // a hover affordance, and there is no hover on a phone.
      expect(find.bySemanticsLabel(l10n.settingsTitle), findsWidgets);
      handle.dispose();
    });
  });

  test('the contrast helper itself is right', () {
    // A self-check on the maths the rest of the audit depends on: black on
    // white is the known 21:1, and a colour against itself is 1:1.
    expect(
      contrastRatio(const Color(0xFF000000), const Color(0xFFFFFFFF)),
      closeTo(21, 0.01),
    );
    expect(
      contrastRatio(const Color(0xFF777777), const Color(0xFF777777)),
      closeTo(1, 0.001),
    );
  });
}
