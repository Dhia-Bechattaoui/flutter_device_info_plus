#include "include/flutter_device_info_plus/flutter_device_info_plus_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "flutter_device_info_plus_plugin.h"

void FlutterDeviceInfoPlusPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
      flutter_device_info_plus::FlutterDeviceInfoPlusPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}

// Compatibility function for older generated plugin registrant
// void FlutterDeviceInfoPlusPluginRegisterWithRegistrar(
//     FlutterDesktopPluginRegistrarRef registrar) {
//   FlutterDeviceInfoPlusPluginCApiRegisterWithRegistrar(registrar);
// }

