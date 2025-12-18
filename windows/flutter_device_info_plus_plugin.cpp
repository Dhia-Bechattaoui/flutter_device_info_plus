#include "flutter_device_info_plus_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <winternl.h>
#include <iphlpapi.h>
#include <pdh.h>
#include <psapi.h>
#include <intrin.h>
#include <sstream>
#include <memory>
#include <vector>
#include <map>

namespace flutter_device_info_plus {

void FlutterDeviceInfoPlusPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "flutter_device_info_plus",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<FlutterDeviceInfoPlusPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

FlutterDeviceInfoPlusPlugin::FlutterDeviceInfoPlusPlugin() {}

FlutterDeviceInfoPlusPlugin::~FlutterDeviceInfoPlusPlugin() {}

void FlutterDeviceInfoPlusPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare("getDeviceInfo") == 0) {
    result->Success(GetDeviceInfo());
  } else if (method_call.method_name().compare("getBatteryInfo") == 0) {
    result->Success(GetBatteryInfo());
  } else if (method_call.method_name().compare("getSensorInfo") == 0) {
    result->Success(GetSensorInfo());
  } else if (method_call.method_name().compare("getNetworkInfo") == 0) {
    result->Success(GetNetworkInfo());
  } else {
    result->NotImplemented();
  }
}

