import 'dart:async';
import 'dart:convert';

import 'package:blockfrost_api/blockfrost_api.dart';
import 'package:blockfrost_secure_webhooks/src/webhook_handler.dart';
import 'package:blockfrost_secure_webhooks/src/webhook_processor.dart';
import 'package:shelf/shelf.dart';

class BlockfrostWebhookHandler implements WebhookHandler {
  /// Request handler which handles the incoming webhook
  @override
  Future<Response> handleWebhook(
      {required Request request,
      required String secretToken,
      required SignatureValidator validator,
      required WebhookProcessor processor}) async {
    logUserAgent(request);

    final String requestPayload = await request.readAsString();
    final signatureHeader = request.headers['blockfrost-signature'];

    // Verify request data
    if (signatureHeader == null || signatureHeader.isEmpty) {
      return Response(400, body: 'Missing signature header.');
    }
    if (requestPayload.isEmpty) {
      return Response(400, body: 'Empty requestPayload.');
    }

    // Validate signature
    try {
      validator.validate(
          requestPayload: requestPayload,
          signatureHeader: signatureHeader,
          secretAuthToken: secretToken);
    } on SignatureValidationException catch (e) {
      return Response(
        400,
        // Or whatever single status code you prefer for all validation failures
        body: 'Signature validation failed! ${e.toString()}',
      );
    } catch (e) {
      return Response.internalServerError(body: 'Signature validation failed!');
    }

    // Process payload
    try {
      processor.process(requestPayload);
    } catch (e) {
      return Response.internalServerError(body: 'Failed to process JSON.');
    }

    // Signature is valid
    return Response.ok(
      jsonEncode({'status': 'Webhook received successfully ✅'}),
      headers: {'content-type': 'application/json'},
    );
  }
}

void logUserAgent(Request request) {
  final userAgent = request.headers['user-agent'] ?? 'N/A';
  final clientIp = request.headers['x-forwarded-for'] ?? 'N/A';

  print('--- Incoming Webhook ---');
  print('User-Agent: $userAgent');
  print('Client IP (Approx): $clientIp');
  print('--------------------------');
}
