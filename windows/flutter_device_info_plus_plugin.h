#ifndef FLUTTER_PLUGIN_FLUTTER_DEVICE_INFO_PLUS_PLUGIN_H_
#define FLUTTER_PLUGIN_FLUTTER_DEVICE_INFO_PLUS_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <string>
#include <vector>

namespace flutter_device_info_plus {

class FlutterDeviceInfoPlusPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  FlutterDeviceInfoPlusPlugin();

  virtual ~FlutterDeviceInfoPlusPlugin();

  // Disallow copy and assign.
  FlutterDeviceInfoPlusPlugin(const FlutterDeviceInfoPlusPlugin&) = delete;
  FlutterDeviceInfoPlusPlugin& operator=(const FlutterDeviceInfoPlusPlugin&) = delete;

 private:
  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // Device information methods
  flutter::EncodableMap GetDeviceInfo();
  flutter::EncodableMap GetBatteryInfo();
  flutter::EncodableMap GetSensorInfo();
  flutter::EncodableMap GetNetworkInfo();

  // Processor information methods
  std::string GetProcessorArchitecture();
  int GetProcessorCoreCount();
  int GetProcessorMaxFrequency();
  std::string GetProcessorName();
  std::vector<std::string> GetProcessorFeatures();

  // Memory and storage methods
  int64_t GetTotalPhysicalMemory();
  int64_t GetAvailablePhysicalMemory();
  int64_t GetTotalStorageSpace();
  int64_t GetAvailableStorageSpace();

  // Display information methods
  int GetScreenWidth();
  int GetScreenHeight();
  double GetPixelDensity();
  double GetRefreshRate();

  // Network information methods
  std::string GetIPAddress();
  std::string GetMACAddress();
};

}  // namespace flutter_device_info_plus

#endif  // FLUTTER_PLUGIN_FLUTTER_DEVICE_INFO_PLUS_PLUGIN_H_
