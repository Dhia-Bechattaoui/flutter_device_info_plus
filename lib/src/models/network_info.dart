import 'package:flutter/foundation.dart';

/// Information about the device's network connectivity.
///
/// Contains details about network connection type, speed,
/// and interface information.
@immutable
class NetworkInfo {
  /// Creates a new [NetworkInfo] instance.
  const NetworkInfo({
    required this.connectionType,
    required this.networkSpeed,
    required this.isConnected,
    required this.ipAddress,
    required this.macAddress,
  });

  /// Type of network connection ('wifi', 'mobile', 'ethernet', 'none').
  final String connectionType;

  /// Network speed description (e.g., '100 Mbps', '4G', '5G').
  final String networkSpeed;

  /// Whether the device is currently connected to a network.
  final bool isConnected;

  /// Current IP address of the device.
  final String ipAddress;

  /// MAC address of the network interface.
  final String macAddress;

  /// Whether the device is connected via WiFi.
  bool get isWifiConnected => connectionType == 'wifi';

  /// Whether the device is connected via mobile data.
  bool get isMobileConnected => connectionType == 'mobile';

  /// Whether the device is connected via Ethernet.
  bool get isEthernetConnected => connectionType == 'ethernet';

  /// Whether the device has no network connection.
  bool get isOffline => connectionType == 'none' || !isConnected;

  /// Creates a copy of this [NetworkInfo] with the given fields replaced.
  NetworkInfo copyWith({
    final String? connectionType,
    final String? networkSpeed,
    final bool? isConnected,
    final String? ipAddress,
    final String? macAddress,
  }) => NetworkInfo(
    connectionType: connectionType ?? this.connectionType,
    networkSpeed: networkSpeed ?? this.networkSpeed,
    isConnected: isConnected ?? this.isConnected,
    ipAddress: ipAddress ?? this.ipAddress,
    macAddress: macAddress ?? this.macAddress,
  );

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is NetworkInfo &&
        other.connectionType == connectionType &&
        other.networkSpeed == networkSpeed &&
        other.isConnected == isConnected &&
        other.ipAddress == ipAddress &&
        other.macAddress == macAddress;
  }

  @override
  int get hashCode => Object.hash(
    connectionType,
    networkSpeed,
    isConnected,
    ipAddress,
    macAddress,
  );

  @override
  String toString() =>
      'NetworkInfo('
      'connectionType: $connectionType, '
      'networkSpeed: $networkSpeed, '
      'isConnected: $isConnected, '
      'ipAddress: $ipAddress, '
      'macAddress: $macAddress'
      ')';
}
