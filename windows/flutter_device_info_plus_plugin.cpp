// 1. ABSOLUTE SOCKET GUARD (Must be at the absolute top)
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#define _WINSOCKAPI_   // Prevents windows.h from loading the legacy winsock.h header

// 2. MODERN WINDOWS SOCKETS
#include <winsock2.h>
#include <ws2tcpip.h>

// 3. PLUGIN HEADER (Processed on a clean, guarded environment)
#include "flutter_device_info_plus_plugin.h"

// 4. WINDOWS SYSTEM APIS
#include <windows.h>
#include <iphlpapi.h>
#include <winternl.h>
#include <pdh.h>
#include <psapi.h>
#include <intrin.h>

// 5. FLUTTER ENGINE HEADERS
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

// 6. C++ STANDARD TEMPLATE LIBRARY (STL)
#include <sstream>
#include <memory>
#include <vector>
#include <map>
#include <string>
#include <iomanip>

// Link-time static libraries for MSVC Compiler
#pragma comment(lib, "iphlpapi.lib")
#pragma comment(lib, "ws2_32.lib")
#pragma comment(lib, "pdh.lib")

namespace flutter_device_info_plus {

// SMBIOS structure definition for the table entry header
struct SMBIOSHeader {
    BYTE Type;
    BYTE Length;
    WORD Handle;
};

// SMBIOS structure definition for Type 1: System Information
struct SMBIOS_Type1 {
    SMBIOSHeader Header;
    BYTE ManufacturerIdx;
    BYTE ProductNameIdx;
    BYTE VersionIdx;
    BYTE SerialNumberIdx;
};

/**
 * Extracts a specific null-terminated string from the SMBIOS string pool area
 * based on its 1-based index assigned inside the hardware structure.
 */
std::string GetSMBIOSStringData(BYTE* pStrings, BYTE index) {
    if (index == 0) return "Unknown";
    while (--index > 0) {
        while (*pStrings != 0) pStrings++;
        pStrings++; // Step over the null terminator of the previous string
    }
    return std::string((char*)pStrings);
}

/**
 * Queries the local System Firmware Table ('RSMB') to fetch raw SMBIOS entries
 * and parses Type 1 structures to look up native desktop hardware information.
 */
std::string QuerySMBIOSField(int fieldType) {
    std::string result = "";
    DWORD bufferSize = GetSystemFirmwareTable('RSMB', 0, nullptr, 0);
    
    if (bufferSize > 0) {
        std::vector<BYTE> buffer(bufferSize);
        if (GetSystemFirmwareTable('RSMB', 0, buffer.data(), bufferSize) == bufferSize) {
            // Skip the 8-byte SMBIOS firmware provider header
            BYTE* pData = buffer.data() + 8; 
            BYTE* pEnd = buffer.data() + bufferSize;

            while (pData < pEnd) {
                SMBIOSHeader* header = (SMBIOSHeader*)pData;
                
                // Filter specifically for Type 1 (System Information) structural layouts
                if (header->Type == 1 && header->Length >= sizeof(SMBIOS_Type1)) {
                    SMBIOS_Type1* type1 = (SMBIOS_Type1*)pData;
                    BYTE* pStrings = pData + header->Length;

                    if (fieldType == 1) { // Extract Hardware Manufacturer / Brand
                        result = GetSMBIOSStringData(pStrings, type1->ManufacturerIdx);
                    } else if (fieldType == 2) { // Extract Hardware Product Model Name
                        result = GetSMBIOSStringData(pStrings, type1->ProductNameIdx);
                    }
                    break; // Target block located and handled, break loop execution
                }

                // Advance over current block structures along with its variable-length string pool
                pData += header->Length;
                while (pData < pEnd && (*pData != 0 || *(pData + 1) != 0)) {
                    pData++;
                }
                pData += 2; // Jump over the double null-terminator sequence ending the pool
            }
        }
    }
    return result;
}

std::string GetWindowsManufacturer() {
    std::string val = QuerySMBIOSField(1);
    return val.empty() ? "Microsoft" : val;
}

std::string GetWindowsModel() {
    std::string val = QuerySMBIOSField(2);
    return val.empty() ? "Windows PC" : val;
}

std::string GetWindowsBrand() {
    std::string val = QuerySMBIOSField(1);
    return val.empty() ? "Microsoft" : val;
}

/**
 * Registers the device information plugin instance within the Flutter build environment
 * and ties incoming Dart platform communications to the standard handler routine.
 */
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

/**
 * Distributes executing actions to their dedicated native internal retrieval procedures
 * based on the incoming channel identifier string originating from Dart.
 */
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

/**
 * Fetches thorough operating system details, native hardware descriptions, processor attributes,
 * physical memory capabilities, display configurations, and default host environment variables.
 */
flutter::EncodableMap FlutterDeviceInfoPlusPlugin::GetDeviceInfo() {
  flutter::EncodableMap deviceInfo;
  
  // Basic device host name mapping
  char computerName[MAX_COMPUTERNAME_LENGTH + 1];
  DWORD size = sizeof(computerName);
  GetComputerNameA(computerName, &size);

  deviceInfo[flutter::EncodableValue("deviceId")] = flutter::EncodableValue(GetDeviceId());
  deviceInfo[flutter::EncodableValue("deviceName")] = flutter::EncodableValue(std::string(computerName));
  
  // Dynamic linking to RtlGetVersion to bypass application manifest compatibility shims
  typedef NTSTATUS (WINAPI *RtlGetVersionPtr)(PRTL_OSVERSIONINFOEXW);
  HMODULE hMod = GetModuleHandleW(L"ntdll.dll");

  if (hMod) {
    RtlGetVersionPtr fxPtr = (RtlGetVersionPtr)GetProcAddress(hMod, "RtlGetVersion");
    if (fxPtr != nullptr) {
      RTL_OSVERSIONINFOEXW osvi = {0};
      osvi.dwOSVersionInfoSize = sizeof(osvi);
      if (fxPtr(&osvi) == 0) {
        std::string version = "";

        // Evaluate build thresholds to properly classify marketing names
        if (osvi.dwBuildNumber >= 22000) {
          version = "11";
        } else if (osvi.dwBuildNumber >= 10240 && osvi.dwBuildNumber < 22000) {
          version = "10";
        } else if (osvi.dwBuildNumber >= 9600 && osvi.dwBuildNumber < 10240) {
          version = "8.1";
        } else if (osvi.dwBuildNumber >= 9200 && osvi.dwBuildNumber < 9600) {
          version = "8";
        } else if (osvi.dwBuildNumber >= 7600 && osvi.dwBuildNumber < 9200) {
          version = "7";
        } else if (osvi.dwBuildNumber >= 6000 && osvi.dwBuildNumber < 7600) {
          version = "Vista";
        } else {
          version = std::to_string(osvi.dwMajorVersion) + "." + std::to_string(osvi.dwMinorVersion);
        }

        std::string buildNumber = std::to_string(osvi.dwBuildNumber);
        std::string kernelVersion = std::to_string(osvi.dwMajorVersion) + "." + std::to_string(osvi.dwMinorVersion) + "." + std::to_string(osvi.dwBuildNumber);
        
        deviceInfo[flutter::EncodableValue("systemVersion")] = flutter::EncodableValue(version);
        deviceInfo[flutter::EncodableValue("buildNumber")] = flutter::EncodableValue(buildNumber);
        deviceInfo[flutter::EncodableValue("kernelVersion")] = flutter::EncodableValue(kernelVersion);
      } else {
        deviceInfo[flutter::EncodableValue("systemVersion")] = flutter::EncodableValue("Unknown");
        deviceInfo[flutter::EncodableValue("buildNumber")] = flutter::EncodableValue("Unknown");
        deviceInfo[flutter::EncodableValue("kernelVersion")] = flutter::EncodableValue("NT");
      }
    } else {
      deviceInfo[flutter::EncodableValue("systemVersion")] = flutter::EncodableValue("Unknown");
      deviceInfo[flutter::EncodableValue("buildNumber")] = flutter::EncodableValue("Unknown");
      deviceInfo[flutter::EncodableValue("kernelVersion")] = flutter::EncodableValue("NT");
    }
  } else {
    deviceInfo[flutter::EncodableValue("systemVersion")] = flutter::EncodableValue("Unknown");
    deviceInfo[flutter::EncodableValue("buildNumber")] = flutter::EncodableValue("Unknown");
    deviceInfo[flutter::EncodableValue("kernelVersion")] = flutter::EncodableValue("NT");
  }
  
  // Inject base device identity variables retrieved via SMBIOS routines
  deviceInfo[flutter::EncodableValue("manufacturer")] = flutter::EncodableValue(GetWindowsManufacturer());
  deviceInfo[flutter::EncodableValue("model")] = flutter::EncodableValue(GetWindowsModel());
  deviceInfo[flutter::EncodableValue("brand")] = flutter::EncodableValue(GetWindowsBrand());
  deviceInfo[flutter::EncodableValue("operatingSystem")] = flutter::EncodableValue("Windows");
  
  // Processor specifications allocation
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
  
  // Global memory capacity map configurations
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
  
  // Storage Info Configuration
  flutter::EncodableMap storageInfo;
  flutter::EncodableList volumesList;
  DWORD drives = GetLogicalDrives();
  for (int i = 0; i < 26; i++) {
    if (drives & (1 << i)) {
      char rootPath[] = {(char)('A' + i), ':', '\\', '\0'};
      UINT driveType = GetDriveTypeA(rootPath);
      
      flutter::EncodableMap volume;
      volume[flutter::EncodableValue("mountPath")] = flutter::EncodableValue(std::string(rootPath));
      
      char volumeName[MAX_PATH + 1] = {0};
      if (GetVolumeInformationA(rootPath, volumeName, MAX_PATH + 1, NULL, NULL, NULL, NULL, 0)) {
        std::string volStr = std::string(volumeName);
        if (volStr.empty()) {
            volStr = "Local Disk";
        }
        volume[flutter::EncodableValue("name")] = flutter::EncodableValue(volStr);
      } else {
        volume[flutter::EncodableValue("name")] = flutter::EncodableValue(std::string("Local Disk"));
      }

      ULARGE_INTEGER freeBytes, totalBytes;
      if (GetDiskFreeSpaceExA(rootPath, &freeBytes, &totalBytes, NULL)) {
        volume[flutter::EncodableValue("totalCapacity")] = flutter::EncodableValue((int64_t)totalBytes.QuadPart);
        volume[flutter::EncodableValue("availableCapacity")] = flutter::EncodableValue((int64_t)freeBytes.QuadPart);
        volume[flutter::EncodableValue("usedCapacity")] = flutter::EncodableValue((int64_t)(totalBytes.QuadPart - freeBytes.QuadPart));
      } else {
        volume[flutter::EncodableValue("totalCapacity")] = flutter::EncodableValue((int64_t)0);
        volume[flutter::EncodableValue("availableCapacity")] = flutter::EncodableValue((int64_t)0);
        volume[flutter::EncodableValue("usedCapacity")] = flutter::EncodableValue((int64_t)0);
      }
      
      std::string devTypeStr = "Unknown";
      bool isRemovable = false;
      switch(driveType) {
        case DRIVE_REMOVABLE: devTypeStr = "Removable"; isRemovable = true; break;
        case DRIVE_FIXED: devTypeStr = "Fixed"; break;
        case DRIVE_REMOTE: devTypeStr = "Network"; break;
        case DRIVE_CDROM: devTypeStr = "CD-ROM"; isRemovable = true; break;
        case DRIVE_RAMDISK: devTypeStr = "RAM Disk"; break;
      }
      volume[flutter::EncodableValue("deviceType")] = flutter::EncodableValue(devTypeStr);
      volume[flutter::EncodableValue("isRemovable")] = flutter::EncodableValue(isRemovable);

      volumesList.push_back(flutter::EncodableValue(volume));
    }
  }
  storageInfo[flutter::EncodableValue("volumes")] = flutter::EncodableValue(volumesList);
  deviceInfo[flutter::EncodableValue("storageInfo")] = flutter::EncodableValue(storageInfo);

  
  // Graphics display environment specifications mapping
  flutter::EncodableMap displayInfo;
  int width = GetScreenWidth();
  int height = GetScreenHeight();
  double density = GetPixelDensity();
  double refreshRate = GetRefreshRate();
  
  displayInfo[flutter::EncodableValue("screenWidth")] = flutter::EncodableValue(width);
  displayInfo[flutter::EncodableValue("screenHeight")] = flutter::EncodableValue(height);
  displayInfo[flutter::EncodableValue("pixelDensity")] = flutter::EncodableValue(density);
  displayInfo[flutter::EncodableValue("refreshRate")] = flutter::EncodableValue(refreshRate);
  displayInfo[flutter::EncodableValue("screenSizeInches")] = flutter::EncodableValue(24.0);
  displayInfo[flutter::EncodableValue("orientation")] = flutter::EncodableValue(width > height ? "landscape" : "portrait");
  displayInfo[flutter::EncodableValue("isHdr")] = flutter::EncodableValue(false);
  deviceInfo[flutter::EncodableValue("displayInfo")] = flutter::EncodableValue(displayInfo);
  
  // Security capabilities parameters definition
  flutter::EncodableMap securityInfo;
  securityInfo[flutter::EncodableValue("isDeviceSecure")] = flutter::EncodableValue(true);
  securityInfo[flutter::EncodableValue("hasFingerprint")] = flutter::EncodableValue(false);
  securityInfo[flutter::EncodableValue("hasFaceUnlock")] = flutter::EncodableValue(false);
  securityInfo[flutter::EncodableValue("screenLockEnabled")] = flutter::EncodableValue(true);
  securityInfo[flutter::EncodableValue("encryptionStatus")] = flutter::EncodableValue("encrypted");
  deviceInfo[flutter::EncodableValue("securityInfo")] = flutter::EncodableValue(securityInfo);
  
  return deviceInfo;
}

/**
 * Retrieves energy configurations and status reports via standard device subsystem mappings.
 * Returns an empty collection container if execution runs on battery-free desktops.
 */
flutter::EncodableMap FlutterDeviceInfoPlusPlugin::GetBatteryInfo() {
  flutter::EncodableMap batteryInfo;
  
  SYSTEM_POWER_STATUS status;
  if (GetSystemPowerStatus(&status)) {
    if (status.BatteryLifePercent == 255) {
      // 255 indicates that system has no battery (e.g. desktop PC) or is unknown.
      return flutter::EncodableMap();
    }
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
    return flutter::EncodableMap();
  }
  
  return batteryInfo;
}

flutter::EncodableMap FlutterDeviceInfoPlusPlugin::GetSensorInfo() {
  flutter::EncodableMap sensorInfo;
  flutter::EncodableList sensors;
  
  sensors.push_back(flutter::EncodableValue("accelerometer"));
  
  sensorInfo[flutter::EncodableValue("availableSensors")] = flutter::EncodableValue(sensors);
  return sensorInfo;
}

/**
 * Scans active network drivers via the native IP Helper API (`GetAdaptersAddresses`)
 * to discover connection paths, compute precise line speeds, look up hardware MAC layout strings,
 * extract IPv4 addresses, and evaluate real-time terminal network status boundaries.
 */
flutter::EncodableMap FlutterDeviceInfoPlusPlugin::GetNetworkInfo() {
    flutter::EncodableMap networkInfo;

    std::string connectionType = "none";
    std::string networkSpeed = "Unknown";
    std::string ipAddress = "Unknown";
    std::string macAddress = "Unknown";

    ULONG bufferSize = 15000; // Allocate a solid safety initial table buffer size
    std::vector<BYTE> buffer(bufferSize);
    PIP_ADAPTER_ADDRESSES adapters = reinterpret_cast<PIP_ADAPTER_ADDRESSES>(buffer.data());

    // Request IPv4 adapter details exclusively to avoid local tunnel pollution
    ULONG result = GetAdaptersAddresses(AF_INET, GAA_FLAG_INCLUDE_GATEWAYS, nullptr, adapters, &bufferSize);
    
    // Resize vector explicitly if the framework flags an unexpected buffer threshold crash
    if (result == ERROR_BUFFER_OVERFLOW) {
        buffer.resize(bufferSize);
        adapters = reinterpret_cast<PIP_ADAPTER_ADDRESSES>(buffer.data());
        result = GetAdaptersAddresses(AF_INET, GAA_FLAG_INCLUDE_GATEWAYS, nullptr, adapters, &bufferSize);
    }

    if (result == NO_ERROR) {
        PIP_ADAPTER_ADDRESSES adapter = adapters;
        while (adapter != nullptr) {
            // Target only running adaptors bound directly to a valid network path configuration
            if (adapter->OperStatus == IfOperStatusUp && adapter->FirstGatewayAddress != nullptr) {
                
                // 1. DETERMINE HARDWARE MEDIUM TYPE
                if (adapter->IfType == IF_TYPE_ETHERNET_CSMACD) {
                    connectionType = "ethernet";
                } else if (adapter->IfType == IF_TYPE_IEEE80211) {
                    connectionType = "wifi";
                } else if (adapter->IfType == IF_TYPE_WWANPP || adapter->IfType == IF_TYPE_WWANPP2) {
                    connectionType = "cellular";
                } else if (adapter->IfType == IF_TYPE_SOFTWARE_LOOPBACK) {
                    adapter = adapter->Next;
                    continue; // Discard localhost adapter interfaces
                } else {
                    connectionType = "other";
                }

                // 2. COMPUTE SYSTEM LINK TRANSMISSION SPEED
                ULONGLONG speedBps = adapter->ReceiveLinkSpeed;
                if (speedBps > 0 && speedBps != MAXULONGLONG) {
                    if (speedBps >= 1000000000ULL) {
                        double speedGbps = static_cast<double>(speedBps) / 1000000000.0;
                        networkSpeed = std::to_string(static_cast<int>(speedGbps)) + " Gbps";
                    } else {
                        double speedMbps = static_cast<double>(speedBps) / 1000000.0;
                        networkSpeed = std::to_string(static_cast<int>(speedMbps)) + " Mbps";
                    }
                }

                // 3. EXTRACT THE IPV4 ADDRESS VALUE
                if (adapter->FirstUnicastAddress != nullptr) {
                    sockaddr_in* sockaddr_ipv4 = reinterpret_cast<sockaddr_in*>(adapter->FirstUnicastAddress->Address.lpSockaddr);
                    char ipBuffer[INET_ADDRSTRLEN];
                    if (InetNtopA(AF_INET, &(sockaddr_ipv4->sin_addr), ipBuffer, INET_ADDRSTRLEN) != nullptr) {
                        ipAddress = std::string(ipBuffer);
                    }
                }

                // 4. FORMAT PHYSICAL ADDRESS BYTE SEQUENCES INTO COLON-SEPARATED MAC STRINGS
                if (adapter->PhysicalAddressLength > 0) {
                    std::stringstream macStream;
                    for (ULONG i = 0; i < adapter->PhysicalAddressLength; ++i) {
                        macStream << std::setw(2) << std::setfill('0') << std::hex << std::uppercase 
                                  << static_cast<int>(adapter->PhysicalAddress[i]);
                        if (i < adapter->PhysicalAddressLength - 1) {
                            macStream << ":";
                        }
                    }
                    macAddress = macStream.str();
                }
                
                break; // Break loop execution as soon as the main active interface info is caught
            }
            adapter = adapter->Next;
        }
    }

    // Guard against blank entries, unassigned slots, zero fallbacks, and APIPA autoconfig allocations (169.254.x.x)
    bool isConnected = (!ipAddress.empty() && 
                        ipAddress != "Unknown" && 
                        ipAddress != "0.0.0.0" && 
                        ipAddress.rfind("169.254", 0) != 0);

    networkInfo[flutter::EncodableValue("isConnected")] = flutter::EncodableValue(isConnected);
    networkInfo[flutter::EncodableValue("connectionType")] = flutter::EncodableValue(std::string(connectionType));
    networkInfo[flutter::EncodableValue("networkSpeed")]   = flutter::EncodableValue(std::string(networkSpeed));
    networkInfo[flutter::EncodableValue("ipAddress")]      = flutter::EncodableValue(std::string(ipAddress));
    networkInfo[flutter::EncodableValue("macAddress")]     = flutter::EncodableValue(std::string(macAddress));

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

/**
 * Executes a compiler-level CPUID bitmask validation routine to probe hardware execution support
 * for common instructional features (MMX, SSE extensions, AVX2 vector pipelines).
 */
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
  return dpi / 96.0; // 96 DPI stands as the baseline scaling dimension
}

double FlutterDeviceInfoPlusPlugin::GetRefreshRate() {
  DEVMODEA dm;
  dm.dmSize = sizeof(DEVMODEA);
  if (EnumDisplaySettingsA(NULL, ENUM_CURRENT_SETTINGS, &dm)) {
    return dm.dmDisplayFrequency;
  }
  return 60.0;
}

/**
 * Extracts the primary volume serial identification hash from disk sectors
 * to use as a stable hardware identifier anchor point.
 */
std::string FlutterDeviceInfoPlusPlugin::GetDeviceId() {
  DWORD volumeSerialNumber;
  if (GetVolumeInformationA("C:\\", NULL, 0, &volumeSerialNumber, NULL, NULL, NULL, 0)) {
    char buffer[32];
    sprintf_s(buffer, "%08X", volumeSerialNumber);
    return std::string(buffer);
  }
  return "unknown";
}

}  // namespace flutter_device_info_plus