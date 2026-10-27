import 'package:local_auth/local_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'biometric_gate.g.dart';

enum GateResult {
  granted,

  /// The user cancelled or failed the check.
  denied,

  /// No lock screen / biometrics enrolled, or the platform call failed.
  /// Treated as closed: the protected screen stays locked.
  unavailable,
}

abstract interface class IBiometricGate {
  Future<GateResult> authenticate(String reason);
}

/// Fingerprint / face, with the device PIN as fallback so a phone without
/// enrolled biometrics is not locked out. A phone with no lock screen at all
/// gets [GateResult.unavailable]: we do not open server access without any
/// local protection.
class LocalAuthGate implements IBiometricGate {
  LocalAuthGate([LocalAuthentication? auth])
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<GateResult> authenticate(String reason) async {
    try {
      if (!await _auth.isDeviceSupported()) return GateResult.unavailable;
      final ok = await _auth.authenticate(localizedReason: reason);
      return ok ? GateResult.granted : GateResult.denied;
    } on LocalAuthException catch (e) {
      return switch (e.code) {
        LocalAuthExceptionCode.userCanceled ||
        LocalAuthExceptionCode.systemCanceled ||
        LocalAuthExceptionCode.timeout => GateResult.denied,
        _ => GateResult.unavailable,
      };
    } catch (_) {
      return GateResult.unavailable;
    }
  }
}

@Riverpod(keepAlive: true)
IBiometricGate biometricGate(Ref ref) => LocalAuthGate();
