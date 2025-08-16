import 'package:flutter/foundation.dart';

/// Information about the device's processor and CPU capabilities.
///
/// Contains details about CPU architecture, core count, frequency,
/// and available instruction set features.
@immutable
class ProcessorInfo {
  /// Creates a new [ProcessorInfo] instance.
  const ProcessorInfo({
    required this.architecture,
    required this.coreCount,
    required this.maxFrequency,
    required this.processorName,
    required this.features,
  });

  /// The processor architecture (e.g., 'arm64', 'x86_64', 'armv7l').
  final String architecture;

  /// The number of CPU cores.
  final int coreCount;

  /// The maximum frequency of the processor in MHz.
  final int maxFrequency;

  /// The name or model of the processor.
  final String processorName;

  /// List of processor features and instruction sets.
  final List<String> features;

  /// Creates a copy of this [ProcessorInfo] with the given fields replaced.
  ProcessorInfo copyWith({
    String? architecture,
    int? coreCount,
    int? maxFrequency,
    String? processorName,
    List<String>? features,
  }) =>
      ProcessorInfo(
        architecture: architecture ?? this.architecture,
        coreCount: coreCount ?? this.coreCount,
        maxFrequency: maxFrequency ?? this.maxFrequency,
        processorName: processorName ?? this.processorName,
        features: features ?? this.features,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ProcessorInfo &&
        other.architecture == architecture &&
        other.coreCount == coreCount &&
        other.maxFrequency == maxFrequency &&
        other.processorName == processorName &&
        _listEquals(other.features, features);
  }

  @override
  int get hashCode => Object.hash(
        architecture,
        coreCount,
        maxFrequency,
        processorName,
        Object.hashAll(features),
      );

  @override
  String toString() => 'ProcessorInfo('
      'architecture: $architecture, '
      'coreCount: $coreCount, '
      'maxFrequency: $maxFrequency, '
      'processorName: $processorName, '
      'features: $features'
      ')';

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
