/// Web platform implementation for flutter_device_info_plus
///
/// This library provides device information retrieval capabilities
/// for web platforms using browser APIs and user agent parsing.
library;

import 'dart:async';
import 'dart:js_interop';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:web/web.dart' as web;

import 'src/models/models.dart';
import 'src/platform_interface.dart';

/// Web implementation of FlutterDeviceInfoPlus.
class FlutterDeviceInfoPlusPlugin extends FlutterDeviceInfoPlusPlatform {
  /// Registar the plugin with the Flutter engine
  static void registerWith(final Registrar registrar) {
    FlutterDeviceInfoPlusPlatform.instance = FlutterDeviceInfoPlusPlugin();
  }

  @override
  Future<DeviceInformation> getDeviceInfo() async {
    final window = web.window;
    final screen = window.screen;
    final navigator = window.navigator;

    // Get user agent info
    final userAgent = navigator.userAgent;

    // Get screen info
    final screenWidth = screen.width;
    final screenHeight = screen.height;
    final pixelRatio = window.devicePixelRatio;

    // Get hardware concurrency (CPU cores)
    final hardwareConcurrency = navigator.hardwareConcurrency;

    // Detect browser
    final browserInfo = _detectBrowser(userAgent);
    final deviceInfo = _detectDevice(userAgent);

    final sensorInfo = await getSensorInfo();
    final networkInfo = await getNetworkInfo();
    final batteryInfo = await getBatteryInfo();

    return DeviceInformation(
      deviceName: browserInfo['name'] ?? 'Web Browser',
      manufacturer: deviceInfo['manufacturer'] ?? 'Unknown',
      model: deviceInfo['model'] ?? browserInfo['name'] ?? 'Web Browser',
      brand: deviceInfo['brand'] ?? browserInfo['name'] ?? 'Web',
      operatingSystem: _detectOS(userAgent),
      systemVersion: await _getOSVersionAsync(userAgent),
      buildNumber: await _getBrowserFullVersionAsync(userAgent),
      kernelVersion: _getKernelVersion(userAgent),
      processorInfo: await _getProcessorInfoAsync(
        userAgent,
        hardwareConcurrency,
      ),
      memoryInfo: await _getMemoryInfoAsync(),
      displayInfo: DisplayInfo(
        screenWidth: screenWidth,
        screenHeight: screenHeight,
        pixelDensity: pixelRatio,
        refreshRate: _getRefreshRate(),
        screenSizeInches: _calculateScreenSize(
          screenWidth,
          screenHeight,
          pixelRatio,
        ),
        orientation: screenWidth > screenHeight ? 'landscape' : 'portrait',
        isHdr: _checkHdrSupport(),
      ),
      batteryInfo: batteryInfo,
      sensorInfo: sensorInfo,
      networkInfo: networkInfo,
      securityInfo: SecurityInfo(
        isDeviceSecure: false,
        hasFingerprint: false,
        hasFaceUnlock: false,
        screenLockEnabled: false,
        encryptionStatus: window.location.protocol == 'https:'
            ? 'encrypted'
            : 'unencrypted',
      ),
    );
  }

  Future<ProcessorInfo> _getProcessorInfoAsync(
    final String userAgent,
    final int cores,
  ) async {
    var architecture = _detectArchitecture(userAgent);
    var processorName = 'JavaScript Engine';
    var bitness = '';

    // Try Client Hints for advanced details
    final navigator = web.window.navigator;
    final uaData = (navigator as NavigatorWithUAData).userAgentData;
    if (uaData != null) {
      try {
        final hints = ['architecture'.toJS, 'bitness'.toJS, 'model'.toJS].toJS;
        final valuesPromise = uaData.getHighEntropyValues(hints);
        final values = await valuesPromise.toDart;

        if (values.architecture != null) {
          architecture = values.architecture!;
        }
        if (values.bitness != null) {
          bitness = values.bitness!;
        }
        if (values.model != null && values.model!.isNotEmpty) {
          processorName = values.model!;
        }
      } on Object catch (_) {}
    }

    if (bitness.isNotEmpty) {
      architecture = '$architecture ($bitness-bit)';
    }

    return ProcessorInfo(
      architecture: architecture,
      coreCount: cores,
      maxFrequency: 0,
      processorName: processorName,
      features: _getProcessorFeatures(),
    );
  }

