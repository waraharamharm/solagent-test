import 'dart:convert';

import 'command_policy.dart';

/// What the AI suggested for one failure, already screened by
/// [CommandPolicy]. Immutable: the command that runs is exactly the one the
/// user approved.
class FixProposal {
  FixProposal({
    required this.diagnosis,
    required this.explanation,
    required this.command,
  }) : verdict = command == null ? null : CommandPolicy.check(command);

  final String diagnosis;
  final String explanation;

  /// Null when the AI says the user has to act themselves.
  final String? command;
  final CommandVerdict? verdict;

  bool get canRun => command != null && verdict?.isBlocked == false;

  static const _maxText = 2000;

  /// Parses the model's JSON reply. Tolerates code fences and prose around
  /// the object. Throws [FormatException] on anything else.
  static FixProposal parse(String reply) {
    final start = reply.indexOf('{');
    final end = reply.lastIndexOf('}');
    if (start < 0 || end <= start) {
      throw const FormatException('No JSON object in reply');
    }
    final Object? json;
    try {
      json = jsonDecode(reply.substring(start, end + 1));
    } on FormatException {
      throw const FormatException('Reply is not valid JSON');
    }
    if (json is! Map) throw const FormatException('Reply is not an object');
    final diagnosis = json['diagnosis'];
    final explanation = json['explanation'] ?? '';
    final command = json['command'];
    if (diagnosis is! String || diagnosis.trim().isEmpty) {
      throw const FormatException('Missing diagnosis');
    }
    if (explanation is! String) {
      throw const FormatException('Bad explanation');
    }
    if (command != null && command is! String) {
      throw const FormatException('Bad command');
    }
    final cmd = (command as String?)?.trim();
    return FixProposal(
      diagnosis: _clip(diagnosis.trim()),
      explanation: _clip(explanation.trim()),
      command: cmd == null || cmd.isEmpty ? null : cmd,
    );
  }

  static String _clip(String s) =>
      s.length > _maxText ? '${s.substring(0, _maxText)}…' : s;
}

/// One earlier round, fed back to the AI so it does not repeat itself.
class FixAttempt {
  const FixAttempt({
    required this.command,
    required this.outcome,
    this.outputTail = const [],
  });

  final String command;

  /// Short English description, e.g. "exit code 1" or "rejected: ...".
  final String outcome;
  final List<String> outputTail;
}
