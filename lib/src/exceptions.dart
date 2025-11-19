/// Base exception class for device information errors.
///
/// All exceptions thrown by the flutter_device_info_plus package
/// extend from this class.
abstract class DeviceInfoBaseException implements Exception {
  /// Creates a new base device info exception.
  const DeviceInfoBaseException(this.message);

  /// The error message describing what went wrong.
  final String message;

  @override
  String toString() => 'DeviceInfoBaseException: $message';
}

/// Exception thrown when device information cannot be retrieved.
///
/// This is the most common exception and typically indicates
/// that the device or platform doesn't support a particular
/// information request.
class DeviceInfoException extends DeviceInfoBaseException {
  /// Creates a new device info exception.
  const DeviceInfoException(super.message);

  @override
  String toString() => 'DeviceInfoException: $message';
}

/// Exception thrown when a platform-specific operation fails.
///
/// This exception is typically thrown when there's an error
/// in the native platform code or when accessing platform-specific
/// APIs.
class PlatformException extends DeviceInfoBaseException {
  /// Creates a new platform exception.
  const PlatformException(super.message, {this.code});

  /// Platform-specific error code, if available.
  final String? code;

  @override
  String toString() {
    final codeString = code != null ? ' (code: $code)' : '';
    return 'PlatformException: $message$codeString';
  }
}

/// Exception thrown when a requested feature is not supported.
///
/// This exception indicates that the current platform or device
/// doesn't support the requested functionality.
class UnsupportedFeatureException extends DeviceInfoBaseException {
  /// Creates a new unsupported feature exception.
  const UnsupportedFeatureException(super.message, {this.feature});

  /// The name of the unsupported feature.
  final String? feature;

  @override
  String toString() {
    final featureString = feature != null ? ' (feature: $feature)' : '';
    return 'UnsupportedFeatureException: $message$featureString';
  }
}

/// Exception thrown when device permissions are required but not granted.
///
/// This exception indicates that the app needs additional permissions
/// to access certain device information.
class PermissionException extends DeviceInfoBaseException {
  /// Creates a new permission exception.
  const PermissionException(super.message, {this.permission});

  /// The name of the required permission.
  final String? permission;

  @override
  String toString() {
    final permissionString = permission != null
        ? ' (permission: $permission)'
        : '';
    return 'PermissionException: $message$permissionString';
  }
}

/// Exception thrown when device information parsing fails.
///
/// This exception is typically thrown when the raw device data
/// cannot be properly parsed or converted to the expected format.
class ParseException extends DeviceInfoBaseException {
  /// Creates a new parse exception.
  const ParseException(super.message, {this.rawData});

  /// The raw data that failed to parse, if available.
  final dynamic rawData;

  @override
  String toString() {
    final dataString = rawData != null ? ' (raw data: $rawData)' : '';
    return 'ParseException: $message$dataString';
  }
}
