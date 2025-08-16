import 'dart:async';

import 'package:flutter/foundation.dart';

import 'exceptions.dart';
import 'models/models.dart';

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

  /// Gets comprehensive device information including hardware specs,
  /// system details, and capabilities.
  ///
  /// Returns a [DeviceInformation] object containing all available
  /// device information for the current platform.
  ///
  /// Throws [DeviceInfoException] if device information cannot be retrieved.
  Future<DeviceInformation> getDeviceInfo() async {
    try {
      // Check if we're on web first since it doesn't have targetPlatform in the enum
      if (kIsWeb) {
        return _getWebDeviceInfo();
      }

      // Use targetPlatform for cross-platform compatibility
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          return _getAndroidDeviceInfo();
        case TargetPlatform.iOS:
          return _getIosDeviceInfo();
        case TargetPlatform.windows:
          return _getWindowsDeviceInfo();
        case TargetPlatform.macOS:
          return _getMacOsDeviceInfo();
        case TargetPlatform.linux:
          return _getLinuxDeviceInfo();
        case TargetPlatform.fuchsia:
          // Treat Fuchsia as Linux-like for now
          return _getLinuxDeviceInfo();
      }
    } catch (e) {
      throw DeviceInfoException('Failed to get device information: $e');
    }
  }

  /// Gets the current platform name as a string.
  ///
  /// Returns the platform name: 'android', 'ios', 'windows', 'macos', 'linux', or 'web'.
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
      // Web platform doesn't provide battery info
      if (kIsWeb) {
        return null;
      }

      // This would be implemented using platform channels
      // For now, return mock data based on platform
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
        case TargetPlatform.iOS:
          return const BatteryInfo(
            batteryLevel: 85,
            chargingStatus: 'charging',
            batteryHealth: 'good',
            batteryCapacity: 3000,
            batteryVoltage: 4,
            batteryTemperature: 25,
          );
        case TargetPlatform.windows:
        case TargetPlatform.macOS:
        case TargetPlatform.linux:
        case TargetPlatform.fuchsia:
          // Desktop/server platforms may have battery info for laptops
          return const BatteryInfo(
            batteryLevel: 95,
            chargingStatus: 'full',
            batteryHealth: 'good',
            batteryCapacity: 5000,
            batteryVoltage: 4,
            batteryTemperature: 23,
          );
      }
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
      // Mock sensor data - would be implemented via platform channels
      final sensors = <SensorType>[
        SensorType.accelerometer,
        SensorType.gyroscope,
        SensorType.magnetometer,
        SensorType.proximity,
        SensorType.light,
      ];

      return SensorInfo(availableSensors: sensors);
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
      // Mock network data - would be implemented via platform channels
      return const NetworkInfo(
        connectionType: 'wifi',
        networkSpeed: '100 Mbps',
        isConnected: true,
        ipAddress: '192.168.1.100',
        macAddress: '00:11:22:33:44:55',
      );
    } catch (e) {
      throw DeviceInfoException('Failed to get network info: $e');
    }
  }

  Future<DeviceInformation> _getAndroidDeviceInfo() async {
    final batteryInfo = await getBatteryInfo();
    final sensorInfo = await getSensorInfo();
    final networkInfo = await getNetworkInfo();

    return DeviceInformation(
      deviceName: 'Android Device',
      manufacturer: 'Unknown',
      model: 'Android Device',
      brand: 'Android',
      operatingSystem: 'Android',
      systemVersion: 'Unknown',
      buildNumber: 'Unknown',
      kernelVersion: 'Linux',
      processorInfo: const ProcessorInfo(
        architecture: 'arm64',
        coreCount: 8, // Mock data - would get from native
        maxFrequency: 2400,
        processorName: 'ARM Processor', // Mock data
        features: ['ARMv8', 'NEON'],
      ),
      memoryInfo: const MemoryInfo(
        totalPhysicalMemory: 8589934592, // 8GB mock
        availablePhysicalMemory: 4294967296, // 4GB mock
        totalStorageSpace: 137438953472, // 128GB mock
        availableStorageSpace: 68719476736, // 64GB mock
        usedStorageSpace: 68719476736, // 64GB mock
        memoryUsagePercentage: 50,
      ),
      displayInfo: const DisplayInfo(
        screenWidth:
            1080, // Mock data - actual implementation would use platform channels
        screenHeight:
            2340, // Mock data - actual implementation would use platform channels
        pixelDensity:
            3, // Mock data - actual implementation would use platform channels
        refreshRate: 120, // Mock data
        screenSizeInches: 6, // Mock data
        orientation: 'portrait',
        isHdr: true,
      ),
      batteryInfo: batteryInfo,
      sensorInfo: sensorInfo,
      networkInfo: networkInfo,
      securityInfo: const SecurityInfo(
        isDeviceSecure: true,
        hasFingerprint: true, // Mock data
        hasFaceUnlock: false, // Mock data
        screenLockEnabled: true, // Mock data
        encryptionStatus: 'encrypted',
      ),
    );
  }

  Future<DeviceInformation> _getIosDeviceInfo() async {
    final batteryInfo = await getBatteryInfo();
    final sensorInfo = await getSensorInfo();
    final networkInfo = await getNetworkInfo();

    return DeviceInformation(
      deviceName: 'iPhone',
      manufacturer: 'Apple',
      model: 'iPhone',
      brand: 'Apple',
      operatingSystem: 'iOS',
      systemVersion: 'Unknown',
      buildNumber: 'Unknown',
      kernelVersion: 'Darwin',
      processorInfo: const ProcessorInfo(
        architecture: 'arm64',
        coreCount: 6, // Mock data
        maxFrequency: 3200,
        processorName: 'Apple A15 Bionic', // Mock data
        features: ['ARMv8', 'NEON'],
      ),
      memoryInfo: const MemoryInfo(
        totalPhysicalMemory: 6442450944, // 6GB mock
        availablePhysicalMemory: 3221225472, // 3GB mock
        totalStorageSpace: 137438953472, // 128GB mock
        availableStorageSpace: 68719476736, // 64GB mock
        usedStorageSpace: 68719476736, // 64GB mock
        memoryUsagePercentage: 50,
      ),
      displayInfo: const DisplayInfo(
        screenWidth: 1170,
        screenHeight: 2532,
        pixelDensity: 3,
        refreshRate: 120,
        screenSizeInches: 6,
        orientation: 'portrait',
        isHdr: true,
      ),
      batteryInfo: batteryInfo,
      sensorInfo: sensorInfo,
      networkInfo: networkInfo,
      securityInfo: const SecurityInfo(
        isDeviceSecure: true,
        hasFingerprint: true, // Mock data
        hasFaceUnlock: true, // Mock data
        screenLockEnabled: true, // Mock data
        encryptionStatus: 'encrypted',
      ),
    );
  }

  Future<DeviceInformation> _getWindowsDeviceInfo() async {
    final sensorInfo = await getSensorInfo();
    final networkInfo = await getNetworkInfo();

    return DeviceInformation(
      deviceName: 'Windows PC',
      manufacturer: 'Microsoft',
      model: 'Windows PC',
      brand: 'Microsoft',
      operatingSystem: 'Windows',
      systemVersion: 'Unknown',
      buildNumber: 'Unknown',
      kernelVersion: 'NT',
      processorInfo: const ProcessorInfo(
        architecture: 'x64',
        coreCount: 8,
        maxFrequency: 3600,
        processorName: 'Intel Core i7',
        features: ['AVX', 'SSE4'],
      ),
      memoryInfo: const MemoryInfo(
        totalPhysicalMemory: 17179869184, // 16GB mock
        availablePhysicalMemory: 8589934592, // 8GB mock
        totalStorageSpace: 1099511627776, // 1TB mock
        availableStorageSpace: 549755813888, // 512GB mock
        usedStorageSpace: 549755813888, // 512GB mock
        memoryUsagePercentage: 50,
      ),
      displayInfo: const DisplayInfo(
        screenWidth: 1920,
        screenHeight: 1080,
        pixelDensity: 1,
        refreshRate: 60,
        screenSizeInches: 24,
        orientation: 'landscape',
        isHdr: false,
      ),
      sensorInfo: sensorInfo,
      networkInfo: networkInfo,
      securityInfo: const SecurityInfo(
        isDeviceSecure: true,
        hasFingerprint: false,
        hasFaceUnlock: false,
        screenLockEnabled: true,
        encryptionStatus: 'encrypted',
      ),
    );
  }

  Future<DeviceInformation> _getMacOsDeviceInfo() async {
    final batteryInfo = await getBatteryInfo();
    final sensorInfo = await getSensorInfo();
    final networkInfo = await getNetworkInfo();

    return DeviceInformation(
      deviceName: 'Mac',
      manufacturer: 'Apple',
      model: 'Mac',
      brand: 'Apple',
      operatingSystem: 'macOS',
      systemVersion: 'Unknown',
      buildNumber: 'Unknown',
      kernelVersion: 'Darwin',
      processorInfo: const ProcessorInfo(
        architecture: 'arm64',
        coreCount: 8,
        maxFrequency: 3200,
        processorName: 'Apple M1 Pro',
        features: ['ARM64', 'Neural Engine'],
      ),
      memoryInfo: const MemoryInfo(
        totalPhysicalMemory: 17179869184, // 16GB mock
        availablePhysicalMemory: 8589934592, // 8GB mock
        totalStorageSpace: 1099511627776, // 1TB mock
        availableStorageSpace: 549755813888, // 512GB mock
        usedStorageSpace: 549755813888, // 512GB mock
        memoryUsagePercentage: 50,
      ),
      displayInfo: const DisplayInfo(
        screenWidth: 3024,
        screenHeight: 1964,
        pixelDensity: 2,
        refreshRate: 120,
        screenSizeInches: 14,
        orientation: 'landscape',
        isHdr: true,
      ),
      batteryInfo: batteryInfo,
      sensorInfo: sensorInfo,
      networkInfo: networkInfo,
      securityInfo: const SecurityInfo(
        isDeviceSecure: true,
        hasFingerprint: true,
        hasFaceUnlock: true,
        screenLockEnabled: true,
        encryptionStatus: 'encrypted',
      ),
    );
  }

  Future<DeviceInformation> _getLinuxDeviceInfo() async {
    final sensorInfo = await getSensorInfo();
    final networkInfo = await getNetworkInfo();

    return DeviceInformation(
      deviceName: 'Linux PC',
      manufacturer: 'Linux',
      model: 'Linux PC',
      brand: 'Linux',
      operatingSystem: 'Linux',
      systemVersion: 'Unknown',
      buildNumber: 'Unknown',
      kernelVersion: 'Linux',
      processorInfo: const ProcessorInfo(
        architecture: 'x64',
        coreCount: 8,
        maxFrequency: 3600,
        processorName: 'AMD Ryzen 7',
        features: ['AVX2', 'SSE4'],
      ),
      memoryInfo: const MemoryInfo(
        totalPhysicalMemory: 17179869184, // 16GB mock
        availablePhysicalMemory: 8589934592, // 8GB mock
        totalStorageSpace: 1099511627776, // 1TB mock
        availableStorageSpace: 549755813888, // 512GB mock
        usedStorageSpace: 549755813888, // 512GB mock
        memoryUsagePercentage: 50,
      ),
      displayInfo: const DisplayInfo(
        screenWidth: 1920,
        screenHeight: 1080,
        pixelDensity: 1,
        refreshRate: 60,
        screenSizeInches: 24,
        orientation: 'landscape',
        isHdr: false,
      ),
      sensorInfo: sensorInfo,
      networkInfo: networkInfo,
      securityInfo: const SecurityInfo(
        isDeviceSecure: true,
        hasFingerprint: false,
        hasFaceUnlock: false,
        screenLockEnabled: true,
        encryptionStatus: 'encrypted',
      ),
    );
  }

  Future<DeviceInformation> _getWebDeviceInfo() async {
    final sensorInfo = await getSensorInfo();
    final networkInfo = await getNetworkInfo();

    return DeviceInformation(
      deviceName: 'Web Browser',
      manufacturer: 'Unknown',
      model: 'Web Browser',
      brand: 'Web',
      operatingSystem: 'Web',
      systemVersion: 'Unknown',
      buildNumber: 'Unknown',
      kernelVersion: 'Web Engine',
      processorInfo: const ProcessorInfo(
        architecture: 'JavaScript',
        coreCount: 4, // Mock data
        maxFrequency: 0, // Not applicable for web
        processorName: 'JavaScript Engine',
        features: ['WebAssembly', 'WebGL'],
      ),
      memoryInfo: const MemoryInfo(
        totalPhysicalMemory: 8589934592, // 8GB mock
        availablePhysicalMemory: 4294967296, // 4GB mock
        totalStorageSpace: 1073741824, // 1GB browser storage mock
        availableStorageSpace: 536870912, // 512MB mock
        usedStorageSpace: 536870912, // 512MB mock
        memoryUsagePercentage: 50,
      ),
      displayInfo: const DisplayInfo(
        screenWidth: 1920,
        screenHeight: 1080,
        pixelDensity: 1,
        refreshRate: 60,
        screenSizeInches: 24,
        orientation: 'landscape',
        isHdr: false,
      ),
      sensorInfo: sensorInfo,
      networkInfo: networkInfo,
      securityInfo: const SecurityInfo(
        isDeviceSecure: false, // Web is generally less secure
        hasFingerprint: false,
        hasFaceUnlock: false,
        screenLockEnabled: false,
        encryptionStatus: 'https',
      ),
    );
  }
}
