import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'exceptions.dart';
import 'models/models.dart';
import 'platform_interface.dart';

/// Enhanced device information with detailed hardware specs and capabilities.
///
/// This class provides a comprehensive API to retrieve device information
/// including hardware specifications, system details, battery status,
/// sensors, and more across all Flutter platforms.
///
/// Example usage:
/// ```dart
/// final deviceInfo = FlutterDeviceInfoPlus();
/// final info = await deviceInfo.getDeviceInfo();
/// print('Device: ${info.deviceName}');
/// print('CPU: ${info.processorInfo.architecture}');
/// print('RAM: ${info.memoryInfo.totalPhysicalMemory} bytes');
/// ```
class FlutterDeviceInfoPlus {
  /// Creates a new instance of [FlutterDeviceInfoPlus].
  const FlutterDeviceInfoPlus();
  static const MethodChannel _channel = MethodChannel(
    'flutter_device_info_plus',
  );

  /// Gets comprehensive device information including hardware specs,
  /// system details, and capabilities.
  ///
  /// Returns a [DeviceInformation] object containing all available
  /// device information for the current platform.
  ///
  /// Throws [DeviceInfoException] if device information cannot be retrieved.
  Future<DeviceInformation> getDeviceInfo() async {
    try {
      if (kIsWeb) {
        return FlutterDeviceInfoPlusPlatform.instance.getDeviceInfo();
      }

      final data =
          await _channel.invokeMethod('getDeviceInfo') as Map<dynamic, dynamic>;

      // Get additional info
      final batteryInfo = await getBatteryInfo();
      final sensorInfo = await getSensorInfo();
      final networkInfo = await getNetworkInfo();

      return DeviceInformation(
        deviceName: data['deviceName'] as String? ?? 'Unknown',
        manufacturer: data['manufacturer'] as String? ?? 'Unknown',
        model: data['model'] as String? ?? 'Unknown',
        brand: data['brand'] as String? ?? 'Unknown',
        operatingSystem: data['operatingSystem'] as String? ?? 'Unknown',
        systemVersion: data['systemVersion'] as String? ?? 'Unknown',
        buildNumber: data['buildNumber'] as String? ?? 'Unknown',
        kernelVersion: data['kernelVersion'] as String? ?? 'Unknown',
        processorInfo: _parseProcessorInfo(
          data['processorInfo'] as Map<dynamic, dynamic>?,
        ),
        memoryInfo: _parseMemoryInfo(
          data['memoryInfo'] as Map<dynamic, dynamic>?,
        ),
        displayInfo: _parseDisplayInfo(
          data['displayInfo'] as Map<dynamic, dynamic>?,
        ),
        batteryInfo: batteryInfo,
        sensorInfo: sensorInfo,
        networkInfo: networkInfo,
        securityInfo: _parseSecurityInfo(
          data['securityInfo'] as Map<dynamic, dynamic>?,
        ),
      );
    } catch (e) {
      throw DeviceInfoException('Failed to get device information: $e');
    }
  }

