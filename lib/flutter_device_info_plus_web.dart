/// Web entrypoint for flutter_device_info_plus.
///
/// This library provides the web implementation registration.
library;

import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'src/flutter_device_info_plus_web_stub.dart'
    if (dart.library.js_interop) 'src/flutter_device_info_plus_web_impl.dart';

/// Web implementation of FlutterDeviceInfoPlus.
class FlutterDeviceInfoPlusPlugin {
  FlutterDeviceInfoPlusPlugin._();

  /// Register the plugin with the Flutter engine
  static void registerWith(final Registrar registrar) {
    registerPlugin(registrar);
  }
}