flutter::EncodableMap FlutterDeviceInfoPlusPlugin::GetDeviceInfo() {
  flutter::EncodableMap deviceInfo;
  
  // Basic device info
  char computerName[MAX_COMPUTERNAME_LENGTH + 1];
  DWORD size = sizeof(computerName);
  GetComputerNameA(computerName, &size);
  deviceInfo[flutter::EncodableValue("deviceName")] = flutter::EncodableValue(std::string(computerName));
  
  // Use RtlGetVersion instead of deprecated GetVersionEx
  typedef NTSTATUS (WINAPI *RtlGetVersionPtr)(PRTL_OSVERSIONINFOEXW);
  HMODULE hMod = GetModuleHandleW(L"ntdll.dll");
  if (hMod) {
    RtlGetVersionPtr fxPtr = (RtlGetVersionPtr)GetProcAddress(hMod, "RtlGetVersion");
    if (fxPtr != nullptr) {
      RTL_OSVERSIONINFOEXW osvi = {0};
      osvi.dwOSVersionInfoSize = sizeof(osvi);
      if (fxPtr(&osvi) == 0) {
        std::string version = std::to_string(osvi.dwMajorVersion) + "." + 
                              std::to_string(osvi.dwMinorVersion);
        deviceInfo[flutter::EncodableValue("systemVersion")] = flutter::EncodableValue(version);
        deviceInfo[flutter::EncodableValue("buildNumber")] = flutter::EncodableValue(std::to_string(osvi.dwBuildNumber));
      } else {
        deviceInfo[flutter::EncodableValue("systemVersion")] = flutter::EncodableValue("10.0");
        deviceInfo[flutter::EncodableValue("buildNumber")] = flutter::EncodableValue("0");
      }
    } else {
      deviceInfo[flutter::EncodableValue("systemVersion")] = flutter::EncodableValue("10.0");
      deviceInfo[flutter::EncodableValue("buildNumber")] = flutter::EncodableValue("0");
    }
  } else {
    deviceInfo[flutter::EncodableValue("systemVersion")] = flutter::EncodableValue("10.0");
    deviceInfo[flutter::EncodableValue("buildNumber")] = flutter::EncodableValue("0");
  }
  
  deviceInfo[flutter::EncodableValue("manufacturer")] = flutter::EncodableValue("Microsoft");
  deviceInfo[flutter::EncodableValue("model")] = flutter::EncodableValue("Windows PC");
  deviceInfo[flutter::EncodableValue("brand")] = flutter::EncodableValue("Microsoft");
  deviceInfo[flutter::EncodableValue("operatingSystem")] = flutter::EncodableValue("Windows");
  deviceInfo[flutter::EncodableValue("kernelVersion")] = flutter::EncodableValue("NT");
  
  // Processor info
  flutter::EncodableMap processorInfo;
  processorInfo[flutter::EncodableValue("architecture")] = flutter::EncodableValue(GetProcessorArchitecture());
  processorInfo[flutter::EncodableValue("coreCount")] = flutter::EncodableValue(GetProcessorCoreCount());
  processorInfo[flutter::EncodableValue("maxFrequency")] = flutter::EncodableValue(GetProcessorMaxFrequency());
  processorInfo[flutter::EncodableValue("processorName")] = flutter::EncodableValue(GetProcessorName());
  
  flutter::EncodableList features;
  for (const auto& feature : GetProcessorFeatures()) {
    features.push_back(flutter::EncodableValue(feature));
  }
  processorInfo[flutter::EncodableValue("features")] = flutter::EncodableValue(features);
  deviceInfo[flutter::EncodableValue("processorInfo")] = flutter::EncodableValue(processorInfo);
  
  // Memory info
  flutter::EncodableMap memoryInfo;
  int64_t totalMem = GetTotalPhysicalMemory();
  int64_t availMem = GetAvailablePhysicalMemory();
  int64_t totalStorage = GetTotalStorageSpace();
  int64_t availStorage = GetAvailableStorageSpace();
  
  memoryInfo[flutter::EncodableValue("totalPhysicalMemory")] = flutter::EncodableValue(totalMem);
  memoryInfo[flutter::EncodableValue("availablePhysicalMemory")] = flutter::EncodableValue(availMem);
  memoryInfo[flutter::EncodableValue("totalStorageSpace")] = flutter::EncodableValue(totalStorage);
  memoryInfo[flutter::EncodableValue("availableStorageSpace")] = flutter::EncodableValue(availStorage);
  memoryInfo[flutter::EncodableValue("usedStorageSpace")] = flutter::EncodableValue(totalStorage - availStorage);
  memoryInfo[flutter::EncodableValue("memoryUsagePercentage")] = 
      flutter::EncodableValue(totalMem > 0 ? ((totalMem - availMem) * 100.0 / totalMem) : 0.0);
  deviceInfo[flutter::EncodableValue("memoryInfo")] = flutter::EncodableValue(memoryInfo);
  
  // Display info
  flutter::EncodableMap displayInfo;
  int width = GetScreenWidth();
  int height = GetScreenHeight();
  double density = GetPixelDensity();
  double refreshRate = GetRefreshRate();
  
  displayInfo[flutter::EncodableValue("screenWidth")] = flutter::EncodableValue(width);
  displayInfo[flutter::EncodableValue("screenHeight")] = flutter::EncodableValue(height);
  displayInfo[flutter::EncodableValue("pixelDensity")] = flutter::EncodableValue(density);
  displayInfo[flutter::EncodableValue("refreshRate")] = flutter::EncodableValue(refreshRate);
  displayInfo[flutter::EncodableValue("screenSizeInches")] = flutter::EncodableValue(24.0); // Approximate
  displayInfo[flutter::EncodableValue("orientation")] = flutter::EncodableValue(width > height ? "landscape" : "portrait");
  displayInfo[flutter::EncodableValue("isHdr")] = flutter::EncodableValue(false);
  deviceInfo[flutter::EncodableValue("displayInfo")] = flutter::EncodableValue(displayInfo);
  
  // Security info
  flutter::EncodableMap securityInfo;
  securityInfo[flutter::EncodableValue("isDeviceSecure")] = flutter::EncodableValue(true);
  securityInfo[flutter::EncodableValue("hasFingerprint")] = flutter::EncodableValue(false);
  securityInfo[flutter::EncodableValue("hasFaceUnlock")] = flutter::EncodableValue(false);
  securityInfo[flutter::EncodableValue("screenLockEnabled")] = flutter::EncodableValue(true);
  securityInfo[flutter::EncodableValue("encryptionStatus")] = flutter::EncodableValue("encrypted");
  deviceInfo[flutter::EncodableValue("securityInfo")] = flutter::EncodableValue(securityInfo);
  
  return deviceInfo;
}

flutter::EncodableMap FlutterDeviceInfoPlusPlugin::GetBatteryInfo() {
  flutter::EncodableMap batteryInfo;
  
  SYSTEM_POWER_STATUS status;
  if (GetSystemPowerStatus(&status)) {
    batteryInfo[flutter::EncodableValue("batteryLevel")] = flutter::EncodableValue((int)status.BatteryLifePercent);
    std::string chargingStatus = "unknown";
    if (status.ACLineStatus == 1) {
      chargingStatus = status.BatteryLifePercent == 100 ? "full" : "charging";
    } else {
      chargingStatus = "discharging";
    }
    batteryInfo[flutter::EncodableValue("chargingStatus")] = flutter::EncodableValue(chargingStatus);
    batteryInfo[flutter::EncodableValue("batteryHealth")] = flutter::EncodableValue("good");
    batteryInfo[flutter::EncodableValue("batteryCapacity")] = flutter::EncodableValue(0);
    batteryInfo[flutter::EncodableValue("batteryVoltage")] = flutter::EncodableValue(0.0);
    batteryInfo[flutter::EncodableValue("batteryTemperature")] = flutter::EncodableValue(0.0);
  } else {
    // No battery (desktop)
    return flutter::EncodableMap(); // Return empty map, will be null in Dart
  }
  
  return batteryInfo;
}

