import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';
import '../ui/cookie_shape.dart';
import 'biometric_gate.dart';

/// Shows [child] only after a successful local authentication, and locks
/// again when the app goes to the background.
class BiometricGuard extends ConsumerStatefulWidget {
  const BiometricGuard({
    super.key,
    required this.child,
    this.reason,
    this.relockAfter = const Duration(seconds: 3),
  });

  /// How long the app may be away before the lock comes back. The system
  /// prompt pauses and resumes the app around itself; a pause that short must
  /// not ask again.
  final Duration relockAfter;

  final Widget child;

  /// Text of the system prompt; the localized default is used when null.
  final String? reason;

  @override
  ConsumerState<BiometricGuard> createState() => _BiometricGuardState();
}

class _BiometricGuardState extends ConsumerState<BiometricGuard>
    with WidgetsBindingObserver {
  GateResult? _result;
  bool _busy = false;
  bool _covered = false;
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_busy) return;
    if (state == AppLifecycleState.paused) {
      // Hide the content right away (the recent-apps preview), decide later.
      _pausedAt ??= DateTime.now();
      if (_result == GateResult.granted) setState(() => _covered = true);
    } else if (state == AppLifecycleState.resumed) {
      final away = _pausedAt == null
          ? Duration.zero
          : DateTime.now().difference(_pausedAt!);
      _pausedAt = null;
      if (_result == GateResult.granted) {
        if (away < widget.relockAfter) {
          if (_covered) setState(() => _covered = false);
        } else {
          setState(() {
            _covered = false;
            _result = null;
          });
          _authenticate();
        }
      } else if (_result == null) {
        _authenticate();
      }
    }
  }

  Future<void> _authenticate() async {
    if (_busy) return;
    setState(() => _busy = true);
    final result = await ref
        .read(biometricGateProvider)
        .authenticate(widget.reason ?? context.l10n.guardReason);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _covered = false;
      _pausedAt = null;
      _result = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_result == GateResult.granted && !_covered) return widget.child;
    final l10n = context.l10n;
    final text = switch (_result) {
      GateResult.unavailable => l10n.guardUnavailable,
      GateResult.denied => l10n.guardDenied,
      _ => l10n.guardChecking,
    };
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CookieShape(
                size: 96,
                color: scheme.primaryContainer,
                child: Icon(
                  Icons.lock_rounded,
                  size: 40,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                text,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _busy ? null : _authenticate,
                child: Text(l10n.guardUnlock),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
