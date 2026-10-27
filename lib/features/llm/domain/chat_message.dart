enum ChatRole { system, user, assistant }

class ChatMessage {
  const ChatMessage(this.role, this.content);

  const ChatMessage.system(this.content) : role = ChatRole.system;
  const ChatMessage.user(this.content) : role = ChatRole.user;
  const ChatMessage.assistant(this.content) : role = ChatRole.assistant;

  final ChatRole role;
  final String content;

  @override
  bool operator ==(Object other) =>
      other is ChatMessage && other.role == role && other.content == content;

  @override
  int get hashCode => Object.hash(role, content);
}

class LlmUsage {
  const LlmUsage({required this.promptTokens, required this.completionTokens});

  final int promptTokens;
  final int completionTokens;
}

class LlmResponse {
  const LlmResponse({required this.content, this.usage});

  final String content;
  final LlmUsage? usage;
}
