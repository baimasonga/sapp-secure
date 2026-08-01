import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:salone_shield/app/providers.dart';
import 'package:salone_shield/core/errors/app_failure.dart';
import 'package:salone_shield/services/images/screenshot_picker_service.dart';
import 'package:salone_shield/services/ocr/text_recogniser.dart';

/// A recogniser that returns whatever the test tells it to.
///
/// ML Kit needs a real device, so the screenshot feature is tested against
/// this instead. [seenPaths] lets a test assert which file was read.
class FakeTextRecogniser implements TextRecogniser {
  FakeTextRecogniser({this.text = '', this.throwFailure = false});

  String text;
  bool throwFailure;
  final List<String> seenPaths = [];
  bool disposed = false;

  @override
  Future<String> recognise(String imagePath) async {
    seenPaths.add(imagePath);
    if (throwFailure) {
      throw const AnalysisFailure(debugMessage: 'test failure');
    }
    return text;
  }

  @override
  Future<void> dispose() async => disposed = true;
}

/// A picker that hands back a real temporary file, so deletion can be checked.
class FakeScreenshotPicker extends ScreenshotPickerService {
  FakeScreenshotPicker({this.path, this.throwOnPick = false})
    : super(picker: _UnusedImagePicker());

  /// Null means the user cancelled.
  String? path;
  bool throwOnPick;
  int deleteCalls = 0;

  @override
  Future<String?> pickScreenshot() async {
    if (throwOnPick) throw const FileSystemException('picker exploded');
    final chosen = path;
    if (chosen == null) return null;
    return ScreenshotPickerService.isSupported(chosen) ? chosen : null;
  }

  /// Deletes synchronously on purpose. Real async file I/O never completes
  /// under the test framework's fake clock, which would stall the caller's
  /// await chain and make the screen look frozen.
  @override
  Future<void> deleteCopy(String path) async {
    deleteCalls++;
    final file = File(path);
    if (file.existsSync()) file.deleteSync();
  }

  /// Creates a throwaway file that stands in for the picked screenshot.
  static File createTempImage([String name = 'shot.png']) {
    final file = File(
      '${Directory.systemTemp.createTempSync('salone_shield_test').path}/$name',
    );
    file.writeAsBytesSync(const [0x89, 0x50, 0x4e, 0x47]);
    return file;
  }
}

/// Never used: [FakeScreenshotPicker] overrides everything that touches it.
class _UnusedImagePicker implements ImagePicker {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('The test picker must not reach the platform.');
}

/// Overrides both halves of the screenshot pipeline.
List<Override> screenshotOverrides({
  required FakeScreenshotPicker picker,
  required FakeTextRecogniser recogniser,
}) => [
  screenshotPickerServiceProvider.overrideWithValue(picker),
  textRecogniserProvider.overrideWithValue(recogniser),
];
