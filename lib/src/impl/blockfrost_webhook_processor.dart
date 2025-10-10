import 'dart:convert';

import 'package:blockfrost_secure_webhooks/src/webhook_processor.dart';

class BlockfrostWebhookProcessor implements WebhookProcessor {
  @override
  void process(String requestPayload) {
    try {
      final Map<String, dynamic> data =
          jsonDecode(requestPayload) as Map<String, dynamic>;
      final String? type = data['type'] as String?;
      final dynamic payload = data['payload'];

      if (type == null || payload == null) {
        throw Exception("Error: Payload or type is missing.");
      }

      // Process the incoming type
      switch (type) {
        case "transaction":
          _processTransactions(payload);
          break;
        case "block":
          _processBlock(payload);
          break;
        // ...other types
        default:
          throw Exception("Unexpected type $type");
      }
    } catch (e) {
      throw Exception("Failed to process JSON.");
    }
  }

  void _processTransactions(List<dynamic> transactions) {
    print("Received ${transactions.length} transactions");
    for (final transaction in transactions) {
      final Map<String, dynamic> txData = transaction as Map<String, dynamic>;
      final String? txHash =
          (txData['tx'] as Map<String, dynamic>?)?['hash'] as String?;
      print("Transaction $txHash");
    }
  }

  void _processBlock(Map<String, dynamic> blockData) {
    final String? blockHash = blockData['hash'] as String?;
    print("Received block hash $blockHash");
  }
}
