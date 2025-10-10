import 'dart:convert';
import 'dart:io';

import 'package:blockfrost_secure_webhooks/src/impl/blockfrost_webhook_processor.dart';
import 'package:test/test.dart';

void main() {
  /// Reads a fixture file synchronously and returns its content as a String.
  ///
  /// [name] is the path relative to the project root (e.g., 'test/fixtures/webhook_type_tx.json')
  String fixture(String name) => File(name).readAsStringSync();

  final testBodyTx = fixture("test/fixtures/webhook_type_tx.json");
  final testBodyBlock = fixture("test/fixtures/webhook_type_block.json");

  late BlockfrostWebhookProcessor processor;

  group('processWebhook Isolation Tests', () {
    // 1. Setup: Runs before *every* test in this group
    setUp(() {
      processor = BlockfrostWebhookProcessor();
    });

    // --- Test Case 1: Missing Signature Header ---
    test('Should process a valid tx payload', () async {
      expect(() => processor.process(testBodyTx), returnsNormally);
    });

    // --- Test Case 1: Missing Signature Header ---
    test('Should process a valid block payload', () async {
      expect(() => processor.process(testBodyBlock), returnsNormally);
    });

    // --- Failure Cases (Verifying exceptions) ---
    test('Should throw exception if payload is not valid JSON', () {
      const payload = 'This is not JSON';
      expect(
        () => processor.process(payload),
        throwsA(
          isA<Exception>().having((e) => e.toString(), 'message',
              contains('Failed to process JSON')),
        ),
      );
    });

    // --- Failure Cases (Verifying exceptions) ---

    test('Should throw exception if [type] is invalid', () {
      final payload = jsonEncode({
        "type": "foo",
        "payload": [1, 2, 3]
      });
      expect(
        () => processor.process(payload),
        throwsA(
          isA<Exception>().having((e) => e.toString(), 'message',
              contains('Failed to process JSON')),
        ),
      );
    });

    test('Should throw exception if required field [type] is missing', () {
      final payload = jsonEncode({
        "payload": [1, 2, 3]
      });
      expect(
        () => processor.process(payload),
        throwsA(
          isA<Exception>().having((e) => e.toString(), 'message',
              contains('Failed to process JSON')),
        ),
      );
    });
  });
}
