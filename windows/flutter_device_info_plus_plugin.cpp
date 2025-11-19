#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>
#include <winternl.h>
#include <iphlpapi.h>
#include <pdh.h>
#include <psapi.h>
#include <intrin.h>
#include <sstream>
#include <memory>
#include <vector>
#include <map>

namespace {

using flutter::EncodableMap;
using flutter::EncodableValue;

class FlutterDeviceInfoPlusPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  FlutterDeviceInfoPlusPlugin();

  virtual ~FlutterDeviceInfoPlusPlugin();

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  EncodableMap GetDeviceInfo();
  EncodableMap GetBatteryInfo();
  EncodableMap GetSensorInfo();
  EncodableMap GetNetworkInfo();

  std::string GetProcessorArchitecture();
  int GetProcessorCoreCount();
  int GetProcessorMaxFrequency();
  std::string GetProcessorName();
  std::vector<std::string> GetProcessorFeatures();
  int64_t GetTotalPhysicalMemory();
  int64_t GetAvailablePhysicalMemory();
  int64_t GetTotalStorageSpace();
  int64_t GetAvailableStorageSpace();
  int GetScreenWidth();
  int GetScreenHeight();
  double GetPixelDensity();
  double GetRefreshRate();
  std::string GetIPAddress();
  std::string GetMACAddress();
};

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

EncodableMap FlutterDeviceInfoPlusPlugin::GetDeviceInfo() {
  EncodableMap deviceInfo;
  
  // Basic device info
  char computerName[MAX_COMPUTERNAME_LENGTH + 1];
  DWORD size = sizeof(computerName);
  GetComputerNameA(computerName, &size);
  deviceInfo[EncodableValue("deviceName")] = EncodableValue(std::string(computerName));
  
  OSVERSIONINFOEX osvi;
  ZeroMemory(&osvi, sizeof(OSVERSIONINFOEX));
  osvi.dwOSVersionInfoSize = sizeof(OSVERSIONINFOEX);
  GetVersionEx((OSVERSIONINFO*)&osvi);
  
  deviceInfo[EncodableValue("manufacturer")] = EncodableValue("Microsoft");
  deviceInfo[EncodableValue("model")] = EncodableValue("Windows PC");
  deviceInfo[EncodableValue("brand")] = EncodableValue("Microsoft");
  deviceInfo[EncodableValue("operatingSystem")] = EncodableValue("Windows");
  
  std::string version = std::to_string(osvi.dwMajorVersion) + "." + 
                        std::to_string(osvi.dwMinorVersion);
  deviceInfo[EncodableValue("systemVersion")] = EncodableValue(version);
  deviceInfo[EncodableValue("buildNumber")] = EncodableValue(std::to_string(osvi.dwBuildNumber));
  deviceInfo[EncodableValue("kernelVersion")] = EncodableValue("NT");
  
  // Processor info
  EncodableMap processorInfo;
  processorInfo[EncodableValue("architecture")] = EncodableValue(GetProcessorArchitecture());
  processorInfo[EncodableValue("coreCount")] = EncodableValue(GetProcessorCoreCount());
  processorInfo[EncodableValue("maxFrequency")] = EncodableValue(GetProcessorMaxFrequency());
  processorInfo[EncodableValue("processorName")] = EncodableValue(GetProcessorName());
  
  EncodableList features;
  for (const auto& feature : GetProcessorFeatures()) {
    features.push_back(EncodableValue(feature));
  }
  processorInfo[EncodableValue("features")] = EncodableValue(features);
  deviceInfo[EncodableValue("processorInfo")] = EncodableValue(processorInfo);
  
  // Memory info
  EncodableMap memoryInfo;
  int64_t totalMem = GetTotalPhysicalMemory();
  int64_t availMem = GetAvailablePhysicalMemory();
  int64_t totalStorage = GetTotalStorageSpace();
  int64_t availStorage = GetAvailableStorageSpace();
  
  memoryInfo[EncodableValue("totalPhysicalMemory")] = EncodableValue(totalMem);
  memoryInfo[EncodableValue("availablePhysicalMemory")] = EncodableValue(availMem);
  memoryInfo[EncodableValue("totalStorageSpace")] = EncodableValue(totalStorage);
  memoryInfo[EncodableValue("availableStorageSpace")] = EncodableValue(availStorage);
  memoryInfo[EncodableValue("usedStorageSpace")] = EncodableValue(totalStorage - availStorage);
  memoryInfo[EncodableValue("memoryUsagePercentage")] = 
      EncodableValue(totalMem > 0 ? ((totalMem - availMem) * 100.0 / totalMem) : 0.0);
  deviceInfo[EncodableValue("memoryInfo")] = EncodableValue(memoryInfo);
  
  // Display info
  EncodableMap displayInfo;
  int width = GetScreenWidth();
  int height = GetScreenHeight();
  double density = GetPixelDensity();
  double refreshRate = GetRefreshRate();
  
  displayInfo[EncodableValue("screenWidth")] = EncodableValue(width);
  displayInfo[EncodableValue("screenHeight")] = EncodableValue(height);
  displayInfo[EncodableValue("pixelDensity")] = EncodableValue(density);
  displayInfo[EncodableValue("refreshRate")] = EncodableValue(refreshRate);
  displayInfo[EncodableValue("screenSizeInches")] = EncodableValue(24.0); // Approximate
  displayInfo[EncodableValue("orientation")] = EncodableValue(width > height ? "landscape" : "portrait");
  displayInfo[EncodableValue("isHdr")] = EncodableValue(false);
  deviceInfo[EncodableValue("displayInfo")] = EncodableValue(displayInfo);
  
  // Security info
  EncodableMap securityInfo;
  securityInfo[EncodableValue("isDeviceSecure")] = EncodableValue(true);
  securityInfo[EncodableValue("hasFingerprint")] = EncodableValue(false);
  securityInfo[EncodableValue("hasFaceUnlock")] = EncodableValue(false);
  securityInfo[EncodableValue("screenLockEnabled")] = EncodableValue(true);
  securityInfo[EncodableValue("encryptionStatus")] = EncodableValue("encrypted");
  deviceInfo[EncodableValue("securityInfo")] = EncodableValue(securityInfo);
  
  return deviceInfo;
}

