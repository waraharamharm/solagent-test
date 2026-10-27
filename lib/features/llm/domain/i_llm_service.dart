import 'chat_message.dart';

/// Vendor-agnostic chat model. Implementations throw only [LlmFailure].
abstract interface class ILLMService {
  Future<LlmResponse> complete(
    List<ChatMessage> messages, {
    double temperature = 0.2,
  });

  /// Yields content deltas as they arrive. The stream ends when the model
  /// finishes; errors are emitted as [LlmFailure].
  Stream<String> stream(List<ChatMessage> messages, {double temperature = 0.2});
}
