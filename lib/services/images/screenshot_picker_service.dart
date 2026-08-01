import 'dart:io';

import 'package:image_picker/image_picker.dart';

/// Chooses a screenshot and cleans it up afterwards.
///
/// Uses the platform photo picker, which shows the system's own UI and returns
/// only the image the user selected — so the app needs no photo or storage
/// permission and can never enumerate the gallery.
///
/// The picker copies the chosen image into the app's cache. That copy is the
/// app's responsibility to delete once the text has been read (section 13),
/// which is what [deleteCopy] is for.
class ScreenshotPickerService {
  ScreenshotPickerService({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Formats the specification requires the app to accept.
  static const Set<String> supportedExtensions = {
    '.png',
    '.jpg',
    '.jpeg',
    '.webp',
  };

  /// Returns the path of the chosen image, or null when the user cancelled.
  Future<String?> pickScreenshot() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return null;
    return isSupported(file.path) ? file.path : null;
  }

  static bool isSupported(String path) {
    final lower = path.toLowerCase();
    return supportedExtensions.any(lower.endsWith);
  }

  /// Deletes the app's cached copy of the image.
  ///
  /// The user's own photo is untouched — this only removes the duplicate the
  /// picker made. Failure is ignored: a leftover cache file must not turn into
  /// an error the user has to understand.
  Future<void> deleteCopy(String path) async {
    try {
      final file = File(path);
      if (file.existsSync()) await file.delete();
    } on FileSystemException {
      return;
    }
  }
}
