import 'package:flutter/services.dart';

import '../sharing/shared_text_service.dart';

/// One contact the user chose from the system picker.
class PickedContact {
  const PickedContact({required this.name, required this.rawNumber});

  final String name;
  final String rawNumber;
}

/// Lets the user pick a single contact without granting a contacts permission.
///
/// The system picker owns the address book; Salone Shield only receives the
/// one person the user tapped. Adding a contact must always remain possible by
/// typing, so every failure here degrades to null rather than to an error the
/// user has to understand.
class ContactPickerService {
  const ContactPickerService({this.channel = SharedTextService.defaultChannel});

  /// Shares the single native channel; overridden in tests.
  final MethodChannel channel;

  static const String methodPickContact = 'pickContact';

  /// Returns the chosen contact, or null when the user cancelled or the
  /// device has no picker.
  Future<PickedContact?> pick() async {
    try {
      final result = await channel.invokeMapMethod<String, dynamic>(
        methodPickContact,
      );
      if (result == null) return null;

      final number = result['number'];
      if (number is! String || number.trim().isEmpty) return null;
      final name = result['name'];

      return PickedContact(
        name: name is String ? name.trim() : '',
        rawNumber: number.trim(),
      );
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
