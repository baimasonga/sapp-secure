import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/errors/app_failure.dart';

/// Where the screenshot flow has got to.
///
/// The user always sees and can correct the recognised text before anything is
/// analysed (section 13), so "recognised" is a real state with a real screen,
/// not a step that flashes past.
sealed class ScreenshotState {
  const ScreenshotState();
}

class ScreenshotIdle extends ScreenshotState {
  const ScreenshotIdle();
}

class ScreenshotReading extends ScreenshotState {
  const ScreenshotReading();
}

/// OCR finished. [text] is editable before it is analysed.
class ScreenshotRecognised extends ScreenshotState {
  const ScreenshotRecognised({required this.text, required this.wasEmpty});

  final String text;

  /// True when the image contained no readable text — a normal outcome worth
  /// saying plainly rather than showing an empty box.
  final bool wasEmpty;
}

class ScreenshotFailed extends ScreenshotState {
  const ScreenshotFailed(this.failure);

  final AppFailure failure;
}

/// Picks a screenshot, reads it on the device, and deletes the copy.
class ScreenshotController extends StateNotifier<ScreenshotState> {
  ScreenshotController(this._ref) : super(const ScreenshotIdle());

  final Ref _ref;

  Future<void> pickAndRead() async {
    final picker = _ref.read(screenshotPickerServiceProvider);

    String? path;
    try {
      path = await picker.pickScreenshot();
    } on Exception {
      state = const ScreenshotFailed(PermissionFailure(permission: 'photos'));
      return;
    }
    // Cancelling is not a failure; the screen simply stays as it was.
    if (path == null) {
      if (state is ScreenshotReading) state = const ScreenshotIdle();
      return;
    }

    state = const ScreenshotReading();
    final recogniser = _ref.read(textRecogniserProvider);
    try {
      final text = await recogniser.recognise(path);
      state = ScreenshotRecognised(text: text, wasEmpty: text.isEmpty);
    } on AppFailure catch (failure) {
      state = ScreenshotFailed(failure);
    } on Exception {
      state = const ScreenshotFailed(AnalysisFailure());
    } finally {
      // The image copy goes as soon as the text is out of it, whether or not
      // recognition succeeded.
      await picker.deleteCopy(path);
    }
  }

  /// Keeps the user's corrections without re-running OCR.
  void updateText(String text) {
    final current = state;
    if (current is! ScreenshotRecognised) return;
    state = ScreenshotRecognised(text: text, wasEmpty: current.wasEmpty);
  }

  void reset() => state = const ScreenshotIdle();
}

final screenshotControllerProvider =
    StateNotifierProvider<ScreenshotController, ScreenshotState>(
      ScreenshotController.new,
    );
