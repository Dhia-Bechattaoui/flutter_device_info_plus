# flutter_device_info_plus

[![pub package](https://img.shields.io/pub/v/flutter_device_info_plus.svg)](https://pub.dev/packages/flutter_device_info_plus)
[![popularity](https://badges.bar/flutter_device_info_plus/popularity)](https://pub.dev/packages/flutter_device_info_plus/score)
[![likes](https://badges.bar/flutter_device_info_plus/likes)](https://pub.dev/packages/flutter_device_info_plus/score)
[![pub points](https://badges.bar/flutter_device_info_plus/pub%20points)](https://pub.dev/packages/flutter_device_info_plus/score)
[![code style: very good analysis](https://img.shields.io/badge/style-very_good_analysis-B22C89.svg)](https://pub.dev/packages/very_good_analysis)

A Flutter plugin for enhanced device information, providing detailed hardware specifications and capabilities. Access comprehensive device data including CPU, memory, storage, sensors, and system information across all Flutter platforms.

<img src="assets/example.gif" width="300" alt="Example demonstration">

## Features

- **Hardware Details**: Access CPU architecture, core count, frequency, and memory usage (RAM/storage).
- **Display Specs**: Read screen resolution, pixel density, and refresh rates.
- **System Information**: OS version, build numbers, kernel details, and sensor availability.
- **Web Support**: Uses Client Hints, Storage Quota, and Battery Status APIs on supported browsers.
- **Cross-Platform**: Consistent API across Android, iOS, macOS, Windows, Linux, and Web.

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_device_info_plus: ^0.3.2
```

### Requirements

- Dart SDK: >=3.8.0
- Flutter: >=3.32.0

## Usage

Here is a quick example of how to retrieve comprehensive device information:

```dart
import 'package:flutter_device_info_plus/flutter_device_info_plus.dart';

void main() async {
  final deviceInfo = FlutterDeviceInfoPlus();
  
  // Get all device data in one call
  final info = await deviceInfo.getDeviceInfo();
  
  print('Device: ${info.deviceName} (${info.brand} ${info.model})');
  print('OS: ${info.operatingSystem} ${info.systemVersion}');
  print('CPU: ${info.processorInfo.architecture} (${info.processorInfo.coreCount} cores)');
  print('RAM: ${info.memoryInfo.totalPhysicalMemory ~/ (1024 * 1024)} MB');
}
```

Check out the [example directory](./example) for more advanced usage patterns, including detailed UI representations and real-time monitoring.

## Platform Support

| Platform | Device Info | Hardware Specs | Battery Info | Sensors | Network Info |
|----------|-------------|----------------|--------------|---------|--------------|
| Android  | ✔️         | ✔️            | ✔️          | ✔️     | ✔️          |
| iOS      | ✔️         | ✔️            | ✔️          | ✔️     | ✔️          |
| Web      | ✔️         | ✔️*           | ✔️*         | ✔️     | ✔️          |
| Windows  | ✔️         | ✔️            | ✔️          | ✔️     | ✔️          |
| macOS    | ✔️         | ✔️            | ✔️          | ✔️     | ✔️          |
| Linux    | ✔️         | ✔️            | Limited      | ✔️     | ✔️          |

*\*Enhanced on supporting browsers via Client Hints & Battery API.*

## Support

- [Documentation](https://pub.dev/documentation/flutter_device_info_plus)
- [Issue Tracker](https://github.com/Dhia-Bechattaoui/flutter_device_info_plus/issues)
- [Changelog](CHANGELOG.md)
- [Contributing](CONTRIBUTING.md)
