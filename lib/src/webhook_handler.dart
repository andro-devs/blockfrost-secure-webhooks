import 'package:blockfrost_api/blockfrost_api.dart';
import 'package:blockfrost_secure_webhooks/src/webhook_processor.dart';
import 'package:shelf/shelf.dart';

abstract class WebhookHandler {
  Future<Response> handleWebhook(
      {required Request request,
      required String secretToken,
      required SignatureValidator validator,
      required WebhookProcessor processor});
}
