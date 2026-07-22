import 'package:flutter/foundation.dart';

import 'storage_volume.dart';

/// Information about the device's storage.
///
/// Contains details about all storage volumes available on the device.
@immutable
class StorageInfo {
  /// Creates a new [StorageInfo] instance.
  const StorageInfo({required this.volumes});

  /// The list of storage volumes available on the device.
  final List<StorageVolume> volumes;

  /// Gets the total storage space across all volumes in bytes.
  int get totalStorageSpace =>
      volumes.fold(0, (final sum, final volume) => sum + volume.totalCapacity);

  /// Gets the available storage space across all volumes in bytes.
  int get availableStorageSpace => volumes.fold(
    0,
    (final sum, final volume) => sum + volume.availableCapacity,
  );

  /// Gets the used storage space across all volumes in bytes.
  int get usedStorageSpace =>
      volumes.fold(0, (final sum, final volume) => sum + volume.usedCapacity);

  /// Gets total storage space in gigabytes.
  double get totalStorageSpaceGB => totalStorageSpace / (1024 * 1024 * 1024);

  /// Gets available storage space in gigabytes.
  double get availableStorageSpaceGB =>
      availableStorageSpace / (1024 * 1024 * 1024);

  /// Gets used storage space in gigabytes.
  double get usedStorageSpaceGB => usedStorageSpace / (1024 * 1024 * 1024);

  /// Gets storage usage as a percentage (0-100).
  double get storageUsagePercentage =>
      totalStorageSpace > 0 ? (usedStorageSpace / totalStorageSpace) * 100 : 0;

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! StorageInfo) {
      return false;
    }

    if (volumes.length != other.volumes.length) {
      return false;
    }

    for (var i = 0; i < volumes.length; i++) {
      if (volumes[i] != other.volumes[i]) {
        return false;
      }
    }

    return true;
  }

  @override
  int get hashCode => Object.hashAll(volumes);

  @override
  String toString() => 'StorageInfo(volumes: $volumes)';
}
