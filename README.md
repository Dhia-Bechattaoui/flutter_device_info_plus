# flutter_device_info_plus

[![pub package](https://img.shields.io/pub/v/flutter_device_info_plus.svg)](https://pub.dev/packages/flutter_device_info_plus)
[![popularity](https://badges.bar/flutter_device_info_plus/popularity)](https://pub.dev/packages/flutter_device_info_plus/score)
[![likes](https://badges.bar/flutter_device_info_plus/likes)](https://pub.dev/packages/flutter_device_info_plus/score)
[![pub points](https://badges.bar/flutter_device_info_plus/pub%20points)](https://pub.dev/packages/flutter_device_info_plus/score)
[![code style: very good analysis](https://img.shields.io/badge/style-very_good_analysis-B22C89.svg)](https://pub.dev/packages/very_good_analysis)

Enhanced device information with detailed hardware specs and capabilities. Get comprehensive device data including CPU, memory, storage, sensors, and system information across all Flutter platforms.

<img src="assets/example.gif" width="300" alt="Example demonstration">

## Features

🚀 **Comprehensive Device Information**
- CPU details (architecture, cores, frequency)
- Memory information (RAM, storage, usage)
- Display specifications (resolution, density, refresh rate)
- Battery status and health information
- Sensor availability and capabilities
- Network interface details
- Operating system and build information

🎯 **Cross-Platform Support**
- ✅ Android (API 21+)
- ✅ iOS (iOS 12.0+ with Swift Package Manager)
- ✅ Web (Progressive Web App + WASM compatible)
- ✅ Windows (Windows 10+)
- ✅ macOS (macOS 10.14+ with Swift Package Manager)
- ✅ Linux (Ubuntu 18.04+)

🔧 **Developer Friendly**
- Null safety support
- Comprehensive documentation (100% API coverage)
- Rich examples and usage guides
- High test coverage (>90%)
- Consistent API across platforms
- Perfect 160/160 pub.dev score

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  flutter_device_info_plus: ^0.1.0
```

Then run:

```bash
flutter pub get
```

### Requirements

- **Dart SDK**: >=3.8.0
- **Flutter**: >=3.32.0

## Usage

### Basic Usage

```dart
import 'package:flutter_device_info_plus/flutter_device_info_plus.dart';

void main() async {
  final deviceInfo = FlutterDeviceInfoPlus();
  
  // Get comprehensive device information
  final info = await deviceInfo.getDeviceInfo();
  
  print('Device: ${info.deviceName}');
  print('OS: ${info.operatingSystem} ${info.systemVersion}');
  print('CPU: ${info.processorInfo.architecture} (${info.processorInfo.coreCount} cores)');
  print('RAM: ${info.memoryInfo.totalPhysicalMemory ~/ (1024 * 1024)} MB');
}
```

### Detailed Hardware Information

```dart
import 'package:flutter_device_info_plus/flutter_device_info_plus.dart';

class DeviceInfoExample extends StatefulWidget {
  @override
  _DeviceInfoExampleState createState() => _DeviceInfoExampleState();
}

class _DeviceInfoExampleState extends State<DeviceInfoExample> {
  final _deviceInfo = FlutterDeviceInfoPlus();
  DeviceInformation? _deviceInformation;

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    try {
      final info = await _deviceInfo.getDeviceInfo();
      setState(() {
        _deviceInformation = info;
      });
    } catch (e) {
      print('Error getting device info: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_deviceInformation == null) {
      return const CircularProgressIndicator();
    }

    final info = _deviceInformation!;
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoCard('Device Information', [
          'Name: ${info.deviceName}',
          'Manufacturer: ${info.manufacturer}',
          'Model: ${info.model}',
          'Brand: ${info.brand}',
        ]),
        
        _buildInfoCard('System Information', [
          'OS: ${info.operatingSystem}',
          'Version: ${info.systemVersion}',
          'Build: ${info.buildNumber}',
          'Kernel: ${info.kernelVersion}',
        ]),
        
        _buildInfoCard('Hardware Specifications', [
          'CPU: ${info.processorInfo.architecture}',
          'Cores: ${info.processorInfo.coreCount}',
          'Frequency: ${info.processorInfo.maxFrequency} MHz',
          'RAM: ${info.memoryInfo.totalPhysicalMemory ~/ (1024 * 1024)} MB',
          'Available RAM: ${info.memoryInfo.availablePhysicalMemory ~/ (1024 * 1024)} MB',
        ]),
        
        _buildInfoCard('Display Information', [
          'Resolution: ${info.displayInfo.screenWidth}x${info.displayInfo.screenHeight}',
          'Density: ${info.displayInfo.pixelDensity.toStringAsFixed(2)}',
          'Refresh Rate: ${info.displayInfo.refreshRate} Hz',
          'Size: ${info.displayInfo.screenSizeInches.toStringAsFixed(1)}"',
        ]),
        
        if (info.batteryInfo != null)
          _buildInfoCard('Battery Information', [
            'Level: ${info.batteryInfo!.batteryLevel}%',
            'Status: ${info.batteryInfo!.chargingStatus}',
            'Health: ${info.batteryInfo!.batteryHealth}',
            'Capacity: ${info.batteryInfo!.batteryCapacity} mAh',
          ]),
        
        _buildInfoCard('Available Sensors', 
          info.sensorInfo.availableSensors.map((s) => s.toString()).toList()),
      ],
    );
  }

  Widget _buildInfoCard(String title, List<String> items) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(item),
            )),
          ],
        ),
      ),
    );
  }
}
```

### Platform-Specific Information

```dart
// Get platform-specific details
final platformInfo = await deviceInfo.getPlatformInfo();

if (platformInfo is AndroidDeviceInfo) {
  print('Android API Level: ${platformInfo.sdkInt}');
  print('Security Patch: ${platformInfo.securityPatch}');
} else if (platformInfo is IosDeviceInfo) {
  print('iOS Version: ${platformInfo.systemVersion}');
  print('Device Type: ${platformInfo.model}');
} else if (platformInfo is WebBrowserInfo) {
  print('Browser: ${platformInfo.browserName}');
  print('User Agent: ${platformInfo.userAgent}');
}
```

## API Reference

### DeviceInformation

The main class containing all device information:

```dart
class DeviceInformation {
  final String deviceName;
  final String manufacturer;
  final String model;
  final String brand;
  final String operatingSystem;
  final String systemVersion;
  final String buildNumber;
  final String kernelVersion;
  final ProcessorInfo processorInfo;
  final MemoryInfo memoryInfo;
  final DisplayInfo displayInfo;
  final BatteryInfo? batteryInfo;
  final SensorInfo sensorInfo;
  final NetworkInfo networkInfo;
  final SecurityInfo securityInfo;
}
```

### ProcessorInfo

CPU and processor information:

```dart
class ProcessorInfo {
  final String architecture;
  final int coreCount;
  final int maxFrequency;
  final String processorName;
  final List<String> features;
}
```

### MemoryInfo

Memory and storage information:

```dart
class MemoryInfo {
  final int totalPhysicalMemory;
  final int availablePhysicalMemory;
  final int totalStorageSpace;
  final int availableStorageSpace;
  final int usedStorageSpace;
  final double memoryUsagePercentage;
}
```

### DisplayInfo

Display and screen information:

```dart
class DisplayInfo {
  final int screenWidth;
  final int screenHeight;
  final double pixelDensity;
  final double refreshRate;
  final double screenSizeInches;
  final String orientation;
  final bool isHdr;
}
```

### BatteryInfo

Battery status and health information:

```dart
class BatteryInfo {
  final int batteryLevel;
  final String chargingStatus;
  final String batteryHealth;
  final int batteryCapacity;
  final double batteryVoltage;
  final double batteryTemperature;
}
```

## Platform Support

| Platform | Device Info | Hardware Specs | Battery Info | Sensors | Network Info | SPM Support | WASM |
|----------|-------------|----------------|--------------|---------|--------------|-------------|------|
| Android  | ✅          | ✅             | ✅           | ✅      | ✅           | N/A         | N/A  |
| iOS      | ✅          | ✅             | ✅           | ✅      | ✅           | ✅          | N/A  |
| Web      | ✅          | ⚠️*            | ⚠️*          | ✅      | ✅           | N/A         | ✅   |
| Windows  | ✅          | ✅             | ✅           | ✅      | ✅           | N/A         | N/A  |
| macOS    | ✅          | ✅             | ✅           | ✅      | ✅           | ✅          | N/A  |
| Linux    | ✅          | ✅             | ⚠️*          | ✅      | ✅           | N/A         | N/A  |

*Limited information available due to platform restrictions  
SPM = Swift Package Manager, WASM = WebAssembly

## Examples

Check out the [example directory](./example) for complete working examples:

- [Basic Usage](./example/lib/basic_example.dart)
- [Advanced Hardware Info](./example/lib/advanced_example.dart)
- [Platform-Specific Details](./example/lib/platform_example.dart)
- [Real-time Monitoring](./example/lib/monitoring_example.dart)

## Contributing

Contributions are welcome! Please read our [contributing guidelines](CONTRIBUTING.md) before submitting PRs.

### Development Setup

1. Clone the repository
2. Run `flutter pub get`
3. Run tests: `flutter test`
4. Run example: `cd example && flutter run`

## License

This project is licensed under the BSD-3-Clause License - see the [LICENSE](LICENSE) file for details.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a detailed list of changes.

## Support

- 📖 [Documentation](https://pub.dev/documentation/flutter_device_info_plus)
- 🐛 [Issue Tracker](https://github.com/Dhia-Bechattaoui/flutter_device_info_plus/issues)
- 💬 [Discussions](https://github.com/Dhia-Bechattaoui/flutter_device_info_plus/discussions)

---

Made with ❤️ for the Flutter community