  Future<String> _getBrowserFullVersionAsync(final String userAgent) async {
    final navigator = web.window.navigator;
    final uaData = (navigator as NavigatorWithUAData).userAgentData;

    if (uaData != null) {
      try {
        final hints = ['fullVersionList'.toJS].toJS;
        final values = await uaData.getHighEntropyValues(hints).toDart;
        final fullVersionList = values.fullVersionList;
        if (fullVersionList != null) {
          final list = fullVersionList.toDart;
          // Prefer 'Google Chrome', 'Microsoft Edge',
          // or just matching current browser
          for (final brandVersion in list) {
            final brand = brandVersion.brand;
            final version = brandVersion.version;
            // Common brands
            if (brand.contains('Chrome') ||
                brand.contains('Edge') ||
                brand.contains('Opera')) {
              return version;
            }
          }
          // Fallback to first
          if (list.isNotEmpty) {
            return list.first.version;
          }
        }
      } on Object catch (_) {
        // Fallback
      }
    }
    return _getBuildNumber(userAgent);
  }

  Future<MemoryInfo> _getMemoryInfoAsync() async {
    // RAM
    final navigator = web.window.navigator;
    final deviceMemory = (navigator as NavigatorWithMemory).deviceMemory;
    var totalRamMB = 0.0;
    if (deviceMemory != null) {
      // deviceMemory is in GB, convert to Bytes
      totalRamMB = deviceMemory * 1024 * 1024 * 1024;
    }

    // Storage
    var totalStorageGB = 0.0;
    var availableStorageGB = 0.0;

    try {
      final storageManager = (navigator as NavigatorWithStorage).storage;
      final estimate = await storageManager.estimate().toDart;
      final quota = estimate.quota;
      final usage = estimate.usage;

      if (quota != null) {
        totalStorageGB = quota.toDouble();
        if (usage != null) {
          availableStorageGB = (quota - usage).toDouble();
        } else {
          availableStorageGB = totalStorageGB;
        }
      }
    } on Object catch (_) {
      // StorageManager not supported or error
    }

    return MemoryInfo(
      totalPhysicalMemory: totalRamMB.toInt(),
      availablePhysicalMemory: 0,
      totalStorageSpace: totalStorageGB.toInt(),
      availableStorageSpace: availableStorageGB.toInt(),
      usedStorageSpace: (totalStorageGB - availableStorageGB).toInt(),
      memoryUsagePercentage: 0,
    );
  }

  @override
  Future<BatteryInfo?> getBatteryInfo() async {
    try {
      final navigator = web.window.navigator;
      final batteryPromise = (navigator as NavigatorWithBattery).getBattery();
      final battery = await batteryPromise.toDart;

      return BatteryInfo(
        batteryLevel: (battery.level * 100).toInt(),
        batteryHealth: 'good',
        chargingStatus: battery.charging ? 'charging' : 'discharging',
        batteryCapacity: 0,
        batteryVoltage: 0,
        batteryTemperature: 0,
      );
    } on Object catch (_) {
      return null;
    }
  }

  @override
  Future<SensorInfo> getSensorInfo() async {
    final sensors = <SensorType>[
      SensorType.accelerometer,
      SensorType.gyroscope,
    ];
    return SensorInfo(availableSensors: sensors);
  }

