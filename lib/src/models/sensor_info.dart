import 'package:flutter/foundation.dart';

/// Information about available sensors on the device.
///
/// Contains details about sensor types and their capabilities.
@immutable
class SensorInfo {
  /// Creates a new [SensorInfo] instance.
  const SensorInfo({
    required this.availableSensors,
  });

  /// List of available sensor types on the device.
  final List<SensorType> availableSensors;

  /// Whether the device has an accelerometer sensor.
  bool get hasAccelerometer =>
      availableSensors.contains(SensorType.accelerometer);

  /// Whether the device has a gyroscope sensor.
  bool get hasGyroscope => availableSensors.contains(SensorType.gyroscope);

  /// Whether the device has a magnetometer sensor.
  bool get hasMagnetometer =>
      availableSensors.contains(SensorType.magnetometer);

  /// Whether the device has a proximity sensor.
  bool get hasProximity => availableSensors.contains(SensorType.proximity);

  /// Whether the device has an ambient light sensor.
  bool get hasLightSensor => availableSensors.contains(SensorType.light);

  /// Whether the device has a barometer sensor.
  bool get hasBarometer => availableSensors.contains(SensorType.barometer);

  /// Whether the device has a temperature sensor.
  bool get hasTemperature => availableSensors.contains(SensorType.temperature);

  /// Whether the device has a humidity sensor.
  bool get hasHumidity => availableSensors.contains(SensorType.humidity);

  /// Whether the device has a step counter sensor.
  bool get hasStepCounter => availableSensors.contains(SensorType.stepCounter);

  /// Whether the device has a heart rate sensor.
  bool get hasHeartRate => availableSensors.contains(SensorType.heartRate);

  /// Gets the total number of available sensors.
  int get sensorCount => availableSensors.length;

  /// Creates a copy of this [SensorInfo] with the given fields replaced.
  SensorInfo copyWith({
    List<SensorType>? availableSensors,
  }) =>
      SensorInfo(
        availableSensors: availableSensors ?? this.availableSensors,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SensorInfo &&
        _listEquals(other.availableSensors, availableSensors);
  }

  @override
  int get hashCode => Object.hashAll(availableSensors);

  @override
  String toString() => 'SensorInfo(availableSensors: $availableSensors)';

  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    if (identical(a, b)) return true;
    for (var index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}

/// Enumeration of sensor types available on devices.
enum SensorType {
  /// Accelerometer sensor for measuring acceleration forces.
  accelerometer,

  /// Gyroscope sensor for measuring rotation rates.
  gyroscope,

  /// Magnetometer sensor for measuring magnetic field.
  magnetometer,

  /// Proximity sensor for detecting nearby objects.
  proximity,

  /// Ambient light sensor for measuring light levels.
  light,

  /// Barometer sensor for measuring atmospheric pressure.
  barometer,

  /// Temperature sensor for measuring ambient temperature.
  temperature,

  /// Humidity sensor for measuring relative humidity.
  humidity,

  /// Step counter sensor for counting user steps.
  stepCounter,

  /// Heart rate sensor for measuring heart rate.
  heartRate,

  /// GPS sensor for location services.
  gps,

  /// Fingerprint sensor for biometric authentication.
  fingerprint,

  /// Face recognition sensor for biometric authentication.
  faceRecognition,

  /// Gravity sensor for measuring gravity forces.
  gravity,

  /// Linear acceleration sensor (acceleration without gravity).
  linearAcceleration,

  /// Rotation vector sensor for device orientation.
  rotationVector,

  /// Pressure sensor for measuring atmospheric pressure.
  pressure,

  /// Ambient temperature sensor.
  ambientTemperature,

  /// Relative humidity sensor.
  relativeHumidity,
}
