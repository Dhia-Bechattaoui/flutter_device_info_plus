/// Web platform implementation for flutter_device_info_plus
///
/// This library provides device information retrieval capabilities
/// for web platforms using browser APIs and user agent parsing.
library;

import 'package:web/web.dart' as web;

import 'src/exceptions.dart';

/// Web implementation of FlutterDeviceInfoPlus
///
/// This class provides device information retrieval for web platforms
/// using browser APIs and user agent parsing.
class FlutterDeviceInfoPlusPlugin {
  /// Creates a new instance of FlutterDeviceInfoPlusPlugin
  FlutterDeviceInfoPlusPlugin();

  /// Registers the plugin with the Flutter engine
  ///
  /// This method is called during plugin initialization to register
  /// the web platform implementation.
  static void registerWith() {
    // Web platform registration
  }

  /// Retrieves comprehensive device information for web platforms
  ///
  /// Returns a map containing device details including:
  /// - Device name and browser information
  /// - Operating system and version
  /// - Processor information (architecture, core count)
  /// - Memory information
  /// - Display specifications (resolution, pixel density)
  /// - Security information
  ///
  /// Throws [DeviceInfoException] if device information cannot be retrieved.
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      final window = web.window;
      final screen = window.screen;
      final navigator = window.navigator;

      // Get user agent info
      final userAgent = navigator.userAgent;

      // Get screen info
      final screenWidth = screen.width.toInt();
      final screenHeight = screen.height.toInt();
      final pixelRatio = window.devicePixelRatio;

      // Get hardware concurrency (CPU cores)
      final hardwareConcurrency = navigator.hardwareConcurrency;

      // Get memory info (if available)
      final memory = _getMemoryInfo();

      // Detect browser
      final browserInfo = _detectBrowser(userAgent);