  @override
  Future<NetworkInfo> getNetworkInfo() async {
    final navigator = web.window.navigator;
    var connectionType = 'unknown';
    var networkSpeed = 'Unknown';

    // Try to access NetworkInformation API
    final connection = (navigator as NavigatorWithConnection).connection;
    if (connection != null) {
      // Try to get specific type (chrome/edge specific) primarily for ethernet
      final specificType = connection.type;
      if (specificType != null && specificType != 'unknown') {
        connectionType = specificType;
      } else {
        // Fallback to effectiveType if specific type is not available
        final type = connection.effectiveType;
        if (type != null) {
          // effectiveType returns 'slow-2g', '2g', '3g', or '4g'
          // This describes speed/quality, not strictly the interface,
          // but it's the best we have if .type is missing.
          connectionType = type;
        }
      }

      // Get downlink speed
      final downlink = connection.downlink;
      if (downlink != null) {
        networkSpeed = '$downlink Mbps';
      }
    }

    // Basic online/offline check as fallback or supplement
    final isConnected = navigator.onLine;
    if (isConnected && connectionType == 'unknown') {
      connectionType = 'wifi'; // Fallback assumption
    }

    return NetworkInfo(
      connectionType: connectionType,
      networkSpeed: networkSpeed,
      isConnected: isConnected,
      ipAddress: await _getLocalIpAddress(),
      // MAC address is strictly blocked by browsers for security
      // (to prevent tracking). It is impossible to retrieve via JS.
      macAddress: 'Not Available',
    );
  }

  Future<String> _getLocalIpAddress() async {
    try {
      final pc = RTCPeerConnection()..createDataChannel('');

      final completer = Completer<String>();

      pc.onicecandidate = ((final JSObject event) {
        final iceEvent = event as RTCPeerConnectionIceEvent;
        final candidate = iceEvent.candidate;
        if (candidate != null) {
          final candidateString = candidate.candidate;
          if (candidateString != null) {
            // Extract IP (IPv4) - look for x.x.x.x
            final parts = candidateString.split(' ');
            for (final part in parts) {
              if (part.contains('.') && part.split('.').length == 4) {
                // Simple verification it is likely an IP
                if (part
                    .split('.')
                    .every((final p) => int.tryParse(p) != null)) {
                  if (!completer.isCompleted) {
                    completer.complete(part);
                  }
                  pc.onicecandidate = null;
                  break;
                }
              }
            }
          }
        }
      }).toJS;

      final offer = await pc.createOffer().toDart;
      await pc.setLocalDescription(offer).toDart;

      // Wait for 500ms max
      return await completer.future.timeout(const Duration(milliseconds: 500));
    } on Object catch (_) {
      return 'unknown';
    }
  }

