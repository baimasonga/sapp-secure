import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../core/errors/app_failure.dart';

/// Reads text out of an image.
///
/// An interface so the screenshot feature can be tested without ML Kit, which
/// needs a real device. [MlKitTextRecogniser] is the only implementation that
/// ships.
abstract interface class TextRecogniser {
  /// Returns the text found in the image at [imagePath].
  ///
  /// Throws [AnalysisFailure] when recognition cannot run at all. An image
  /// with no readable text is not a failure — it returns an empty string.
  Future<String> recognise(String imagePath);

  Future<void> dispose();
}

/// On-device OCR through Google ML Kit.
///
/// Runs entirely on the phone: no image and no recognised text is sent
/// anywhere (specification section 13). The recogniser is created lazily and
/// closed as soon as the feature is finished with it, because it holds native
/// resources.
class MlKitTextRecogniser implements TextRecogniser {
  MlKitTextRecogniser();

  TextRecognizer? _recognizer;

  TextRecognizer get _instance =>
      _recognizer ??= TextRecognizer(script: TextRecognitionScript.latin);

  @override
  Future<String> recognise(String imagePath) async {
    try {
      final result = await _instance.processImage(
        InputImage.fromFilePath(imagePath),
      );
      return result.text.trim();
    } on Exception {
      // The path is deliberately left out of the failure: it can name a
      // photo in the user's gallery.
      throw const AnalysisFailure(debugMessage: 'text recognition failed');
    }
  }

  @override
  Future<void> dispose() async {
    await _recognizer?.close();
    _recognizer = null;
  }
}
