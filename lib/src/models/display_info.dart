import 'package:flutter/foundation.dart';

/// Information about the device's display and screen.
///
/// Contains details about screen resolution, pixel density, refresh rate,
/// and display capabilities.
@immutable
class DisplayInfo {
  /// Creates a new [DisplayInfo] instance.
  const DisplayInfo({
    required this.screenWidth,
    required this.screenHeight,
    required this.pixelDensity,
    required this.refreshRate,
    required this.screenSizeInches,
    required this.orientation,
    required this.isHdr,
  });

  /// Screen width in pixels.
  final int screenWidth;

  /// Screen height in pixels.
  final int screenHeight;

  /// Pixel density (DPI/160).
  final double pixelDensity;

  /// Display refresh rate in Hz.
  final double refreshRate;

  /// Screen size in inches (diagonal).
  final double screenSizeInches;

  /// Current screen orientation ('portrait' or 'landscape').
  final String orientation;

  /// Whether the display supports HDR.
  final bool isHdr;

  /// Gets the aspect ratio of the screen.
  double get aspectRatio => screenWidth / screenHeight;

  /// Gets the total number of pixels.
  int get totalPixels => screenWidth * screenHeight;

  /// Gets pixels per inch (PPI).
  double get pixelsPerInch => pixelDensity * 160;

  /// Gets screen resolution as a formatted string.
  String get resolutionString => '${screenWidth}x$screenHeight';

  /// Determines if the screen is considered high-density.
  bool get isHighDensity => pixelDensity >= 2.0;

  /// Determines if the screen is considered high refresh rate.
  bool get isHighRefreshRate => refreshRate >= 90.0;

  /// Creates a copy of this [DisplayInfo] with the given fields replaced.
  DisplayInfo copyWith({
    final int? screenWidth,
    final int? screenHeight,
    final double? pixelDensity,
    final double? refreshRate,
    final double? screenSizeInches,
    final String? orientation,
    final bool? isHdr,
  }) => DisplayInfo(
    screenWidth: screenWidth ?? this.screenWidth,
    screenHeight: screenHeight ?? this.screenHeight,
    pixelDensity: pixelDensity ?? this.pixelDensity,
    refreshRate: refreshRate ?? this.refreshRate,
    screenSizeInches: screenSizeInches ?? this.screenSizeInches,
    orientation: orientation ?? this.orientation,
    isHdr: isHdr ?? this.isHdr,
  );

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is DisplayInfo &&
        other.screenWidth == screenWidth &&
        other.screenHeight == screenHeight &&
        other.pixelDensity == pixelDensity &&
        other.refreshRate == refreshRate &&
        other.screenSizeInches == screenSizeInches &&
        other.orientation == orientation &&
        other.isHdr == isHdr;
  }

  @override
  int get hashCode => Object.hash(
    screenWidth,
    screenHeight,
    pixelDensity,
    refreshRate,
    screenSizeInches,
    orientation,
    isHdr,
  );

  @override
  String toString() =>
      'DisplayInfo('
      'screenWidth: $screenWidth, '
      'screenHeight: $screenHeight, '
      'pixelDensity: $pixelDensity, '
      'refreshRate: $refreshRate, '
      'screenSizeInches: $screenSizeInches, '
      'orientation: $orientation, '
      'isHdr: $isHdr'
      ')';
}
