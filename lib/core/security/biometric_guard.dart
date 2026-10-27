import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';
import '../ui/cookie_shape.dart';
import 'biometric_gate.dart';

/// Shows [child] only after a successful local authentication, and locks
/// again when the app goes to the background.
class BiometricGuard extends ConsumerStatefulWidget {
  const BiometricGuard({super.key, required this.child, this.reason});

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
    // The system prompt itself pauses the app; do not lock while it is up.
    if (state == AppLifecycleState.paused && !_busy) {
      setState(() => _result = null);
    } else if (state == AppLifecycleState.resumed &&
        _result == null &&
        !_busy) {
      _authenticate();
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
      _result = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_result == GateResult.granted) return widget.child;
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