      return {
        'deviceName': browserInfo['name'] ?? 'Web Browser',
        'manufacturer': 'Unknown',
        'model': browserInfo['name'] ?? 'Web Browser',
        'brand': browserInfo['name'] ?? 'Web',
        'operatingSystem': _detectOS(userAgent),
        'systemVersion': _getOSVersion(userAgent),
        'buildNumber': 'Unknown',
        'kernelVersion': 'Web Engine',
        'processorInfo': {
          'architecture': _detectArchitecture(userAgent),
          'coreCount': hardwareConcurrency,
          'maxFrequency': 0,
          'processorName': 'JavaScript Engine',
          'features': _getProcessorFeatures(),
        },
        'memoryInfo': memory,
        'displayInfo': {
          'screenWidth': screenWidth,
          'screenHeight': screenHeight,
          'pixelDensity': pixelRatio,
          'refreshRate': _getRefreshRate(),
          'screenSizeInches': _calculateScreenSize(
            screenWidth,
            screenHeight,
            pixelRatio,
          ),
          'orientation': screenWidth > screenHeight ? 'landscape' : 'portrait',
          'isHdr': _checkHdrSupport(),
        },
        'securityInfo': {
          'isDeviceSecure': false,
          'hasFingerprint': false,
          'hasFaceUnlock': false,
          'screenLockEnabled': false,
          'encryptionStatus': window.location.protocol == 'https:'
              ? 'encrypted'
              : 'unencrypted',
        },
      };
    } catch (e) {
      throw DeviceInfoException('Failed to get device info: $e');
    }
  }

  /// Retrieves battery information for web platforms
  ///
  /// Currently returns null as the Battery API is not directly accessible
  /// via package:web. This can be enhanced when package:web adds Battery API support.
  ///
  /// Returns null if battery information is not available.
  static Future<Map<String, dynamic>?> getBatteryInfo() async {
    // Battery API is not directly accessible via package:web yet
    // Return null for now - can be enhanced when package:web adds Battery API support
    return null;
  }

  /// Retrieves sensor information for web platforms
  ///
  /// Returns a map containing available sensor types.
  /// Note: Sensor detection on web is limited due to browser security
  /// restrictions. This method provides a basic list of commonly
  /// available sensors.
  ///
  /// Returns a map with 'availableSensors' key containing a list of sensor types.
  static Future<Map<String, dynamic>> getSensorInfo() async {
    try {
      final sensors = <String>[];

      // Check for available sensors - simplified check
      // DeviceMotionEvent and DeviceOrientationEvent are not directly available in package:web
      // This is a basic implementation
      sensors.add('accelerometer'); // Assume available if browser supports it
      sensors.add('gyroscope');
      sensors.add('magnetometer');

      return {'availableSensors': sensors};
    } catch (e) {
      return {'availableSensors': <String>[]};
    }
  }

  /// Retrieves network information for web platforms
  ///
  /// Returns a map containing:
  /// - Connection type (wifi, unknown)
  /// - Network speed (if available)
  /// - Connection status (online/offline)
  /// - IP address and MAC address (limited availability on web)
  ///
  /// Note: Network connection details are limited on web platforms
  /// due to browser security restrictions.
  static Future<Map<String, dynamic>> getNetworkInfo() async {
    try {
      final navigator = web.window.navigator;

      String connectionType = 'unknown';
      String networkSpeed = 'Unknown';
      bool isConnected = navigator.onLine;

      // Network connection info is not directly available in package:web
      // Use basic online/offline detection
      if (isConnected) {
        connectionType = 'wifi'; // Assume WiFi if connected
        networkSpeed = 'Unknown';
      }

      return {
        'connectionType': connectionType,
        'networkSpeed': networkSpeed,
        'isConnected': isConnected,
        'ipAddress': 'unknown',
        'macAddress': 'unknown',
      };
    } catch (e) {
      final navigator = web.window.navigator;
      return {
        'connectionType': 'unknown',
        'networkSpeed': 'Unknown',
        'isConnected': navigator.onLine,
        'ipAddress': 'unknown',
        'macAddress': 'unknown',
      };
    }
  }

  static Map<String, dynamic> _getMemoryInfo() {
    // Performance.memory is Chrome-specific and not available in package:web
    // Return default values
    return {
      'totalPhysicalMemory': 8589934592,
      'availablePhysicalMemory': 4294967296,
      'totalStorageSpace': 0,
      'availableStorageSpace': 0,
      'usedStorageSpace': 0,
      'memoryUsagePercentage': 50.0,
    };
  }

  static Map<String, String> _detectBrowser(String userAgent) {
    if (userAgent.contains('Chrome') && !userAgent.contains('Edg')) {
      return {
        'name': 'Chrome',
        'version': _extractVersion(userAgent, 'Chrome/'),
      };
    } else if (userAgent.contains('Firefox')) {
      return {
        'name': 'Firefox',
        'version': _extractVersion(userAgent, 'Firefox/'),
      };
    } else if (userAgent.contains('Safari') && !userAgent.contains('Chrome')) {
      return {
        'name': 'Safari',
        'version': _extractVersion(userAgent, 'Version/'),
      };
    } else if (userAgent.contains('Edg')) {
      return {'name': 'Edge', 'version': _extractVersion(userAgent, 'Edg/')};
    } else if (userAgent.contains('Opera') || userAgent.contains('OPR')) {
      return {'name': 'Opera', 'version': _extractVersion(userAgent, 'OPR/')};
    }
    return {'name': 'Unknown Browser', 'version': 'Unknown'};
  }

  static String _detectOS(String userAgent) {
    if (userAgent.contains('Windows')) return 'Windows';
    if (userAgent.contains('Mac OS X') || userAgent.contains('Macintosh')) {
      return 'macOS';
    }
    if (userAgent.contains('Linux')) return 'Linux';
    if (userAgent.contains('Android')) return 'Android';
    if (userAgent.contains('iOS') ||
        userAgent.contains('iPhone') ||
        userAgent.contains('iPad')) {
      return 'iOS';
    }
    return 'Unknown';
  }

  static String _getOSVersion(String userAgent) {
    if (userAgent.contains('Windows NT 10.0')) return '10';
    if (userAgent.contains('Windows NT 6.3')) return '8.1';
    if (userAgent.contains('Windows NT 6.2')) return '8';
    if (userAgent.contains('Mac OS X')) {
      final match = RegExp(r'Mac OS X (\d+[._]\d+)').firstMatch(userAgent);
      return match?.group(1)?.replaceAll('_', '.') ?? 'Unknown';
    }
    if (userAgent.contains('Android')) {
      final match = RegExp(r'Android (\d+\.?\d*)').firstMatch(userAgent);
      return match?.group(1) ?? 'Unknown';
    }
    return 'Unknown';
  }

  static String _detectArchitecture(String userAgent) {
    if (userAgent.contains('x86_64') ||
        userAgent.contains('Win64') ||
        userAgent.contains('WOW64')) {
      return 'x86_64';
    }
    if (userAgent.contains('ARM') || userAgent.contains('arm')) {
      return 'arm64';
    }
    return 'unknown';
  }

  static List<String> _getProcessorFeatures() {
    final features = <String>['WebAssembly'];
    // WebGL and SharedArrayBuffer detection would require JS interop
    // Simplified for now
    features.add('WebGL');
    return features;
  }

  static double _getRefreshRate() {
    // Most displays are 60Hz, some high-end are 120Hz+
    // This is not directly detectable via web APIs
    return 60.0;
  }

  static double _calculateScreenSize(int width, int height, double pixelRatio) {
    // Approximate calculation
    final widthInches = width / pixelRatio / 96.0; // 96 DPI standard
    final heightInches = height / pixelRatio / 96.0;
    return (widthInches * widthInches + heightInches * heightInches) / 2.0;
  }

  static bool _checkHdrSupport() {
    // HDR support check would require matchMedia API
    // Simplified for now - package:web doesn't have direct matchMedia support yet
    return false;
  }

  static String _extractVersion(String userAgent, String prefix) {
    final index = userAgent.indexOf(prefix);
    if (index != -1) {
      final start = index + prefix.length;
      final end = userAgent.indexOf(' ', start);
      return end != -1
          ? userAgent.substring(start, end)
          : userAgent.substring(start);
    }
    return 'Unknown';
  }
}
