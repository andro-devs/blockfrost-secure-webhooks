import 'dart:convert';

import 'package:crypto/crypto.dart';

void main() {
  // NOTE: Must match the value you provide as BLOCKFROST_TOKEN env variable during server start up
  const testSecret = 'WEBHOOK-AUTH-TOKEN';
  // current timestamp
  final testTs = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  // The exact JSON payload string you will use in your curl command
  const String testPayloadString = '{"type": "block", "payload": {"hash": "0a26dd2b2c2cd32e66029215d22cd9f1572e41bd6549c75cf2479fb9b771487a"}}';

  // 1. Prepare the signature_payload (timestamp.payload)
  final signaturePayload = '$testTs.$testPayloadString';

  // 2. Compute the expected signature (HMAC-SHA256)
  final key = utf8.encode(testSecret);
  final messageBytes = utf8.encode(signaturePayload);

  final hmac = Hmac(sha256, key);
  final digest = hmac.convert(messageBytes);

  final expectedSignature = digest.toString();

  print('\n--- Blockfrost Signature Generator outputs ---');
  print('String to Sign: $signaturePayload');
  print('Expected Signature (v1=): $expectedSignature');
  print('Header Value: t=$testTs,v1=$expectedSignature');
  print('--------------------------------\n');
}
