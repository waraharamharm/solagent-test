import 'package:solagent/features/llm/domain/chat_message.dart';
import 'package:solagent/features/llm/domain/i_llm_service.dart';

class FakeLlm implements ILLMService {
  FakeLlm(this.replies);

  final List<Object> replies;
  final requests = <List<ChatMessage>>[];

  @override
  Future<LlmResponse> complete(
    List<ChatMessage> messages, {
    double temperature = 0.2,
  }) async {
    requests.add(messages);
    final next = replies.removeAt(0);
    if (next is Exception) throw next;
    return LlmResponse(content: next as String);
  }

  @override
  Stream<String> stream(
    List<ChatMessage> messages, {
    double temperature = 0.2,
  }) => throw UnimplementedError();
}
