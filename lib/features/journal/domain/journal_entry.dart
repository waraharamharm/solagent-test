/// What the app did on the user's server. Written in English: the journal is
/// read back by later sessions (and the AI), possibly in another UI language.
enum JournalKind {
  deployStarted,
  deployFinished,
  diagnosis,
  fixProposed,
  fixDecision,
  fixStarted,
  fixFinished,
  runFinished,

  /// Anything read back that this version does not know.
  note,
}

class JournalEntry {
  JournalEntry({
    required this.time,
    required this.kind,
    required String summary,
    String? detail,
    this.jobId,
  }) : summary = _clean(summary, maxSummary),
       detail = detail == null ? null : _clean(detail, maxDetail);

  static const maxSummary = 300;
  static const maxDetail = 1500;

  final DateTime time;
  final JournalKind kind;
  final String? jobId;
  final String summary;
  final String? detail;

  /// One JSON line, always well under 4 KB.
  Map<String, Object?> toJson() => {
    't': time.toUtc().toIso8601String(),
    'k': kind.name,
    'job': ?jobId,
    's': summary,
    'd': ?detail,
  };

  /// Null for anything that is not a plausible entry. The file lives on the
  /// server and may have been edited, so every field is checked and cut.
  static JournalEntry? tryParse(Object? json) {
    if (json is! Map) return null;
    final t = json['t'];
    final s = json['s'];
    if (t is! String || s is! String) return null;
    final time = DateTime.tryParse(t);
    if (time == null) return null;
    final job = json['job'];
    final detail = json['d'];
    return JournalEntry(
      time: time.toUtc(),
      kind: JournalKind.values.asNameMap()[json['k']] ?? JournalKind.note,
      jobId: job is String && RegExp(r'^[A-Za-z0-9_-]{1,64}$').hasMatch(job)
          ? job
          : null,
      summary: s,
      detail: detail is String ? detail : null,
    );
  }

  /// Control characters out (they could fake lines or terminal escapes), and cut.
  static String _clean(String text, int max) {
    final flat = text.replaceAll(
      RegExp(r'[\u0000-\u0008\u000B-\u001F\u007F]'),
      ' ',
    );
    return flat.length <= max ? flat : '${flat.substring(0, max - 1)}…';
  }
}
