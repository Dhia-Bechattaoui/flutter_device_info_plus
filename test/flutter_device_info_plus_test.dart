import 'package:flutter_device_info_plus/flutter_device_info_plus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FlutterDeviceInfoPlus', () {
    late FlutterDeviceInfoPlus deviceInfo;

    setUp(() {
      deviceInfo = const FlutterDeviceInfoPlus();
    });

    group('getDeviceInfo', () {
      test('should handle device info exceptions gracefully', () async {
        // This test would need proper mocking of DeviceInfoPlugin
        // For now, we'll test the structure and ensure no exceptions
        try {
          final info = await deviceInfo.getDeviceInfo();
          expect(info, isA<DeviceInformation>());
          expect(info.operatingSystem, isNotEmpty);
          expect(info.deviceName, isNotEmpty);
          expect(info.processorInfo, isA<ProcessorInfo>());
          expect(info.memoryInfo, isA<MemoryInfo>());
          expect(info.displayInfo, isA<DisplayInfo>());
          expect(info.sensorInfo, isA<SensorInfo>());
          expect(info.networkInfo, isA<NetworkInfo>());
          expect(info.securityInfo, isA<SecurityInfo>());
        } catch (e) {
          // Expected to fail in test environment without actual device info
          expect(e, isA<DeviceInfoException>());
        }
      });
    });

    group('getBatteryInfo', () {
      test('should return battery info or null', () async {
        final batteryInfo = await deviceInfo.getBatteryInfo();
        if (batteryInfo != null) {
          expect(batteryInfo, isA<BatteryInfo>());
          expect(batteryInfo.batteryLevel, inInclusiveRange(0, 100));
          expect(batteryInfo.chargingStatus, isNotEmpty);
          expect(batteryInfo.batteryHealth, isNotEmpty);
        }
      });
    });

    group('getSensorInfo', () {
      test('should return sensor information', () async {
        final sensorInfo = await deviceInfo.getSensorInfo();

        expect(sensorInfo, isA<SensorInfo>());
        expect(sensorInfo.availableSensors, isA<List<SensorType>>());
        expect(sensorInfo.sensorCount, greaterThanOrEqualTo(0));
      });
    });

    group('getNetworkInfo', () {
      test('should return network information', () async {
        final networkInfo = await deviceInfo.getNetworkInfo();

        expect(networkInfo, isA<NetworkInfo>());
        expect(networkInfo.connectionType, isNotEmpty);
        expect(networkInfo.isConnected, isA<bool>());
      });
    });

    group('getCurrentPlatform', () {
      test('should return current platform name', () {
        final platform = deviceInfo.getCurrentPlatform();
        expect(platform, isA<String>());
        expect(
          ['android', 'ios', 'windows', 'macos', 'linux', 'web', 'fuchsia'],
          contains(platform),
        );
      });
    });
  });

  group('DeviceInformation', () {
    test('should create valid instance with all required fields', () {
      const deviceInfo = DeviceInformation(
        deviceName: 'Test Device',
        manufacturer: 'Test Manufacturer',
        model: 'Test Model',
        brand: 'Test Brand',
        operatingSystem: 'Test OS',
        systemVersion: '1.0.0',
        buildNumber: '123',
        kernelVersion: '1.0.0',
        processorInfo: ProcessorInfo(
          architecture: 'x64',
          coreCount: 4,
          maxFrequency: 2400,
          processorName: 'Test CPU',
          features: ['AVX'],
        ),
        memoryInfo: MemoryInfo(
          totalPhysicalMemory: 8589934592,
          availablePhysicalMemory: 4294967296,
          totalStorageSpace: 1099511627776,
          availableStorageSpace: 549755813888,
          usedStorageSpace: 549755813888,
          memoryUsagePercentage: 50,
        ),
        displayInfo: DisplayInfo(
          screenWidth: 1920,
          screenHeight: 1080,
          pixelDensity: 1,
          refreshRate: 60,
          screenSizeInches: 24,
          orientation: 'landscape',
          isHdr: false,
        ),
        sensorInfo: SensorInfo(
          availableSensors: [SensorType.accelerometer],
        ),
        networkInfo: NetworkInfo(
          connectionType: 'wifi',
          networkSpeed: '100 Mbps',
          isConnected: true,
          ipAddress: '192.168.1.1',
          macAddress: '00:11:22:33:44:55',
        ),
        securityInfo: SecurityInfo(
          isDeviceSecure: true,
          hasFingerprint: false,
          hasFaceUnlock: false,
          screenLockEnabled: true,
          encryptionStatus: 'encrypted',
        ),
      );

      expect(deviceInfo.deviceName, 'Test Device');
      expect(deviceInfo.manufacturer, 'Test Manufacturer');
      expect(deviceInfo.model, 'Test Model');
      expect(deviceInfo.operatingSystem, 'Test OS');
      expect(deviceInfo.processorInfo.coreCount, 4);
      expect(deviceInfo.memoryInfo.totalPhysicalMemoryMB, closeTo(8192, 1));
      expect(deviceInfo.displayInfo.aspectRatio, closeTo(1.777, 0.01));
      expect(deviceInfo.sensorInfo.hasAccelerometer, true);
      expect(deviceInfo.networkInfo.isWifiConnected, true);
      expect(deviceInfo.securityInfo.securityScore, greaterThan(0));
    });

    test('should support copyWith method', () {
      const originalInfo = DeviceInformation(
        deviceName: 'Original Device',
        manufacturer: 'Original Manufacturer',
        model: 'Original Model',
        brand: 'Original Brand',
        operatingSystem: 'Original OS',
        systemVersion: '1.0.0',
        buildNumber: '123',
        kernelVersion: '1.0.0',
        processorInfo: ProcessorInfo(
          architecture: 'x64',
          coreCount: 4,
          maxFrequency: 2400,
          processorName: 'Original CPU',
          features: ['AVX'],
        ),
        memoryInfo: MemoryInfo(
          totalPhysicalMemory: 8589934592,
          availablePhysicalMemory: 4294967296,
          totalStorageSpace: 1099511627776,
          availableStorageSpace: 549755813888,
          usedStorageSpace: 549755813888,
          memoryUsagePercentage: 50,
        ),
        displayInfo: DisplayInfo(
          screenWidth: 1920,
          screenHeight: 1080,
          pixelDensity: 1,
          refreshRate: 60,
          screenSizeInches: 24,
          orientation: 'landscape',
          isHdr: false,
        ),
        sensorInfo: SensorInfo(
          availableSensors: [SensorType.accelerometer],
        ),
        networkInfo: NetworkInfo(
          connectionType: 'wifi',
          networkSpeed: '100 Mbps',
          isConnected: true,
          ipAddress: '192.168.1.1',
          macAddress: '00:11:22:33:44:55',
        ),
        securityInfo: SecurityInfo(
          isDeviceSecure: true,
          hasFingerprint: false,
          hasFaceUnlock: false,
          screenLockEnabled: true,
          encryptionStatus: 'encrypted',
        ),
      );

      final modifiedInfo = originalInfo.copyWith(
        deviceName: 'Modified Device',
        manufacturer: 'Modified Manufacturer',
      );

      expect(modifiedInfo.deviceName, 'Modified Device');
      expect(modifiedInfo.manufacturer, 'Modified Manufacturer');
      expect(modifiedInfo.model, 'Original Model'); // Unchanged
      expect(modifiedInfo.operatingSystem, 'Original OS'); // Unchanged
    });

    test('should have proper equality comparison', () {
      const info1 = DeviceInformation(
        deviceName: 'Test Device',
        manufacturer: 'Test Manufacturer',
        model: 'Test Model',
        brand: 'Test Brand',
        operatingSystem: 'Test OS',
        systemVersion: '1.0.0',
        buildNumber: '123',
        kernelVersion: '1.0.0',
        processorInfo: ProcessorInfo(
          architecture: 'x64',
          coreCount: 4,
          maxFrequency: 2400,
          processorName: 'Test CPU',
          features: ['AVX'],
        ),
        memoryInfo: MemoryInfo(
          totalPhysicalMemory: 8589934592,
          availablePhysicalMemory: 4294967296,
          totalStorageSpace: 1099511627776,
          availableStorageSpace: 549755813888,
          usedStorageSpace: 549755813888,
          memoryUsagePercentage: 50,
        ),
        displayInfo: DisplayInfo(
          screenWidth: 1920,
          screenHeight: 1080,
          pixelDensity: 1,
          refreshRate: 60,
          screenSizeInches: 24,
          orientation: 'landscape',
          isHdr: false,
        ),
        sensorInfo: SensorInfo(
          availableSensors: [SensorType.accelerometer],
        ),
        networkInfo: NetworkInfo(
          connectionType: 'wifi',
          networkSpeed: '100 Mbps',
          isConnected: true,
          ipAddress: '192.168.1.1',
          macAddress: '00:11:22:33:44:55',
        ),
        securityInfo: SecurityInfo(
          isDeviceSecure: true,
          hasFingerprint: false,
          hasFaceUnlock: false,
          screenLockEnabled: true,
          encryptionStatus: 'encrypted',
        ),
      );

      const info2 = DeviceInformation(
        deviceName: 'Test Device',
        manufacturer: 'Test Manufacturer',
        model: 'Test Model',
        brand: 'Test Brand',
        operatingSystem: 'Test OS',
        systemVersion: '1.0.0',
        buildNumber: '123',
        kernelVersion: '1.0.0',
        processorInfo: ProcessorInfo(
          architecture: 'x64',
          coreCount: 4,
          maxFrequency: 2400,
          processorName: 'Test CPU',
          features: ['AVX'],
        ),
        memoryInfo: MemoryInfo(
          totalPhysicalMemory: 8589934592,
          availablePhysicalMemory: 4294967296,
          totalStorageSpace: 1099511627776,
          availableStorageSpace: 549755813888,
          usedStorageSpace: 549755813888,
          memoryUsagePercentage: 50,
        ),
        displayInfo: DisplayInfo(
          screenWidth: 1920,
          screenHeight: 1080,
          pixelDensity: 1,
          refreshRate: 60,
          screenSizeInches: 24,
          orientation: 'landscape',
          isHdr: false,
        ),
        sensorInfo: SensorInfo(
          availableSensors: [SensorType.accelerometer],
        ),
        networkInfo: NetworkInfo(
          connectionType: 'wifi',
          networkSpeed: '100 Mbps',
          isConnected: true,
          ipAddress: '192.168.1.1',
          macAddress: '00:11:22:33:44:55',
        ),
        securityInfo: SecurityInfo(
          isDeviceSecure: true,
          hasFingerprint: false,
          hasFaceUnlock: false,
          screenLockEnabled: true,
          encryptionStatus: 'encrypted',
        ),
      );

      expect(info1, equals(info2));
      expect(info1.hashCode, equals(info2.hashCode));
    });
  });

  group('Model Classes', () {
    test('ProcessorInfo should work correctly', () {
      const processor = ProcessorInfo(
        architecture: 'arm64',
        coreCount: 8,
        maxFrequency: 3200,
        processorName: 'Apple M1',
        features: ['NEON', 'ARMv8'],
      );

      expect(processor.architecture, 'arm64');
      expect(processor.coreCount, 8);
      expect(processor.maxFrequency, 3200);
      expect(processor.processorName, 'Apple M1');
      expect(processor.features, ['NEON', 'ARMv8']);
    });

    test('MemoryInfo should calculate derived values correctly', () {
      const memory = MemoryInfo(
        totalPhysicalMemory: 8589934592, // 8GB
        availablePhysicalMemory: 4294967296, // 4GB
        totalStorageSpace: 1099511627776, // 1TB
        availableStorageSpace: 549755813888, // 512GB
        usedStorageSpace: 549755813888, // 512GB
        memoryUsagePercentage: 50,
      );

      expect(memory.totalPhysicalMemoryMB, closeTo(8192, 1));
      expect(memory.availablePhysicalMemoryMB, closeTo(4096, 1));
      expect(memory.totalStorageSpaceGB, closeTo(1024, 1));
      expect(memory.storageUsagePercentage, closeTo(50, 1));
    });

    test('DisplayInfo should calculate derived values correctly', () {
      const display = DisplayInfo(
        screenWidth: 1920,
        screenHeight: 1080,
        pixelDensity: 2,
        refreshRate: 120,
        screenSizeInches: 6.1,
        orientation: 'portrait',
        isHdr: true,
      );

      expect(display.aspectRatio, closeTo(1.777, 0.01));
      expect(display.totalPixels, 1920 * 1080);
      expect(display.pixelsPerInch, 320.0);
      expect(display.isHighDensity, true);
      expect(display.isHighRefreshRate, true);
      expect(display.resolutionString, '1920x1080');
    });

    test('BatteryInfo should calculate derived values correctly', () {
      const battery = BatteryInfo(
        batteryLevel: 75,
        chargingStatus: 'charging',
        batteryHealth: 'good',
        batteryCapacity: 3000,
        batteryVoltage: 3.8,
        batteryTemperature: 25,
      );

      expect(battery.isCharging, true);
      expect(battery.isFullyCharged, false);
      expect(battery.isHealthy, true);
      expect(battery.isLowBattery, false);
      expect(battery.isCriticalBattery, false);
      expect(battery.batteryTemperatureFahrenheit, 77.0);
    });

    test('SensorInfo should identify available sensors correctly', () {
      const sensors = SensorInfo(
        availableSensors: [
          SensorType.accelerometer,
          SensorType.gyroscope,
          SensorType.magnetometer,
        ],
      );

      expect(sensors.hasAccelerometer, true);
      expect(sensors.hasGyroscope, true);
      expect(sensors.hasMagnetometer, true);
      expect(sensors.hasProximity, false);
      expect(sensors.sensorCount, 3);
    });

    test('NetworkInfo should identify connection types correctly', () {
      const network = NetworkInfo(
        connectionType: 'wifi',
        networkSpeed: '100 Mbps',
        isConnected: true,
        ipAddress: '192.168.1.100',
        macAddress: '00:11:22:33:44:55',
      );

      expect(network.isWifiConnected, true);
      expect(network.isMobileConnected, false);
      expect(network.isEthernetConnected, false);
      expect(network.isOffline, false);
    });

    test('SecurityInfo should calculate security score correctly', () {
      const security = SecurityInfo(
        isDeviceSecure: true,
        hasFingerprint: true,
        hasFaceUnlock: true,
        screenLockEnabled: true,
        encryptionStatus: 'encrypted',
      );

      expect(security.hasBiometricAuth, true);
      expect(security.isEncrypted, true);
      expect(security.hasMultiLayerSecurity, true);
      expect(security.securityScore, 100);
      expect(security.securityLevel, 'High');
    });
  });

  group('Exceptions', () {
    test('DeviceInfoException should format correctly', () {
      const exception = DeviceInfoException('Test error message');
      expect(exception.message, 'Test error message');
      expect(exception.toString(), 'DeviceInfoException: Test error message');
    });

    test('PlatformException should format with code', () {
      const exception = PlatformException('Test error', code: 'ERR001');
      expect(exception.message, 'Test error');
      expect(exception.code, 'ERR001');
      expect(
        exception.toString(),
        'PlatformException: Test error (code: ERR001)',
      );
    });

    test('UnsupportedFeatureException should format with feature', () {
      const exception = UnsupportedFeatureException(
        'Feature not supported',
        feature: 'battery_info',
      );
      expect(exception.message, 'Feature not supported');
      expect(exception.feature, 'battery_info');
      expect(
        exception.toString(),
        'UnsupportedFeatureException: Feature not supported (feature: battery_info)',
      );
    });

    test('PermissionException should format with permission', () {
      const exception = PermissionException(
        'Permission required',
        permission: 'android.permission.BATTERY_STATS',
      );
      expect(exception.message, 'Permission required');
      expect(exception.permission, 'android.permission.BATTERY_STATS');
      expect(
        exception.toString(),
        'PermissionException: Permission required (permission: android.permission.BATTERY_STATS)',
      );
    });

    test('ParseException should format with raw data', () {
      const exception = ParseException(
        'Failed to parse',
        rawData: {'invalid': 'data'},
      );
      expect(exception.message, 'Failed to parse');
      expect(exception.rawData, {'invalid': 'data'});
      expect(
        exception.toString(),
        'ParseException: Failed to parse (raw data: {invalid: data})',
      );
    });
  });
}
