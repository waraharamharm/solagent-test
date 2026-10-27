import 'package:flutter/foundation.dart';

/// Records a failure the app deliberately carries on after. Debug builds
/// only, and only the kind of error: its text may contain server details.
void debugLogError(String where, Object error) {
  if (kDebugMode) debugPrint('[$where] ${error.runtimeType}');
}
