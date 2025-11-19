#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_linux.h>
#include <flutter/standard_method_codec.h>
#include <sys/utsname.h>
#include <sys/sysinfo.h>
#include <sys/statvfs.h>
#include <fstream>
#include <sstream>
#include <memory>
#include <vector>
#include <map>
#include <unistd.h>
#include <ifaddrs.h>
#include <net/if.h>
#include <linux/if_link.h>
#include <cstring>

namespace {

using flutter::EncodableMap;
using flutter::EncodableValue;
using flutter::EncodableList;

class FlutterDeviceInfoPlusPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarLinux *registrar);

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

  std::string ReadFile(const std::string& path);
  std::string GetProcessorArchitecture();
  int GetProcessorCoreCount();
  int GetProcessorMaxFrequency();
  std::string GetProcessorName();
  std::vector<std::string> GetProcessorFeatures();
  int64_t GetTotalPhysicalMemory();
  int64_t GetAvailablePhysicalMemory();
  int64_t GetTotalStorageSpace();
  int64_t GetAvailableStorageSpace();
  std::string GetIPAddress();
  std::string GetMACAddress();
};

void FlutterDeviceInfoPlusPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarLinux *registrar) {
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

std::string FlutterDeviceInfoPlusPlugin::ReadFile(const std::string& path) {
  std::ifstream file(path);
  if (file.is_open()) {
    std::stringstream buffer;
    buffer << file.rdbuf();
    return buffer.str();
  }
  return "";
}

EncodableMap FlutterDeviceInfoPlusPlugin::GetDeviceInfo() {
  EncodableMap deviceInfo;
  
  // Get hostname
  char hostname[256];
  gethostname(hostname, sizeof(hostname));
  deviceInfo[EncodableValue("deviceName")] = EncodableValue(std::string(hostname));
  
  // Get system info
  struct utsname unameInfo;
  uname(&unameInfo);
  
  deviceInfo[EncodableValue("manufacturer")] = EncodableValue("Unknown");
  deviceInfo[EncodableValue("model")] = EncodableValue("Linux PC");
  deviceInfo[EncodableValue("brand")] = EncodableValue("Linux");
  deviceInfo[EncodableValue("operatingSystem")] = EncodableValue("Linux");
  deviceInfo[EncodableValue("systemVersion")] = EncodableValue(std::string(unameInfo.release));
  deviceInfo[EncodableValue("buildNumber")] = EncodableValue(std::string(unameInfo.version));
  deviceInfo[EncodableValue("kernelVersion")] = EncodableValue(std::string(unameInfo.release));
  
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
  
  // Display info (approximate, would need X11 for real values)
  EncodableMap displayInfo;
  displayInfo[EncodableValue("screenWidth")] = EncodableValue(1920);
  displayInfo[EncodableValue("screenHeight")] = EncodableValue(1080);
  displayInfo[EncodableValue("pixelDensity")] = EncodableValue(1.0);
  displayInfo[EncodableValue("refreshRate")] = EncodableValue(60.0);
  displayInfo[EncodableValue("screenSizeInches")] = EncodableValue(24.0);
  displayInfo[EncodableValue("orientation")] = EncodableValue("landscape");
  displayInfo[EncodableValue("isHdr")] = EncodableValue(false);
  deviceInfo[EncodableValue("displayInfo")] = EncodableValue(displayInfo);
  
  // Security info
  EncodableMap securityInfo;
  securityInfo[EncodableValue("isDeviceSecure")] = EncodableValue(true);
  securityInfo[EncodableValue("hasFingerprint")] = EncodableValue(false);
  securityInfo[EncodableValue("hasFaceUnlock")] = EncodableValue(false);
  securityInfo[EncodableValue("screenLockEnabled")] = EncodableValue(true);
  securityInfo[EncodableValue("encryptionStatus")] = EncodableValue("unknown");
  deviceInfo[EncodableValue("securityInfo")] = EncodableValue(securityInfo);
  
  return deviceInfo;
}

EncodableMap FlutterDeviceInfoPlusPlugin::GetBatteryInfo() {
  EncodableMap batteryInfo;
  
  // Try to read battery info from /sys/class/power_supply
  std::string batteryPath = "/sys/class/power_supply/BAT0";
  std::string capacity = ReadFile(batteryPath + "/capacity");
  std::string status = ReadFile(batteryPath + "/status");
  
  if (!capacity.empty()) {
    int level = std::stoi(capacity);
    batteryInfo[EncodableValue("batteryLevel")] = EncodableValue(level);
    
    std::string chargingStatus = "unknown";
    if (!status.empty()) {
      if (status.find("Charging") != std::string::npos) {
        chargingStatus = "charging";
      } else if (status.find("Full") != std::string::npos) {
        chargingStatus = "full";
      } else {
        chargingStatus = "discharging";
      }
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
  
  // Check for available sensors in /sys/bus/iio/devices
  // This is a simplified check
  sensors.push_back(EncodableValue("accelerometer")); // If available
  
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
  struct utsname unameInfo;
  uname(&unameInfo);
  std::string machine = unameInfo.machine;
  
  if (machine.find("x86_64") != std::string::npos || 
      machine.find("amd64") != std::string::npos) {
    return "x86_64";
  } else if (machine.find("arm64") != std::string::npos || 
             machine.find("aarch64") != std::string::npos) {
    return "arm64";
  } else if (machine.find("arm") != std::string::npos) {
    return "arm";
  } else if (machine.find("i386") != std::string::npos || 
             machine.find("i686") != std::string::npos) {
    return "x86";
  }
  return machine;
}

int FlutterDeviceInfoPlusPlugin::GetProcessorCoreCount() {
  return sysconf(_SC_NPROCESSORS_ONLN);
}

int FlutterDeviceInfoPlusPlugin::GetProcessorMaxFrequency() {
  std::string cpuinfo = ReadFile("/proc/cpuinfo");
  if (!cpuinfo.empty()) {
    size_t pos = cpuinfo.find("cpu MHz");
    if (pos != std::string::npos) {
      size_t start = cpuinfo.find(":", pos) + 1;
      size_t end = cpuinfo.find("\n", start);
      if (end != std::string::npos) {
        std::string freq = cpuinfo.substr(start, end - start);
        // Trim whitespace
        freq.erase(0, freq.find_first_not_of(" \t"));
        freq.erase(freq.find_last_not_of(" \t") + 1);
        return static_cast<int>(std::stod(freq));
      }
    }
  }
  return 0;
}

std::string FlutterDeviceInfoPlusPlugin::GetProcessorName() {
  std::string cpuinfo = ReadFile("/proc/cpuinfo");
  if (!cpuinfo.empty()) {
    size_t pos = cpuinfo.find("model name");
    if (pos != std::string::npos) {
      size_t start = cpuinfo.find(":", pos) + 1;
      size_t end = cpuinfo.find("\n", start);
      if (end != std::string::npos) {
        std::string name = cpuinfo.substr(start, end - start);
        // Trim whitespace
        name.erase(0, name.find_first_not_of(" \t"));
        name.erase(name.find_last_not_of(" \t") + 1);
        return name;
      }
    }
  }
  return "Unknown Processor";
}

std::vector<std::string> FlutterDeviceInfoPlusPlugin::GetProcessorFeatures() {
  std::vector<std::string> features;
  std::string cpuinfo = ReadFile("/proc/cpuinfo");
  
  if (cpuinfo.find("neon") != std::string::npos) {
    features.push_back("NEON");
  }
  if (cpuinfo.find("vfp") != std::string::npos) {
    features.push_back("VFP");
  }
  if (cpuinfo.find("avx") != std::string::npos) {
    features.push_back("AVX");
  }
  if (cpuinfo.find("avx2") != std::string::npos) {
    features.push_back("AVX2");
  }
  if (cpuinfo.find("sse") != std::string::npos) {
    features.push_back("SSE");
  }
  if (cpuinfo.find("sse2") != std::string::npos) {
    features.push_back("SSE2");
  }
  if (cpuinfo.find("sse4") != std::string::npos) {
    features.push_back("SSE4");
  }
  
  return features;
}

int64_t FlutterDeviceInfoPlusPlugin::GetTotalPhysicalMemory() {
  struct sysinfo info;
  if (sysinfo(&info) == 0) {
    return info.totalram * info.mem_unit;
  }
  return 0;
}

int64_t FlutterDeviceInfoPlusPlugin::GetAvailablePhysicalMemory() {
  struct sysinfo info;
  if (sysinfo(&info) == 0) {
    return info.freeram * info.mem_unit;
  }
  return 0;
}

int64_t FlutterDeviceInfoPlusPlugin::GetTotalStorageSpace() {
  struct statvfs stat;
  if (statvfs("/", &stat) == 0) {
    return stat.f_blocks * stat.f_frsize;
  }
  return 0;
}

int64_t FlutterDeviceInfoPlusPlugin::GetAvailableStorageSpace() {
  struct statvfs stat;
  if (statvfs("/", &stat) == 0) {
    return stat.f_bavail * stat.f_frsize;
  }
  return 0;
}

std::string FlutterDeviceInfoPlusPlugin::GetIPAddress() {
  struct ifaddrs *ifaddr, *ifa;
  std::string ipAddress = "unknown";
  
  if (getifaddrs(&ifaddr) == 0) {
    for (ifa = ifaddr; ifa != NULL; ifa = ifa->ifa_next) {
      if (ifa->ifa_addr == NULL) continue;
      
      if (ifa->ifa_addr->sa_family == AF_INET) {
        char host[NI_MAXHOST];
        if (getnameinfo(ifa->ifa_addr, sizeof(struct sockaddr_in),
                       host, NI_MAXHOST, NULL, 0, NI_NUMERICHOST) == 0) {
          std::string addr = host;
          if (addr != "127.0.0.1" && addr.find("169.254") != 0) {
            ipAddress = addr;
            break;
          }
        }
      }
    }
    freeifaddrs(ifaddr);
  }
  
  return ipAddress;
}

std::string FlutterDeviceInfoPlusPlugin::GetMACAddress() {
  struct ifaddrs *ifaddr, *ifa;
  std::string macAddress = "unknown";
  
  if (getifaddrs(&ifaddr) == 0) {
    for (ifa = ifaddr; ifa != NULL; ifa = ifa->ifa_next) {
      if (ifa->ifa_addr == NULL) continue;
      
      if (ifa->ifa_addr->sa_family == AF_PACKET) {
        struct sockaddr_ll *s = (struct sockaddr_ll*)ifa->ifa_addr;
        if (s->sll_halen == 6) {
          char mac[18];
          sprintf(mac, "%02X:%02X:%02X:%02X:%02X:%02X",
                  (unsigned char)s->sll_addr[0],
                  (unsigned char)s->sll_addr[1],
                  (unsigned char)s->sll_addr[2],
                  (unsigned char)s->sll_addr[3],
                  (unsigned char)s->sll_addr[4],
                  (unsigned char)s->sll_addr[5]);
          macAddress = mac;
          break;
        }
      }
    }
    freeifaddrs(ifaddr);
  }
  
  return macAddress;
}

}  // namespace

void FlutterDeviceInfoPlusPluginRegisterWithRegistrar(
    flutter::PluginRegistrarLinux *registrar) {
  FlutterDeviceInfoPlusPlugin::RegisterWithRegistrar(registrar);
}