  /// Gets the current platform name as a string.
  ///
  /// Returns the platform name: 'android', 'ios', 'windows', 'macos',
  /// 'linux', or 'web'.
  String getCurrentPlatform() {
    if (kIsWeb) {
      return 'web';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }

  /// Gets current battery information.
  ///
  /// Returns [BatteryInfo] with current battery status, level, health,
  /// and charging information. Returns null if battery information
  /// is not available on the current platform.
  Future<BatteryInfo?> getBatteryInfo() async {
    try {
      if (kIsWeb) {
        return FlutterDeviceInfoPlusPlatform.instance.getBatteryInfo();
      }

      final data =
          await _channel.invokeMethod('getBatteryInfo')
              as Map<dynamic, dynamic>?;

      if (data == null) {
        return null;
      }

      return BatteryInfo(
        batteryLevel: data['batteryLevel'] as int? ?? 0,
        chargingStatus: data['chargingStatus'] as String? ?? 'unknown',
        batteryHealth: data['batteryHealth'] as String? ?? 'unknown',
        batteryCapacity: data['batteryCapacity'] as int? ?? 0,
        batteryVoltage: (data['batteryVoltage'] as num?)?.toDouble() ?? 0.0,
        batteryTemperature:
            (data['batteryTemperature'] as num?)?.toDouble() ?? 0.0,
      );
    } catch (e) {
      throw DeviceInfoException('Failed to get battery info: $e');
    }
  }

  /// Gets information about available sensors on the device.
  ///
  /// Returns [SensorInfo] containing a list of all available sensors
  /// and their capabilities.
  Future<SensorInfo> getSensorInfo() async {
    try {
      if (kIsWeb) {
        return FlutterDeviceInfoPlusPlatform.instance.getSensorInfo();
      }

      final data =
          await _channel.invokeMethod('getSensorInfo') as Map<dynamic, dynamic>;

      final sensors = data['availableSensors'] as List<dynamic>? ?? [];
      final sensorTypes = sensors
          .map((final s) => _stringToSensorType(s as String))
          .whereType<SensorType>()
          .toList();

      return SensorInfo(availableSensors: sensorTypes);
    } catch (e) {
      throw DeviceInfoException('Failed to get sensor info: $e');
    }
  }

  /// Gets current network information.
  ///
  /// Returns [NetworkInfo] with details about the current network
  /// connection including type, speed, and interface information.
  Future<NetworkInfo> getNetworkInfo() async {
    try {
      if (kIsWeb) {
        return FlutterDeviceInfoPlusPlatform.instance.getNetworkInfo();
      }

      final data =
          await _channel.invokeMethod('getNetworkInfo')
              as Map<dynamic, dynamic>;

      return NetworkInfo(
        connectionType: data['connectionType'] as String? ?? 'none',
        networkSpeed: data['networkSpeed'] as String? ?? 'Unknown',
        isConnected: data['isConnected'] as bool? ?? false,
        ipAddress: data['ipAddress'] as String? ?? 'unknown',
        macAddress: data['macAddress'] as String? ?? 'unknown',
      );
    } catch (e) {
      throw DeviceInfoException('Failed to get network info: $e');
    }
  }

  ProcessorInfo _parseProcessorInfo(final Map<dynamic, dynamic>? data) {
    if (data == null) {
      return const ProcessorInfo(
        architecture: 'unknown',
        coreCount: 0,
        maxFrequency: 0,
        processorName: 'Unknown',
        features: [],
      );
    }

    final features = (data['features'] as List<dynamic>?)?.cast<String>() ?? [];

    return ProcessorInfo(
      architecture: data['architecture'] as String? ?? 'unknown',
      coreCount: (data['coreCount'] as num?)?.toInt() ?? 0,
      maxFrequency: (data['maxFrequency'] as num?)?.toInt() ?? 0,
      processorName: data['processorName'] as String? ?? 'Unknown',
      features: features,
    );
  }

  MemoryInfo _parseMemoryInfo(final Map<dynamic, dynamic>? data) {
    if (data == null) {
      return const MemoryInfo(
        totalPhysicalMemory: 0,
        availablePhysicalMemory: 0,
        totalStorageSpace: 0,
        availableStorageSpace: 0,
        usedStorageSpace: 0,
        memoryUsagePercentage: 0,
      );
    }

    return MemoryInfo(
      totalPhysicalMemory: (data['totalPhysicalMemory'] as num?)?.toInt() ?? 0,
      availablePhysicalMemory:
          (data['availablePhysicalMemory'] as num?)?.toInt() ?? 0,
      totalStorageSpace: (data['totalStorageSpace'] as num?)?.toInt() ?? 0,
      availableStorageSpace:
          (data['availableStorageSpace'] as num?)?.toInt() ?? 0,
      usedStorageSpace: (data['usedStorageSpace'] as num?)?.toInt() ?? 0,
      memoryUsagePercentage:
          (data['memoryUsagePercentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  DisplayInfo _parseDisplayInfo(final Map<dynamic, dynamic>? data) {
    if (data == null) {
      return const DisplayInfo(
        screenWidth: 0,
        screenHeight: 0,
        pixelDensity: 1,
        refreshRate: 60,
        screenSizeInches: 0,
        orientation: 'portrait',
        isHdr: false,
      );
    }

    return DisplayInfo(
      screenWidth: (data['screenWidth'] as num?)?.toInt() ?? 0,
      screenHeight: (data['screenHeight'] as num?)?.toInt() ?? 0,
      pixelDensity: (data['pixelDensity'] as num?)?.toDouble() ?? 1.0,
      refreshRate: (data['refreshRate'] as num?)?.toDouble() ?? 60.0,
      screenSizeInches: (data['screenSizeInches'] as num?)?.toDouble() ?? 0.0,
      orientation: data['orientation'] as String? ?? 'portrait',
      isHdr: data['isHdr'] as bool? ?? false,
    );
  }

  SecurityInfo _parseSecurityInfo(final Map<dynamic, dynamic>? data) {
    if (data == null) {
      return const SecurityInfo(
        isDeviceSecure: false,
        hasFingerprint: false,
        hasFaceUnlock: false,
        screenLockEnabled: false,
        encryptionStatus: 'unknown',
      );
    }

    return SecurityInfo(
      isDeviceSecure: data['isDeviceSecure'] as bool? ?? false,
      hasFingerprint: data['hasFingerprint'] as bool? ?? false,
      hasFaceUnlock: data['hasFaceUnlock'] as bool? ?? false,
      screenLockEnabled: data['screenLockEnabled'] as bool? ?? false,
      encryptionStatus: data['encryptionStatus'] as String? ?? 'unknown',
    );
  }

  SensorType? _stringToSensorType(final String sensor) {
    switch (sensor.toLowerCase()) {
      case 'accelerometer':
        return SensorType.accelerometer;
      case 'gyroscope':
        return SensorType.gyroscope;
      case 'magnetometer':
        return SensorType.magnetometer;
      case 'proximity':
        return SensorType.proximity;
      case 'light':
        return SensorType.light;
      case 'barometer':
        return SensorType.barometer;
      case 'temperature':
        return SensorType.temperature;
      case 'humidity':
        return SensorType.humidity;
      case 'stepcounter':
        return SensorType.stepCounter;
      case 'heartrate':
        return SensorType.heartRate;
      case 'gravity':
        return SensorType.gravity;
      case 'linearacceleration':
        return SensorType.linearAcceleration;
      case 'rotationvector':
        return SensorType.rotationVector;
      case 'fingerprint':
        return SensorType.fingerprint;
      case 'facerecognition':
        return SensorType.faceRecognition;
      default:
        return null;
    }
  }
}