flutter::EncodableMap FlutterDeviceInfoPlusPlugin::GetSensorInfo() {
  flutter::EncodableMap sensorInfo;
  flutter::EncodableList sensors;
  
  // Windows doesn't have many sensors accessible via standard APIs
  // Most sensors would require device-specific drivers
  sensors.push_back(flutter::EncodableValue("accelerometer")); // If available via drivers
  
  sensorInfo[flutter::EncodableValue("availableSensors")] = flutter::EncodableValue(sensors);
  return sensorInfo;
}

flutter::EncodableMap FlutterDeviceInfoPlusPlugin::GetNetworkInfo() {
  flutter::EncodableMap networkInfo;
  
  std::string ipAddress = GetIPAddress();
  std::string macAddress = GetMACAddress();
  
  networkInfo[flutter::EncodableValue("connectionType")] = flutter::EncodableValue("ethernet");
  networkInfo[flutter::EncodableValue("networkSpeed")] = flutter::EncodableValue("Unknown");
  networkInfo[flutter::EncodableValue("isConnected")] = flutter::EncodableValue(!ipAddress.empty());
  networkInfo[flutter::EncodableValue("ipAddress")] = flutter::EncodableValue(ipAddress);
  networkInfo[flutter::EncodableValue("macAddress")] = flutter::EncodableValue(macAddress);
  
  return networkInfo;
}

std::string FlutterDeviceInfoPlusPlugin::GetProcessorArchitecture() {
  SYSTEM_INFO si;
  GetSystemInfo(&si);
  
  switch (si.wProcessorArchitecture) {
    case PROCESSOR_ARCHITECTURE_AMD64:
      return "x86_64";
    case PROCESSOR_ARCHITECTURE_ARM:
      return "arm";
    case PROCESSOR_ARCHITECTURE_ARM64:
      return "arm64";
    case PROCESSOR_ARCHITECTURE_IA64:
      return "ia64";
    case PROCESSOR_ARCHITECTURE_INTEL:
      return "x86";
    default:
      return "unknown";
  }
}

int FlutterDeviceInfoPlusPlugin::GetProcessorCoreCount() {
  SYSTEM_INFO si;
  GetSystemInfo(&si);
  return si.dwNumberOfProcessors;
}

int FlutterDeviceInfoPlusPlugin::GetProcessorMaxFrequency() {
  HKEY hKey;
  if (RegOpenKeyExA(HKEY_LOCAL_MACHINE, 
                    "HARDWARE\\DESCRIPTION\\System\\CentralProcessor\\0",
                    0, KEY_READ, &hKey) == ERROR_SUCCESS) {
    DWORD maxMHz = 0;
    DWORD size = sizeof(DWORD);
    if (RegQueryValueExA(hKey, "~MHz", NULL, NULL, (LPBYTE)&maxMHz, &size) == ERROR_SUCCESS) {
      RegCloseKey(hKey);
      return maxMHz;
    }
    RegCloseKey(hKey);
  }
  return 0;
}

std::string FlutterDeviceInfoPlusPlugin::GetProcessorName() {
  HKEY hKey;
  char processorName[256] = {0};
  DWORD size = sizeof(processorName);
  
  if (RegOpenKeyExA(HKEY_LOCAL_MACHINE,
                    "HARDWARE\\DESCRIPTION\\System\\CentralProcessor\\0",
                    0, KEY_READ, &hKey) == ERROR_SUCCESS) {
    if (RegQueryValueExA(hKey, "ProcessorNameString", NULL, NULL,
                         (LPBYTE)processorName, &size) == ERROR_SUCCESS) {
      RegCloseKey(hKey);
      return std::string(processorName);
    }
    RegCloseKey(hKey);
  }
  return "Unknown Processor";
}

std::vector<std::string> FlutterDeviceInfoPlusPlugin::GetProcessorFeatures() {
  std::vector<std::string> features;
  
  int cpuInfo[4];
  __cpuid(cpuInfo, 1);
  
  if (cpuInfo[3] & (1 << 23)) features.push_back("MMX");
  if (cpuInfo[3] & (1 << 25)) features.push_back("SSE");
  if (cpuInfo[3] & (1 << 26)) features.push_back("SSE2");
  
  __cpuid(cpuInfo, 7);
  if (cpuInfo[1] & (1 << 5)) features.push_back("AVX2");
  if (cpuInfo[1] & (1 << 16)) features.push_back("AVX512F");
  
  return features;
}

