import 'dart:async';

import 'models/models.dart';

/// The interface that implementations of flutter_device_info_plus must implement.
///
/// Platform implementations should extend this class rather than implementing it
/// directly to ensure that new methods are handled correctly.
abstract class FlutterDeviceInfoPlusPlatform {
  /// Creates a new platform interface.
  const FlutterDeviceInfoPlusPlatform();

  /// The current platform implementation.
  static FlutterDeviceInfoPlusPlatform? _instance;

  /// Gets the current platform implementation.
  static FlutterDeviceInfoPlusPlatform get instance =>
      _instance ?? _throwNoPlatformImplementation();

  /// Sets the current platform implementation.
  static set instance(FlutterDeviceInfoPlusPlatform instance) {
    _instance = instance;
  }

  /// Gets comprehensive device information.
  ///
  /// Returns a [DeviceInformation] object containing all available
  /// device information for the current platform.
  Future<DeviceInformation> getDeviceInfo();

  /// Gets current battery information.
  ///
  /// Returns [BatteryInfo] with current battery status, level, health,
  /// and charging information. Returns null if battery information
  /// is not available on the current platform.
  Future<BatteryInfo?> getBatteryInfo();

  /// Gets information about available sensors on the device.
  ///
  /// Returns [SensorInfo] containing a list of all available sensors
  /// and their capabilities.
  Future<SensorInfo> getSensorInfo();

  /// Gets current network information.
  ///
  /// Returns [NetworkInfo] with details about the current network
  /// connection including type, speed, and interface information.
  Future<NetworkInfo> getNetworkInfo();

  static Never _throwNoPlatformImplementation() {
    throw UnimplementedError(
      'No platform implementation found. '
      'Make sure to register a platform implementation before using the plugin.',
    );
  }
}
