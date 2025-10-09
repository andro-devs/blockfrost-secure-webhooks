import 'dart:async';
import 'dart:convert';

import 'package:blockfrost_api/blockfrost_api.dart';
import 'package:shelf/shelf.dart';

/// Request handler which handles the incoming webhook
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

  // Parsing requestPayload JSON
  try {
    Map<String, dynamic> data =
        jsonDecode(requestPayload) as Map<String, dynamic>;
    final String? type = data['type'] as String?;
    final dynamic payload = data['payload'];

    if (type == null || payload == null) {
      throw Exception("Error: Payload or type is missing.");
    }

    // Process the incoming event
    switch (type) {
      case "transaction":
        final List<dynamic> transactions = payload as List<dynamic>;
        print("Received ${transactions.length} transactions");
        for (final transaction in transactions) {
          final Map<String, dynamic> txData =
              transaction as Map<String, dynamic>;
          final String? txHash =
              (txData['tx'] as Map<String, dynamic>?)?['hash'] as String?;
          print("Transaction $txHash");
        }
        break;
      case "block":
        final Map<String, dynamic> blockData = payload as Map<String, dynamic>;
        final String? blockHash = blockData['hash'] as String?;
        print("Received block hash $blockHash");
        break;
      // ...other types (delegation, epoch)
      default:
        throw Exception("Unexpected type $type");
    }
    // Signature is valid
    return Response.ok(
      jsonEncode({'status': 'Webhook received successfully ✅'}),
      headers: {'content-type': 'application/json'},
    );
  } catch (e) {
    return Response.internalServerError(body: 'Failed to process JSON.');
  }
}
