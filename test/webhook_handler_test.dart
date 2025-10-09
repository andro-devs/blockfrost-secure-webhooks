import 'dart:io';

import 'package:blockfrost_api/blockfrost_api.dart';
import 'package:blockfrost_secure_webhooks/webhook_handler.dart';
import 'package:mocktail/mocktail.dart'; // Used only for Request mocking
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

// --- Helper Mock for the Request Object (from previous answer) ---
class MockRequest extends Mock implements Request {}

Request createMockRequest({
  Map<String, String> headers = const {},
  String body = '{}',
}) {
  final mockRequest = MockRequest();
  when(() => mockRequest.headers).thenReturn(headers);
  when(() => mockRequest.readAsString()).thenAnswer((_) => Future.value(body));
  when(() => mockRequest.method).thenReturn('POST');
  return mockRequest;
}

// Mock class for the validator function (allows us to verify if it was called)
class MockWebhookValidator extends Mock implements SignatureValidator {}

final mockValidator = MockWebhookValidator();
// -----------------------------------------------------------------

void main() {
  const testSecret = 'TEST_SECRET';
  const validSignatureHeader = 't=foo,v1=bar';

  /// Reads a fixture file synchronously and returns its content as a String.
  ///
  /// [name] is the path relative to the project root (e.g., 'test/fixtures/webhook_type_tx.json')
  String fixture(String name) => File(name).readAsStringSync();

  final testBodyTx = fixture("test/fixtures/webhook_type_tx.json");
  final testBodyBlock = fixture("test/fixtures/webhook_type_block.json");

  // Define the common stubbing logic
  void stubValidatorToReturn(bool value) {
    when(() => mockValidator.validate(
          signatureHeader: any(named: 'signatureHeader'),
          requestPayload: any(named: 'requestPayload'),
          secretAuthToken: testSecret,
        )).thenReturn(value);
  }

  group('handleWebhook Isolation Tests', () {
    // 1. Setup: Runs before *every* test in this group
    setUp(() {
      // Reset the mocks call history and behavior for a clean slate
      reset(mockValidator);
      // Set the default behavior to TRUE (Success), as this is the most common path tested.
      // Tests that need failure will override this behavior.
      stubValidatorToReturn(true);
    });

    // --- Test Case 1: Missing Signature Header ---
    test('Should return 400 if Blockfrost-Signature header is missing',
        () async {
      final request = createMockRequest(body: testBodyBlock, headers: {});
      final response = await handleWebhook(
          request: request, secretToken: testSecret, validator: mockValidator);
      expect(response.statusCode, 400);
      expect(await response.readAsString(), 'Missing signature header.');

      // Verify that the validator was never reached
      verifyZeroInteractions(mockValidator);
    });

    // --- Test Case 2: Validation Failure ---
    test('Should return 400 when validation fails (Rejection scenario)',
        () async {
      // Override the default TRUE stub with a FALSE stub just for this test
      stubValidatorToReturn(false);

      final request = createMockRequest(
        body: testBodyBlock,
        headers: {'blockfrost-signature': validSignatureHeader},
      );

      // STUB: Inject a validator that ALWAYS returns FALSE (simulates invalid signature)
      final response = await handleWebhook(
          request: request, secretToken: testSecret, validator: mockValidator);
      expect(response.statusCode, 400);
      expect(await response.readAsString(), 'Signature validation failed!');

      // Verify the mock was called to ensure we tested the correct path
      verify(() => mockValidator.validate(
            signatureHeader: validSignatureHeader,
            requestPayload: testBodyBlock,
            secretAuthToken: testSecret,
          )).called(1);
    });

    // --- Test Case 3: Successful Reception of an transaction webhook ---
    test('Should return 200 when validation succeeds and type is transaction',
        () async {
      stubValidatorToReturn(
          true); // or skip stubbing due to default return in setup set to "true"
      final request = createMockRequest(
        body: testBodyTx,
        headers: {'blockfrost-signature': validSignatureHeader},
      );

      // STUB: Inject a validator that ALWAYS returns TRUE (simulates valid signature)
      final response = await handleWebhook(
          request: request, secretToken: testSecret, validator: mockValidator);
      expect(response.statusCode, 200);
      expect(await response.readAsString(),
          contains('Webhook received successfully'));
    });

    // --- Test Case 4: Successful Reception of an transaction webhook ---
    test('Should return 200 when validation succeeds and type is transaction',
        () async {
      stubValidatorToReturn(
          true); // or skip stubbing due to default return in setup set to "true"
      final request = createMockRequest(
        body: testBodyBlock,
        headers: {'blockfrost-signature': validSignatureHeader},
      );

      // STUB: Inject a validator that ALWAYS returns TRUE (simulates valid signature)
      final response = await handleWebhook(
          request: request, secretToken: testSecret, validator: mockValidator);
      expect(response.statusCode, 200);
      expect(await response.readAsString(),
          contains('Webhook received successfully'));
    });

    // --- Test Case 5: Invalid JSON After Validation ---
    test('Should return 500 if the validated payload is not valid JSON',
        () async {
      final request = createMockRequest(
        // Invalid JSON body structure
        body: 'This is not JSON!',
        headers: {'blockfrost-signature': validSignatureHeader},
      );

      // STUB: Validation still passes (we assume the signature *was* calculated on this junk data)
      final response = await handleWebhook(
          request: request, secretToken: testSecret, validator: mockValidator);
      // This tests the `try-catch` block responsible for `jsonDecode`
      expect(response.statusCode, 500);
      expect(
          await response.readAsString(), contains('Failed to process JSON.'));
    });
  });
}
