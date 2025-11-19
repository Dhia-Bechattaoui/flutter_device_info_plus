#ifndef FLUTTER_PLUGIN_FLUTTER_DEVICE_INFO_PLUS_PLUGIN_H_
#define FLUTTER_PLUGIN_FLUTTER_DEVICE_INFO_PLUS_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace flutter {

class FlutterDeviceInfoPlusPlugin : public Plugin {
 public:
  static void RegisterWithRegistrar(PluginRegistrarWindows *registrar);

  FlutterDeviceInfoPlusPlugin();

  virtual ~FlutterDeviceInfoPlusPlugin();

  // Disallow copy and assign.
  FlutterDeviceInfoPlusPlugin(const FlutterDeviceInfoPlusPlugin&) = delete;
  FlutterDeviceInfoPlusPlugin& operator=(const FlutterDeviceInfoPlusPlugin&) = delete;

 private:
  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const MethodCall<EncodableValue> &method_call,
      std::unique_ptr<MethodResult<EncodableValue>> result);
};

}  // namespace flutter

#endif  // FLUTTER_PLUGIN_FLUTTER_DEVICE_INFO_PLUS_PLUGIN_H_

