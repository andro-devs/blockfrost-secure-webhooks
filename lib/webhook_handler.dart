import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:blockfrost_api/blockfrost_api.dart';
import 'package:shelf/shelf.dart';

/// Request handler that handles the webhook logic
Future<Response> handleWebhook(
    {required Request request,
    required String secretToken,
    required SignatureValidator validator}) async {
  final userAgent = request.headers['user-agent'] ?? 'N/A';
  final clientIp = request.headers['x-forwarded-for'] ?? 'N/A';

  print('--- Incoming Webhook ---');
  print('User-Agent: $userAgent');
  print('Client IP (Approx): $clientIp');
  print('--------------------------');
  // -----------------------------

  final String requestPayload = await request.readAsString();
  final signatureHeader = request.headers['blockfrost-signature'];

  // Verify request data is available
  if (signatureHeader == null || signatureHeader.isEmpty) {
    return Response(400, body: 'Missing signature header.');
  }
  if (requestPayload.isEmpty) {
    return Response(400, body: 'Empty requestPayload.');
  }

  // Validate using the SignatureValidator
  if (!validator.validate(
    signatureHeader: signatureHeader,
    requestPayload: requestPayload,
    secretAuthToken: secretToken,
  )) {
    return Response(400, body: 'Signature validation failed!');
  }

  // Payload parsing JSON
  try {
    Map<String, dynamic> data =
        jsonDecode(requestPayload) as Map<String, dynamic>;
    developer.log('Payload keys received: ${data.keys}');
    return Response.ok(
      jsonEncode({'status': 'Webhook received successfully ✅'}),
      headers: {'content-type': 'application/json'},
    );
  } catch (e) {
    developer.log('Internal Server Error: Could not decode validated JSON.');
    return Response.internalServerError(body: 'Failed to process JSON.');
  }
}