  Map<String, String> _detectBrowser(final String userAgent) {
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

  String _detectOS(final String userAgent) {
    if (userAgent.contains('Windows')) {
      return 'Windows';
    }
    if (userAgent.contains('Mac OS X') || userAgent.contains('Macintosh')) {
      return 'macOS';
    }
    if (userAgent.contains('Linux')) {
      return 'Linux';
    }
    if (userAgent.contains('Android')) {
      return 'Android';
    }
    if (userAgent.contains('iOS') ||
        userAgent.contains('iPhone') ||
        userAgent.contains('iPad')) {
      return 'iOS';
    }
    return 'Unknown';
  }

  Map<String, String> _detectDevice(final String userAgent) {
    if (userAgent.contains('Android')) {
      // Regex to capture the model name between "; " and " Build/"
      // Example: Linux; Android 10; SM-G980F Build/
      var model = 'Android Device';
      final buildIndex = userAgent.indexOf(' Build/');
      if (buildIndex != -1) {
        final substringBeforeBuild = userAgent.substring(0, buildIndex);
        final lastSemicolon = substringBeforeBuild.lastIndexOf(';');
        if (lastSemicolon != -1) {
          model = substringBeforeBuild.substring(lastSemicolon + 1).trim();
        }
      }

      if (model != 'Android Device') {
        var manufacturer = 'Unknown';
        if (model.startsWith('SM-') || model.startsWith('GT-')) {
          manufacturer = 'Samsung';
        }
        if (model.startsWith('Pixel')) {
          manufacturer = 'Google';
        }
        if (model.startsWith('Redmi') || model.startsWith('Mi')) {
          manufacturer = 'Xiaomi';
        }

        return {
          'manufacturer': manufacturer,
          'model': model,
          'brand': 'Android',
        };
      }
      return {
        'manufacturer': 'Unknown',
        'model': 'Android Device',
        'brand': 'Android',
      };
    }

    if (userAgent.contains('iPad')) {
      return {'manufacturer': 'Apple', 'model': 'iPad', 'brand': 'Apple'};
    }
    if (userAgent.contains('iPhone')) {
      return {'manufacturer': 'Apple', 'model': 'iPhone', 'brand': 'Apple'};
    }
    if (userAgent.contains('Macintosh') || userAgent.contains('Mac OS X')) {
      return {'manufacturer': 'Apple', 'model': 'Mac', 'brand': 'Apple'};
    }
    if (userAgent.contains('Windows')) {
      return {
        'manufacturer': 'Microsoft',
        'model': 'Windows PC',
        'brand': 'Windows',
      };
    }

    return {};
  }

  Future<String> _getOSVersionAsync(final String userAgent) async {
    // Try Client Hints first for accurate Windows 11 detection
    final navigator = web.window.navigator;
    final uaData = (navigator as NavigatorWithUAData).userAgentData;

    if (uaData != null) {
      try {
        // Request platformVersion hint using standard conversion
        final hints = ['platformVersion'.toJS].toJS;
        final valuesPromise = uaData.getHighEntropyValues(hints);
        final values = await valuesPromise.toDart;
        final platformVersion = values.platformVersion;

        if (platformVersion != null) {
          // Windows 11 is platformVersion >= 13.0.0
          if (userAgent.contains('Windows')) {
            final versionParts = platformVersion.split('.');
            if (versionParts.isNotEmpty) {
              final major = int.tryParse(versionParts[0]);
              if (major != null && major >= 13) {
                return '11';
              }
            }
          }
        }
      } on Object catch (_) {
        // Fallback if permission denied or error
      }
    }

    // Fallback to User Agent string parsing
    return _getOSVersion(userAgent);
  }

  String _getOSVersion(final String userAgent) {
    if (userAgent.contains('Windows NT 10.0')) {
      return '10';
    }
    if (userAgent.contains('Windows NT 6.3')) {
      return '8.1';
    }
    if (userAgent.contains('Windows NT 6.2')) {
      return '8';
    }
    if (userAgent.contains('Mac OS X')) {
      const key = 'Mac OS X ';
      final index = userAgent.indexOf(key);
      if (index != -1) {
        var version = userAgent.substring(index + key.length);
        version = version.split(')')[0].split(';')[0];
        // Clean up any trailing info if spaces exist, e.g. "10_15_7 "
        // But usually it's "Mac OS X 10_15_7)" or similar
        // Just replacing _ with . and taking the first part
        version = version.replaceAll('_', '.').trim();
        return version;
      }
      return 'Unknown';
    }
    if (userAgent.contains('Android')) {
      const key = 'Android ';
      final index = userAgent.indexOf(key);
      if (index != -1) {
        return userAgent
            .substring(index + key.length)
            .split(';')[0]
            .split(')')[0]
            .trim();
      }
      return 'Unknown';
    }
    return 'Unknown';
  }

  String _getBuildNumber(final String userAgent) {
    // Returns the browser build version, e.g., 120.0.6099.109
    if (userAgent.contains('Chrome/')) {
      return _extractVersion(userAgent, 'Chrome/');
    }
    if (userAgent.contains('Firefox/')) {
      return _extractVersion(userAgent, 'Firefox/');
    }
    if (userAgent.contains('Version/')) {
      return _extractVersion(userAgent, 'Version/');
    }
    return 'Unknown';
  }

  String _getKernelVersion(final String userAgent) {
    // Returns the engine version, e.g., AppleWebKit/537.36
    if (userAgent.contains('AppleWebKit/')) {
      return 'AppleWebKit/${_extractVersion(userAgent, 'AppleWebKit/')}';
    }
    if (userAgent.contains('Gecko/')) {
      return 'Gecko/${_extractVersion(userAgent, 'Gecko/')}';
    }
    return 'Web Engine';
  }

  String _detectArchitecture(final String userAgent) {
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

  List<String> _getProcessorFeatures() => ['WebAssembly', 'WebGL'];

  double _getRefreshRate() => 60;

  double _calculateScreenSize(
    final int width,
    final int height,
    final double pixelRatio,
  ) {
    final widthInches = width / pixelRatio / 96.0;
    final heightInches = height / pixelRatio / 96.0;
    return (widthInches * widthInches + heightInches * heightInches) / 2.0;
  }

  bool _checkHdrSupport() => false;

  String _extractVersion(final String userAgent, final String prefix) {
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

extension type NavigatorWithConnection(web.Navigator navigator)
    implements web.Navigator {
  external JSNetworkInformation? get connection;
}

extension type NavigatorWithUAData(web.Navigator navigator)
    implements web.Navigator {
  external UAData? get userAgentData;
}

extension type UAData(JSObject _) implements JSObject {
  external JSPromise<UADataValues> getHighEntropyValues(final JSObject hints);
}

extension type UADataValues(JSObject _) implements JSObject {
  external String? get platformVersion;
  external String? get architecture;
  external String? get bitness;
  external String? get model;
  external JSArray<UABrandVersion>? get fullVersionList;
}

extension type UABrandVersion(JSObject _) implements JSObject {
  external String get brand;
  external String get version;
}

/// JS interop for the NetworkInformation object.
extension type JSNetworkInformation(JSObject _) implements JSObject {
  /// The effective type of the connection meaning one of 'slow-2g', '2g', '3g', or '4g'.
  external String? get effectiveType;

  /// The estimated effective round-trip time of the current connection, rounded to the nearest multiple of 25 milliseconds.
  external double? get downlink;

  /// The type of connection a device is using to communicate with the network.
  external String? get type;
}

extension type NavigatorWithMemory(web.Navigator navigator)
    implements web.Navigator {
  external double? get deviceMemory;
}

extension type NavigatorWithStorage(web.Navigator navigator)
    implements web.Navigator {
  external StorageManager get storage;
}

extension type StorageManager(JSObject _) implements JSObject {
  external JSPromise<StorageEstimate> estimate();
}

extension type StorageEstimate(JSObject _) implements JSObject {
  external int? get quota;
  external int? get usage;
}

extension type NavigatorWithBattery(web.Navigator navigator)
    implements web.Navigator {
  /// Returns a [JSPromise] that resolves with a [BatteryManager] object.
  ///
  /// See: [Battery Status API](https://developer.mozilla.org/en-US/docs/Web/API/Battery_Status_API)
  external JSPromise<BatteryManager> getBattery();
}

/// JS interop for the BatteryManager object from the Battery Status API.
extension type BatteryManager(JSObject _) implements JSObject {
  /// Whether the battery is currently being charged.
  external bool get charging;

  /// The current battery level as a value between 0.0 and 1.0.
  external double get level;

  /// The time remaining until the battery is fully charged, in seconds.
  external double get chargingTime;

  /// The time remaining until the battery is fully discharged, in seconds.
  external double get dischargingTime;
}

// WebRTC Extensions
extension type RTCPeerConnection._(JSObject _) implements JSObject {
  external factory RTCPeerConnection([final JSAny? configuration]);
  external JSPromise<RTCSessionDescription> createOffer([final JSAny? options]);
  external JSPromise<JSAny?> setLocalDescription(
    final RTCSessionDescription description,
  );
  external JSObject createDataChannel(final String label);
  external JSFunction? get onicecandidate;
  external set onicecandidate(final JSFunction? callback);
}

extension type RTCSessionDescription(JSObject _) implements JSObject {}

extension type RTCIceCandidate(JSObject _) implements JSObject {
  external String? get candidate;
}

extension type RTCPeerConnectionIceEvent(JSObject _) implements JSObject {
  external RTCIceCandidate? get candidate;
}
