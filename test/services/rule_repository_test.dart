import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salone_shield/core/errors/app_failure.dart';
import 'package:salone_shield/services/risk_engine/rule_repository.dart';

/// Serves a fixed string for the rules asset, so the repository's real code
/// path is exercised without depending on test-framework asset I/O.
class _FakeAssetBundle extends CachingAssetBundle {
  _FakeAssetBundle(this.contents);

  final String? contents;

  @override
  Future<ByteData> load(String key) async {
    if (contents == null || key != RuleRepository.assetPath) {
      throw FlutterError('Asset not found: $key');
    }
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(contents!)));
  }
}

void main() {
  test('loads the rules that are actually shipped in the bundle', () async {
    final shipped = File(RuleRepository.assetPath).readAsStringSync();
    final repository = RuleRepository(bundle: _FakeAssetBundle(shipped));

    final engine = await repository.loadEngine();

    expect(engine.rules, isNotEmpty);
    expect(
      engine.rules.map((rule) => rule.id),
      contains('verification_code_request'),
    );
  });

  test('the shipped asset is declared in pubspec.yaml', () {
    expect(File(RuleRepository.assetPath).existsSync(), isTrue);
    expect(
      File('pubspec.yaml').readAsStringSync(),
      contains('assets/scam_rules/'),
    );
  });

  test('a malformed rule set fails loudly instead of scoring nothing', () {
    final repository = RuleRepository(
      bundle: _FakeAssetBundle('{"rules": [{"id": "broken"}]}'),
    );

    expect(repository.loadEngine(), throwsA(isA<AnalysisFailure>()));
  });

  test('a missing asset surfaces a typed failure', () {
    final repository = RuleRepository(bundle: _FakeAssetBundle(null));

    expect(repository.loadEngine(), throwsA(isA<AnalysisFailure>()));
  });

  test('failures say whether data was saved and whether retry is safe', () {
    const failure = AnalysisFailure();
    expect(failure.dataWasSaved, isFalse);
    expect(failure.retrySafe, isTrue);
  });
}
