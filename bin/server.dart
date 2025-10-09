import 'dart:io';

import 'package:blockfrost_api/blockfrost_api.dart';
import 'package:blockfrost_secure_webhooks/webhook_handler.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

// You will find your webhook secret auth token in your webhook settings in the Blockfrost Dashboard
// Pass it as environment variable when starting the server:
// BLOCKFROST_TOKEN='WEBHOOK-AUTH-TOKEN' dart run bin/server.dart
const String secretAuthEnvToken = 'BLOCKFROST_TOKEN';
const int port = 8080;

// Main Method
void main() async {
  final secretToken = Platform.environment[secretAuthEnvToken];
  if (secretToken == null || secretToken.isEmpty) {
    print('FATAL: Missing environment variable $secretAuthEnvToken');
    exit(1); // Exit if secret is not set
  }

  // path mapping with router configuration
  final router = Router()
    ..post(
        '/webhook',
        (Request request) => handleWebhook(
            request: request,
            secretToken: secretToken,
            validator:
                BlockfrostSignatureValidator())) // Map POST requests to /webhook
    ..get('/status', (_) => Response.ok('ok')); // Simple test route

  // Configure middleware (optional, but good practice for logging)
  final handler =
      Pipeline().addMiddleware(logRequests()).addHandler(router.call);

  // Start the server
  try {
    final server = await io.serve(handler, InternetAddress.anyIPv4, port);
    print('Server running on http://${server.address.host}:${server.port}');
    print('Ready to receive webhooks at: http://localhost:$port/webhook');
  } catch (e) {
    print('Failed to start server: $e');
  }
}