int64_t FlutterDeviceInfoPlusPlugin::GetTotalPhysicalMemory() {
  MEMORYSTATUSEX memStatus;
  memStatus.dwLength = sizeof(MEMORYSTATUSEX);
  if (GlobalMemoryStatusEx(&memStatus)) {
    return memStatus.ullTotalPhys;
  }
  return 0;
}

int64_t FlutterDeviceInfoPlusPlugin::GetAvailablePhysicalMemory() {
  MEMORYSTATUSEX memStatus;
  memStatus.dwLength = sizeof(MEMORYSTATUSEX);
  if (GlobalMemoryStatusEx(&memStatus)) {
    return memStatus.ullAvailPhys;
  }
  return 0;
}

int64_t FlutterDeviceInfoPlusPlugin::GetTotalStorageSpace() {
  ULARGE_INTEGER freeBytes, totalBytes;
  if (GetDiskFreeSpaceExA("C:\\", &freeBytes, &totalBytes, NULL)) {
    return totalBytes.QuadPart;
  }
  return 0;
}

int64_t FlutterDeviceInfoPlusPlugin::GetAvailableStorageSpace() {
  ULARGE_INTEGER freeBytes, totalBytes;
  if (GetDiskFreeSpaceExA("C:\\", &freeBytes, &totalBytes, NULL)) {
    return freeBytes.QuadPart;
  }
  return 0;
}

int FlutterDeviceInfoPlusPlugin::GetScreenWidth() {
  return GetSystemMetrics(SM_CXSCREEN);
}

int FlutterDeviceInfoPlusPlugin::GetScreenHeight() {
  return GetSystemMetrics(SM_CYSCREEN);
}

double FlutterDeviceInfoPlusPlugin::GetPixelDensity() {
  HDC hdc = GetDC(NULL);
  int dpi = GetDeviceCaps(hdc, LOGPIXELSX);
  ReleaseDC(NULL, hdc);
  return dpi / 96.0; // 96 DPI is standard
}

double FlutterDeviceInfoPlusPlugin::GetRefreshRate() {
  DEVMODEA dm;
  dm.dmSize = sizeof(DEVMODEA);
  if (EnumDisplaySettingsA(NULL, ENUM_CURRENT_SETTINGS, &dm)) {
    return dm.dmDisplayFrequency;
  }
  return 60.0;
}

std::string FlutterDeviceInfoPlusPlugin::GetIPAddress() {
  IP_ADAPTER_INFO adapterInfo[16];
  DWORD dwBufLen = sizeof(adapterInfo);
  
  if (GetAdaptersInfo(adapterInfo, &dwBufLen) == ERROR_SUCCESS) {
    PIP_ADAPTER_INFO pAdapterInfo = adapterInfo;
    do {
      // IF_TYPE_ETHERNET = 6, IF_TYPE_IEEE80211 = 71
      if (pAdapterInfo->Type == 6 || pAdapterInfo->Type == 71) {
        return std::string(pAdapterInfo->IpAddressList.IpAddress.String);
      }
      pAdapterInfo = pAdapterInfo->Next;
    } while (pAdapterInfo);
  }
  return "unknown";
}

std::string FlutterDeviceInfoPlusPlugin::GetMACAddress() {
  IP_ADAPTER_INFO adapterInfo[16];
  DWORD dwBufLen = sizeof(adapterInfo);
  
  if (GetAdaptersInfo(adapterInfo, &dwBufLen) == ERROR_SUCCESS) {
    PIP_ADAPTER_INFO pAdapterInfo = adapterInfo;
    do {
      // IF_TYPE_ETHERNET = 6, IF_TYPE_IEEE80211 = 71
      if (pAdapterInfo->Type == 6 || pAdapterInfo->Type == 71) {
        char mac[18];
        sprintf_s(mac, "%02X:%02X:%02X:%02X:%02X:%02X",
                  pAdapterInfo->Address[0], pAdapterInfo->Address[1],
                  pAdapterInfo->Address[2], pAdapterInfo->Address[3],
                  pAdapterInfo->Address[4], pAdapterInfo->Address[5]);
        return std::string(mac);
      }
      pAdapterInfo = pAdapterInfo->Next;
    } while (pAdapterInfo);
  }
  return "unknown";
}

}  // namespace flutter_device_info_plus
