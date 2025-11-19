import 'package:flutter/foundation.dart';

/// Information about the device's battery status and health.
///
/// Contains details about battery level, charging status, health,
/// and other battery-related metrics.
@immutable
class BatteryInfo {
  /// Creates a new [BatteryInfo] instance.
  const BatteryInfo({
    required this.batteryLevel,
    required this.chargingStatus,
    required this.batteryHealth,
    required this.batteryCapacity,
    required this.batteryVoltage,
    required this.batteryTemperature,
  });

  /// Current battery level as a percentage (0-100).
  final int batteryLevel;

  /// Current charging status ('charging', 'discharging', 'full', 'unknown').
  final String chargingStatus;

  /// Battery health status ('good', 'poor', 'dead', 'unknown').
  final String batteryHealth;

  /// Battery capacity in mAh (milliampere-hours).
  final int batteryCapacity;

  /// Current battery voltage in volts.
  final double batteryVoltage;

  /// Current battery temperature in Celsius.
  final double batteryTemperature;

  /// Whether the battery is currently charging.
  bool get isCharging => chargingStatus == 'charging';

  /// Whether the battery is fully charged.
  bool get isFullyCharged => chargingStatus == 'full';

  /// Whether the battery is in good health.
  bool get isHealthy => batteryHealth == 'good';

  /// Whether the battery level is low (below 20%).
  bool get isLowBattery => batteryLevel < 20;

  /// Whether the battery level is critical (below 10%).
  bool get isCriticalBattery => batteryLevel < 10;

  /// Gets battery temperature in Fahrenheit.
  double get batteryTemperatureFahrenheit => (batteryTemperature * 9 / 5) + 32;

  /// Creates a copy of this [BatteryInfo] with the given fields replaced.
  BatteryInfo copyWith({
    int? batteryLevel,
    String? chargingStatus,
    String? batteryHealth,
    int? batteryCapacity,
    double? batteryVoltage,
    double? batteryTemperature,
  }) => BatteryInfo(
    batteryLevel: batteryLevel ?? this.batteryLevel,
    chargingStatus: chargingStatus ?? this.chargingStatus,
    batteryHealth: batteryHealth ?? this.batteryHealth,
    batteryCapacity: batteryCapacity ?? this.batteryCapacity,
    batteryVoltage: batteryVoltage ?? this.batteryVoltage,
    batteryTemperature: batteryTemperature ?? this.batteryTemperature,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is BatteryInfo &&
        other.batteryLevel == batteryLevel &&
        other.chargingStatus == chargingStatus &&
        other.batteryHealth == batteryHealth &&
        other.batteryCapacity == batteryCapacity &&
        other.batteryVoltage == batteryVoltage &&
        other.batteryTemperature == batteryTemperature;
  }

  @override
  int get hashCode => Object.hash(
    batteryLevel,
    chargingStatus,
    batteryHealth,
    batteryCapacity,
    batteryVoltage,
    batteryTemperature,
  );

  @override
  String toString() =>
      'BatteryInfo('
      'batteryLevel: $batteryLevel, '
      'chargingStatus: $chargingStatus, '
      'batteryHealth: $batteryHealth, '
      'batteryCapacity: $batteryCapacity, '
      'batteryVoltage: $batteryVoltage, '
      'batteryTemperature: $batteryTemperature'
      ')';
}
