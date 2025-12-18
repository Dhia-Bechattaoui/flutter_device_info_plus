import 'package:flutter/foundation.dart';

/// Information about the device's security features and status.
///
/// Contains details about device security capabilities, encryption status,
/// and biometric authentication availability.
@immutable
class SecurityInfo {
  /// Creates a new [SecurityInfo] instance.
  const SecurityInfo({
    required this.isDeviceSecure,
    required this.hasFingerprint,
    required this.hasFaceUnlock,
    required this.screenLockEnabled,
    required this.encryptionStatus,
  });

  /// Whether the device has security measures enabled.
  final bool isDeviceSecure;

  /// Whether fingerprint authentication is available.
  final bool hasFingerprint;

  /// Whether face unlock authentication is available.
  final bool hasFaceUnlock;

  /// Whether screen lock (PIN, pattern, password) is enabled.
  final bool screenLockEnabled;

  /// Encryption status of the device ('encrypted', 'unencrypted', 'partial').
  final String encryptionStatus;

  /// Whether the device has any biometric authentication enabled.
  bool get hasBiometricAuth => hasFingerprint || hasFaceUnlock;

  /// Whether the device is fully encrypted.
  bool get isEncrypted => encryptionStatus == 'encrypted';

  /// Whether the device has multiple security layers.
  bool get hasMultiLayerSecurity =>
      screenLockEnabled && hasBiometricAuth && isEncrypted;

  /// Gets a security score from 0 to 100 based on enabled features.
  int get securityScore {
    var score = 0;
    if (isDeviceSecure) {
      score += 20;
    }
    if (screenLockEnabled) {
      score += 25;
    }
    if (hasFingerprint) {
      score += 20;
    }
    if (hasFaceUnlock) {
      score += 15;
    }
    if (isEncrypted) {
      score += 20;
    }
    return score;
  }

  /// Gets a human-readable security level description.
  String get securityLevel {
    final score = securityScore;
    if (score >= 80) {
      return 'High';
    }
    if (score >= 60) {
      return 'Medium';
    }
    if (score >= 40) {
      return 'Low';
    }
    return 'Very Low';
  }

  /// Creates a copy of this [SecurityInfo] with the given fields replaced.
  SecurityInfo copyWith({
    final bool? isDeviceSecure,
    final bool? hasFingerprint,
    final bool? hasFaceUnlock,
    final bool? screenLockEnabled,
    final String? encryptionStatus,
  }) => SecurityInfo(
    isDeviceSecure: isDeviceSecure ?? this.isDeviceSecure,
    hasFingerprint: hasFingerprint ?? this.hasFingerprint,
    hasFaceUnlock: hasFaceUnlock ?? this.hasFaceUnlock,
    screenLockEnabled: screenLockEnabled ?? this.screenLockEnabled,
    encryptionStatus: encryptionStatus ?? this.encryptionStatus,
  );

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is SecurityInfo &&
        other.isDeviceSecure == isDeviceSecure &&
        other.hasFingerprint == hasFingerprint &&
        other.hasFaceUnlock == hasFaceUnlock &&
        other.screenLockEnabled == screenLockEnabled &&
        other.encryptionStatus == encryptionStatus;
  }

  @override
  int get hashCode => Object.hash(
    isDeviceSecure,
    hasFingerprint,
    hasFaceUnlock,
    screenLockEnabled,
    encryptionStatus,
  );

  @override
  String toString() =>
      'SecurityInfo('
      'isDeviceSecure: $isDeviceSecure, '
      'hasFingerprint: $hasFingerprint, '
      'hasFaceUnlock: $hasFaceUnlock, '
      'screenLockEnabled: $screenLockEnabled, '
      'encryptionStatus: $encryptionStatus'
      ')';
}