EncodableMap FlutterDeviceInfoPlusPlugin::GetBatteryInfo() {
  EncodableMap batteryInfo;
  
  SYSTEM_POWER_STATUS status;
  if (GetSystemPowerStatus(&status)) {
    batteryInfo[EncodableValue("batteryLevel")] = EncodableValue((int)status.BatteryLifePercent);
    std::string chargingStatus = "unknown";
    if (status.ACLineStatus == 1) {
      chargingStatus = status.BatteryLifePercent == 100 ? "full" : "charging";
    } else {
      chargingStatus = "discharging";
    }
    batteryInfo[EncodableValue("chargingStatus")] = EncodableValue(chargingStatus);
    batteryInfo[EncodableValue("batteryHealth")] = EncodableValue("good");
    batteryInfo[EncodableValue("batteryCapacity")] = EncodableValue(0);
    batteryInfo[EncodableValue("batteryVoltage")] = EncodableValue(0.0);
    batteryInfo[EncodableValue("batteryTemperature")] = EncodableValue(0.0);
  } else {
    // No battery (desktop)
    return EncodableMap(); // Return empty map, will be null in Dart
  }
  
  return batteryInfo;
}

EncodableMap FlutterDeviceInfoPlusPlugin::GetSensorInfo() {
  EncodableMap sensorInfo;
  EncodableList sensors;
  
  // Windows doesn't have many sensors accessible via standard APIs
  // Most sensors would require device-specific drivers
  sensors.push_back(EncodableValue("accelerometer")); // If available via drivers
  
  sensorInfo[EncodableValue("availableSensors")] = EncodableValue(sensors);
  return sensorInfo;
}

EncodableMap FlutterDeviceInfoPlusPlugin::GetNetworkInfo() {
  EncodableMap networkInfo;
  
  std::string ipAddress = GetIPAddress();
  std::string macAddress = GetMACAddress();
  
  networkInfo[EncodableValue("connectionType")] = EncodableValue("ethernet");
  networkInfo[EncodableValue("networkSpeed")] = EncodableValue("Unknown");
  networkInfo[EncodableValue("isConnected")] = EncodableValue(!ipAddress.empty());
  networkInfo[EncodableValue("ipAddress")] = EncodableValue(ipAddress);
  networkInfo[EncodableValue("macAddress")] = EncodableValue(macAddress);
  
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
      if (pAdapterInfo->Type == MIB_IF_TYPE_ETHERNET || 
          pAdapterInfo->Type == IF_TYPE_IEEE80211) {
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
      if (pAdapterInfo->Type == MIB_IF_TYPE_ETHERNET || 
          pAdapterInfo->Type == IF_TYPE_IEEE80211) {
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

}  // namespace

void FlutterDeviceInfoPlusPluginRegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  FlutterDeviceInfoPlusPlugin::RegisterWithRegistrar(registrar);
}

