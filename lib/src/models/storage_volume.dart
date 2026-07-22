import 'package:flutter/foundation.dart';

/// Information about a single storage volume or partition.
@immutable
class StorageVolume {
  /// Creates a new [StorageVolume] instance.
  const StorageVolume({
    required this.totalCapacity,
    required this.availableCapacity,
    required this.usedCapacity,
    required this.isRemovable,
    this.name,
    this.mountPath,
    this.deviceType,
  });

  /// The name of the volume (e.g., "Internal Storage", "C:\").
  final String? name;

  /// The path where the volume is mounted (e.g., "/data", "C:\").
  final String? mountPath;

  /// Total capacity of the volume in bytes.
  final int totalCapacity;

  /// Available capacity of the volume in bytes.
  final int availableCapacity;

  /// Used capacity of the volume in bytes.
  final int usedCapacity;

  /// The type of the device (e.g., "Removable", "Fixed", "Optical").
  final String? deviceType;

  /// Whether the volume is removable (e.g., an SD card or USB drive).
  final bool isRemovable;

  /// Gets total capacity in gigabytes.
  double get totalCapacityGB => totalCapacity / (1024 * 1024 * 1024);

  /// Gets available capacity in gigabytes.
  double get availableCapacityGB => availableCapacity / (1024 * 1024 * 1024);

  /// Gets used capacity in gigabytes.
  double get usedCapacityGB => usedCapacity / (1024 * 1024 * 1024);

  /// Gets usage as a percentage (0-100).
  double get usagePercentage =>
      totalCapacity > 0 ? (usedCapacity / totalCapacity) * 100 : 0;

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is StorageVolume &&
        other.name == name &&
        other.mountPath == mountPath &&
        other.totalCapacity == totalCapacity &&
        other.availableCapacity == availableCapacity &&
        other.usedCapacity == usedCapacity &&
        other.deviceType == deviceType &&
        other.isRemovable == isRemovable;
  }

  @override
  int get hashCode => Object.hash(
    name,
    mountPath,
    totalCapacity,
    availableCapacity,
    usedCapacity,
    deviceType,
    isRemovable,
  );

  @override
  String toString() =>
      'StorageVolume('
      'name: $name, '
      'mountPath: $mountPath, '
      'totalCapacity: $totalCapacity, '
      'availableCapacity: $availableCapacity, '
      'usedCapacity: $usedCapacity, '
      'deviceType: $deviceType, '
      'isRemovable: $isRemovable'
      ')';
}
