import 'package:flutter_test/flutter_test.dart';
import 'package:salone_shield/features/link_analysis/application/link_check_controller.dart';
import 'package:salone_shield/services/images/screenshot_picker_service.dart';

import '../support/fake_screenshot_pipeline.dart';

void main() {
  group('supported screenshot formats (section 13)', () {
    test('accepts PNG, JPG, JPEG and WEBP', () {
      for (final path in [
        '/tmp/a.png',
        '/tmp/a.jpg',
        '/tmp/a.jpeg',
        '/tmp/a.webp',
        '/tmp/A.PNG',
      ]) {
        expect(ScreenshotPickerService.isSupported(path), isTrue, reason: path);
      }
    });

    test('rejects anything else', () {
      for (final path in [
        '/tmp/a.pdf',
        '/tmp/a.gif',
        '/tmp/a',
        '/tmp/a.heic',
      ]) {
        expect(
          ScreenshotPickerService.isSupported(path),
          isFalse,
          reason: path,
        );
      }
    });
  });

  group('deleting the app copy', () {
    test('removes the file', () async {
      final image = FakeScreenshotPicker.createTempImage();
      addTearDown(() {
        if (image.parent.existsSync()) image.parent.deleteSync(recursive: true);
      });

      await ScreenshotPickerService().deleteCopy(image.path);

      expect(image.existsSync(), isFalse);
    });

    test('a missing file is not an error', () async {
      await expectLater(
        ScreenshotPickerService().deleteCopy('/tmp/definitely-not-here.png'),
        completes,
      );
    });
  });

  group('link check controller', () {
    late LinkCheckController controller;

    setUp(() => controller = LinkCheckController());

    test('starts idle', () {
      expect(controller.state, isA<LinkCheckIdle>());
    });

    test('rejects empty input', () {
      controller.check('   ');
      expect(controller.state, isA<LinkCheckFailed>());
    });

    test('rejects a sentence with no link in it', () {
      controller.check('please call me back tomorrow');
      expect(controller.state, isA<LinkCheckFailed>());
    });

    test('rejects a token with no dot in it', () {
      controller.check('notalink');
      expect(controller.state, isA<LinkCheckFailed>());
    });

    test('rejects input past the length limit', () {
      controller.check(
        'https://example.com/${'a' * LinkCheckController.maxLength}',
      );
      final state = controller.state;
      expect(state, isA<LinkCheckFailed>());
    });

    test('finds the link inside a pasted message', () {
      controller.check('Claim now at https://claim-now.tk/win before midnight');
      final state = controller.state as LinkCheckDone;
      expect(state.analysis.host, 'claim-now.tk');
    });

    test('accepts a bare host', () {
      controller.check('whatsapp-verify.tk');
      final state = controller.state as LinkCheckDone;
      expect(state.analysis.host, 'whatsapp-verify.tk');
      expect(state.analysis.impersonatedBrand, 'whatsapp');
    });

    test('a clean link produces no findings', () {
      controller.check('https://www.gov.sl/news');
      final state = controller.state as LinkCheckDone;
      expect(state.analysis.isSuspicious, isFalse);
    });

    test('reset returns to idle', () {
      controller.check('https://example.com');
      controller.reset();
      expect(controller.state, isA<LinkCheckIdle>());
    });
  });
}
