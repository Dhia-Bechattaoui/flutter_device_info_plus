import 'package:flutter/foundation.dart';

import 'battery_info.dart';
import 'display_info.dart';
import 'memory_info.dart';
import 'network_info.dart';
import 'processor_info.dart';
import 'security_info.dart';
import 'sensor_info.dart';

/// Comprehensive device information containing all available device details.
///
/// This class aggregates information from various device subsystems including
/// hardware specifications, system details, battery status, sensors, and more.
@immutable
class DeviceInformation {
  /// Creates a new [DeviceInformation] instance.
  const DeviceInformation({
    required this.deviceName,
    required this.manufacturer,
    required this.model,
    required this.brand,
    required this.operatingSystem,
    required this.systemVersion,
    required this.buildNumber,
    required this.kernelVersion,
    required this.processorInfo,
    required this.memoryInfo,
    required this.displayInfo,
    required this.sensorInfo,
    required this.networkInfo,
    required this.securityInfo,
    this.batteryInfo,
  });

  /// The human-readable name of the device.
  final String deviceName;

  /// The manufacturer of the device (e.g., 'Samsung', 'Apple', 'Google').
  final String manufacturer;

  /// The model name of the device (e.g., 'iPhone 15 Pro', 'Galaxy S23').
  final String model;

  /// The brand name of the device.
  final String brand;

  /// The operating system name (e.g., 'Android', 'iOS', 'Windows').
  final String operatingSystem;

  /// The version of the operating system.
  final String systemVersion;

  /// The build number or identifier of the operating system.
  final String buildNumber;

  /// The kernel version information.
  final String kernelVersion;

  /// Detailed processor and CPU information.
  final ProcessorInfo processorInfo;

  /// Memory and storage information.
  final MemoryInfo memoryInfo;

  /// Display and screen information.
  final DisplayInfo displayInfo;

  /// Battery information (null if not available).
  final BatteryInfo? batteryInfo;

  /// Information about available sensors.
  final SensorInfo sensorInfo;

  /// Network connection information.
  final NetworkInfo networkInfo;

  /// Device security and privacy information.
  final SecurityInfo securityInfo;

  /// Creates a copy of this [DeviceInformation] with the given fields replaced.
  DeviceInformation copyWith({
    final String? deviceName,
    final String? manufacturer,
    final String? model,
    final String? brand,
    final String? operatingSystem,
    final String? systemVersion,
    final String? buildNumber,
    final String? kernelVersion,
    final ProcessorInfo? processorInfo,
    final MemoryInfo? memoryInfo,
    final DisplayInfo? displayInfo,
    final BatteryInfo? batteryInfo,
    final SensorInfo? sensorInfo,
    final NetworkInfo? networkInfo,
    final SecurityInfo? securityInfo,
  }) => DeviceInformation(
    deviceName: deviceName ?? this.deviceName,
    manufacturer: manufacturer ?? this.manufacturer,
    model: model ?? this.model,
    brand: brand ?? this.brand,
    operatingSystem: operatingSystem ?? this.operatingSystem,
    systemVersion: systemVersion ?? this.systemVersion,
    buildNumber: buildNumber ?? this.buildNumber,
    kernelVersion: kernelVersion ?? this.kernelVersion,
    processorInfo: processorInfo ?? this.processorInfo,
    memoryInfo: memoryInfo ?? this.memoryInfo,
    displayInfo: displayInfo ?? this.displayInfo,
    batteryInfo: batteryInfo ?? this.batteryInfo,
    sensorInfo: sensorInfo ?? this.sensorInfo,
    networkInfo: networkInfo ?? this.networkInfo,
    securityInfo: securityInfo ?? this.securityInfo,
  );

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is DeviceInformation &&
        other.deviceName == deviceName &&
        other.manufacturer == manufacturer &&
        other.model == model &&
        other.brand == brand &&
        other.operatingSystem == operatingSystem &&
        other.systemVersion == systemVersion &&
        other.buildNumber == buildNumber &&
        other.kernelVersion == kernelVersion &&
        other.processorInfo == processorInfo &&
        other.memoryInfo == memoryInfo &&
        other.displayInfo == displayInfo &&
        other.batteryInfo == batteryInfo &&
        other.sensorInfo == sensorInfo &&
        other.networkInfo == networkInfo &&
        other.securityInfo == securityInfo;
  }

  @override
  int get hashCode => Object.hash(
    deviceName,
    manufacturer,
    model,
    brand,
    operatingSystem,
    systemVersion,
    buildNumber,
    kernelVersion,
    processorInfo,
    memoryInfo,
    displayInfo,
    batteryInfo,
    sensorInfo,
    networkInfo,
    securityInfo,
  );

  @override
  String toString() =>
      'DeviceInformation('
      'deviceName: $deviceName, '
      'manufacturer: $manufacturer, '
      'model: $model, '
      'brand: $brand, '
      'operatingSystem: $operatingSystem, '
      'systemVersion: $systemVersion, '
      'buildNumber: $buildNumber, '
      'kernelVersion: $kernelVersion, '
      'processorInfo: $processorInfo, '
      'memoryInfo: $memoryInfo, '
      'displayInfo: $displayInfo, '
      'batteryInfo: $batteryInfo, '
      'sensorInfo: $sensorInfo, '
      'networkInfo: $networkInfo, '
      'securityInfo: $securityInfo'
      ')';
}
