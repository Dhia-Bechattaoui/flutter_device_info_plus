#ifndef FLUTTER_PLUGIN_FLUTTER_DEVICE_INFO_PLUS_PLUGIN_C_API_H_
#define FLUTTER_PLUGIN_FLUTTER_DEVICE_INFO_PLUS_PLUGIN_C_API_H_

#include <flutter_plugin_registrar.h>

#ifdef FLUTTER_PLUGIN_IMPL
#define FLUTTER_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FLUTTER_PLUGIN_EXPORT __declspec(dllimport)
#endif

#if defined(__cplusplus)
extern "C" {
#endif

FLUTTER_PLUGIN_EXPORT void FlutterDeviceInfoPlusPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar);

// // Compatibility function for older generated plugin registrant
// FLUTTER_PLUGIN_EXPORT void FlutterDeviceInfoPlusPluginRegisterWithRegistrar(
//     FlutterDesktopPluginRegistrarRef registrar);

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // FLUTTER_PLUGIN_FLUTTER_DEVICE_INFO_PLUS_PLUGIN_C_API_H_

