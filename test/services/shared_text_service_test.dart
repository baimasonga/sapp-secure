import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salone_shield/services/sharing/shared_text_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.gsit.saloneshield/shared_text');
  const service = SharedTextService(channel: channel);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  void mockNativeReply(Object? reply) {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, SharedTextService.methodGetSharedText);
      return reply;
    });
  }

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  group('text shared when the app launches', () {
    test('is returned, trimmed', () async {
      mockNativeReply('  send me the code  ');
      expect(await service.initialSharedText(), 'send me the code');
    });

    test('is null when nothing was shared', () async {
      mockNativeReply(null);
      expect(await service.initialSharedText(), isNull);
    });

    test('blank text is treated as nothing shared', () async {
      mockNativeReply('   \n  ');
      expect(await service.initialSharedText(), isNull);
    });

    test('a platform failure degrades to null rather than crashing', () async {
      messenger.setMockMethodCallHandler(
        channel,
        (call) async => throw PlatformException(code: 'boom'),
      );
      expect(await service.initialSharedText(), isNull);
    });

    test('a missing native side degrades to null', () async {
      // No handler registered at all, which is what happens on a platform
      // where the channel does not exist.
      messenger.setMockMethodCallHandler(channel, null);
      expect(await service.initialSharedText(), isNull);
    });
  });

  group('text shared while the app is open', () {
    Future<void> sendFromNative(String method, Object? arguments) async {
      await messenger.handlePlatformMessage(
        channel.name,
        channel.codec.encodeMethodCall(MethodCall(method, arguments)),
        (_) {},
      );
    }

    test('reaches the listener', () async {
      final received = <String>[];
      service.listen(received.add);
      addTearDown(service.dispose);

      await sendFromNative(
        SharedTextService.methodOnSharedText,
        ' pay 076123456 ',
      );

      expect(received, ['pay 076123456']);
    });

    test('blank or non-string payloads are ignored', () async {
      final received = <String>[];
      service.listen(received.add);
      addTearDown(service.dispose);

      await sendFromNative(SharedTextService.methodOnSharedText, '  ');
      await sendFromNative(SharedTextService.methodOnSharedText, 42);
      await sendFromNative(SharedTextService.methodOnSharedText, null);

      expect(received, isEmpty);
    });

    test('an unknown method is ignored', () async {
      final received = <String>[];
      service.listen(received.add);
      addTearDown(service.dispose);

      await sendFromNative('somethingElse', 'send money');

      expect(received, isEmpty);
    });
  });
}
