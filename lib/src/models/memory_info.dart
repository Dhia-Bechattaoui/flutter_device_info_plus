// ignore_for_file: deprecated_member_use_from_same_package, document_ignores

import 'package:flutter/foundation.dart';

/// Information about the device's memory and storage.
///
/// Contains details about RAM, storage space, and memory usage.
@immutable
class MemoryInfo {
  /// Creates a new [MemoryInfo] instance.
  const MemoryInfo({
    required this.totalPhysicalMemory,
    required this.availablePhysicalMemory,
    required this.memoryUsagePercentage,
    @Deprecated('Use DeviceInformation.storageInfo instead')
    this.totalStorageSpace = 0,
    @Deprecated('Use DeviceInformation.storageInfo instead')
    this.availableStorageSpace = 0,
    @Deprecated('Use DeviceInformation.storageInfo instead')
    this.usedStorageSpace = 0,
  });

  /// Total physical RAM in bytes.
  final int totalPhysicalMemory;

  /// Available physical RAM in bytes.
  final int availablePhysicalMemory;

  /// Total storage space in bytes.
  @Deprecated('Use DeviceInformation.storageInfo instead')
  final int totalStorageSpace;

  /// Available storage space in bytes.
  @Deprecated('Use DeviceInformation.storageInfo instead')
  final int availableStorageSpace;

  /// Used storage space in bytes.
  @Deprecated('Use DeviceInformation.storageInfo instead')
  final int usedStorageSpace;

  /// Current memory usage as a percentage (0-100).
  final double memoryUsagePercentage;

  /// Gets total physical memory in megabytes.
  double get totalPhysicalMemoryMB => totalPhysicalMemory / (1024 * 1024);

  /// Gets available physical memory in megabytes.
  double get availablePhysicalMemoryMB =>
      availablePhysicalMemory / (1024 * 1024);

  /// Gets total storage space in gigabytes.
  @Deprecated('Use DeviceInformation.storageInfo instead')
  double get totalStorageSpaceGB => totalStorageSpace / (1024 * 1024 * 1024);

  /// Gets available storage space in gigabytes.
  @Deprecated('Use DeviceInformation.storageInfo instead')
  double get availableStorageSpaceGB =>
      availableStorageSpace / (1024 * 1024 * 1024);

  /// Gets used storage space in gigabytes.
  @Deprecated('Use DeviceInformation.storageInfo instead')
  double get usedStorageSpaceGB => usedStorageSpace / (1024 * 1024 * 1024);

  /// Gets storage usage as a percentage (0-100).
  @Deprecated('Use DeviceInformation.storageInfo instead')
  double get storageUsagePercentage =>
      totalStorageSpace > 0 ? (usedStorageSpace / totalStorageSpace) * 100 : 0;

  /// Creates a copy of this [MemoryInfo] with the given fields replaced.
  MemoryInfo copyWith({
    final int? totalPhysicalMemory,
    final int? availablePhysicalMemory,
    final int? totalStorageSpace,
    final int? availableStorageSpace,
    final int? usedStorageSpace,
    final double? memoryUsagePercentage,
  }) => MemoryInfo(
    totalPhysicalMemory: totalPhysicalMemory ?? this.totalPhysicalMemory,
    availablePhysicalMemory:
        availablePhysicalMemory ?? this.availablePhysicalMemory,
    totalStorageSpace: totalStorageSpace ?? this.totalStorageSpace,
    availableStorageSpace: availableStorageSpace ?? this.availableStorageSpace,
    usedStorageSpace: usedStorageSpace ?? this.usedStorageSpace,
    memoryUsagePercentage: memoryUsagePercentage ?? this.memoryUsagePercentage,
  );

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is MemoryInfo &&
        other.totalPhysicalMemory == totalPhysicalMemory &&
        other.availablePhysicalMemory == availablePhysicalMemory &&
        other.totalStorageSpace == totalStorageSpace &&
        other.availableStorageSpace == availableStorageSpace &&
        other.usedStorageSpace == usedStorageSpace &&
        other.memoryUsagePercentage == memoryUsagePercentage;
  }

  @override
  int get hashCode => Object.hash(
    totalPhysicalMemory,
    availablePhysicalMemory,
    totalStorageSpace,
    availableStorageSpace,
    usedStorageSpace,
    memoryUsagePercentage,
  );

  @override
  String toString() =>
      'MemoryInfo('
      'totalPhysicalMemory: $totalPhysicalMemory, '
      'availablePhysicalMemory: $availablePhysicalMemory, '
      'totalStorageSpace: $totalStorageSpace, '
      'availableStorageSpace: $availableStorageSpace, '
      'usedStorageSpace: $usedStorageSpace, '
      'memoryUsagePercentage: $memoryUsagePercentage'
      ')';
}
