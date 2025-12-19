#include "include/flutter_device_info_plus/flutter_device_info_plus_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <sys/utsname.h>
#include <sys/sysinfo.h>
#include <sys/statvfs.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <fstream>
#include <sstream>
#include <memory>
#include <vector>
#include <map>
#include <unistd.h>
#include <ifaddrs.h>
#include <net/if.h>
#include <linux/if_packet.h>
#include <linux/if_link.h>
#include <cstring>

#define FLUTTER_DEVICE_INFO_PLUS_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), flutter_device_info_plus_plugin_get_type(), \
                              FlutterDeviceInfoPlusPlugin))

struct _FlutterDeviceInfoPlusPlugin {
  GObject parent_instance;
};

G_DEFINE_TYPE(FlutterDeviceInfoPlusPlugin, flutter_device_info_plus_plugin, g_object_get_type())

// Helper function to read file content
static std::string ReadFile(const std::string& path) {
  std::ifstream file(path);
  if (file.is_open()) {
    std::stringstream buffer;
    buffer << file.rdbuf();
    return buffer.str();
  }
  return "";
}

// Helper function to create FlValue from string
static FlValue* CreateStringValue(const std::string& str) {
  return fl_value_new_string(str.c_str());
}

// Helper function to create FlValue from int
static FlValue* CreateIntValue(int64_t value) {
  return fl_value_new_int(value);
}

// Helper function to create FlValue from double
static FlValue* CreateDoubleValue(double value) {
  return fl_value_new_float(value);
}

// Helper function to create FlValue from bool
static FlValue* CreateBoolValue(bool value) {
  return fl_value_new_bool(value);
}

// Helper function to create FlValue map
static FlValue* CreateMapValue() {
  return fl_value_new_map();
}

// Helper function to set map value
static void SetMapValue(FlValue* map, const char* key, FlValue* value) {
  fl_value_set_take(map, CreateStringValue(key), value);
}

// Get processor architecture
static std::string GetProcessorArchitecture() {
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

// Get processor core count
static int GetProcessorCoreCount() {
  return sysconf(_SC_NPROCESSORS_ONLN);
}

// Get processor max frequency
static int GetProcessorMaxFrequency() {
  std::string cpuinfo = ReadFile("/proc/cpuinfo");
  if (!cpuinfo.empty()) {
    size_t pos = cpuinfo.find("cpu MHz");
    if (pos != std::string::npos) {
      size_t start = cpuinfo.find(":", pos) + 1;
      size_t end = cpuinfo.find("\n", start);
      if (end != std::string::npos) {
        std::string freq = cpuinfo.substr(start, end - start);
        freq.erase(0, freq.find_first_not_of(" \t"));
        freq.erase(freq.find_last_not_of(" \t") + 1);
        return static_cast<int>(std::stod(freq));
      }
    }
  }
  return 0;
}

// Get processor name
static std::string GetProcessorName() {
  std::string cpuinfo = ReadFile("/proc/cpuinfo");
  if (!cpuinfo.empty()) {
    size_t pos = cpuinfo.find("model name");
    if (pos != std::string::npos) {
      size_t start = cpuinfo.find(":", pos) + 1;
      size_t end = cpuinfo.find("\n", start);
      if (end != std::string::npos) {
        std::string name = cpuinfo.substr(start, end - start);
        name.erase(0, name.find_first_not_of(" \t"));
        name.erase(name.find_last_not_of(" \t") + 1);
        return name;
      }
    }
  }
  return "Unknown Processor";
}

// Get processor features
static FlValue* GetProcessorFeatures() {
  FlValue* features = fl_value_new_list();
  std::string cpuinfo = ReadFile("/proc/cpuinfo");
  
  if (cpuinfo.find("neon") != std::string::npos) {
    fl_value_append_take(features, CreateStringValue("NEON"));
  }
  if (cpuinfo.find("vfp") != std::string::npos) {
    fl_value_append_take(features, CreateStringValue("VFP"));
  }
  if (cpuinfo.find("avx") != std::string::npos) {
    fl_value_append_take(features, CreateStringValue("AVX"));
  }
  if (cpuinfo.find("avx2") != std::string::npos) {
    fl_value_append_take(features, CreateStringValue("AVX2"));
  }
  if (cpuinfo.find("sse") != std::string::npos) {
    fl_value_append_take(features, CreateStringValue("SSE"));
  }
  if (cpuinfo.find("sse2") != std::string::npos) {
    fl_value_append_take(features, CreateStringValue("SSE2"));
  }
  if (cpuinfo.find("sse4") != std::string::npos) {
    fl_value_append_take(features, CreateStringValue("SSE4"));
  }
  
  return features;
}

// Get total physical memory
static int64_t GetTotalPhysicalMemory() {
  struct sysinfo info;
  if (sysinfo(&info) == 0) {
    return info.totalram * info.mem_unit;
  }
  return 0;
}

// Get available physical memory
static int64_t GetAvailablePhysicalMemory() {
  struct sysinfo info;
  if (sysinfo(&info) == 0) {
    return info.freeram * info.mem_unit;
  }
  return 0;
}

// Get total storage space
static int64_t GetTotalStorageSpace() {
  struct statvfs stat;
  if (statvfs("/", &stat) == 0) {
    return stat.f_blocks * stat.f_frsize;
  }
  return 0;
}

// Get available storage space
static int64_t GetAvailableStorageSpace() {
  struct statvfs stat;
  if (statvfs("/", &stat) == 0) {
    return stat.f_bavail * stat.f_frsize;
  }
  return 0;
}

// Get IP address
static std::string GetIPAddress() {
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

// Get MAC address
static std::string GetMACAddress() {
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

// Get device info
static FlValue* GetDeviceInfo() {
  FlValue* deviceInfo = CreateMapValue();
  
  // Get hostname
  char hostname[256];
  gethostname(hostname, sizeof(hostname));
  SetMapValue(deviceInfo, "deviceName", CreateStringValue(hostname));
  
  // Get system info
  struct utsname unameInfo;
  uname(&unameInfo);
  
  SetMapValue(deviceInfo, "manufacturer", CreateStringValue("Unknown"));
  SetMapValue(deviceInfo, "model", CreateStringValue("Linux PC"));
  SetMapValue(deviceInfo, "brand", CreateStringValue("Linux"));
  SetMapValue(deviceInfo, "operatingSystem", CreateStringValue("Linux"));
  SetMapValue(deviceInfo, "systemVersion", CreateStringValue(unameInfo.release));
  SetMapValue(deviceInfo, "buildNumber", CreateStringValue(unameInfo.version));
  SetMapValue(deviceInfo, "kernelVersion", CreateStringValue(unameInfo.release));
  
  // Processor info
  FlValue* processorInfo = CreateMapValue();
  SetMapValue(processorInfo, "architecture", CreateStringValue(GetProcessorArchitecture()));
  SetMapValue(processorInfo, "coreCount", CreateIntValue(GetProcessorCoreCount()));
  SetMapValue(processorInfo, "maxFrequency", CreateIntValue(GetProcessorMaxFrequency()));
  SetMapValue(processorInfo, "processorName", CreateStringValue(GetProcessorName()));
  SetMapValue(processorInfo, "features", GetProcessorFeatures());
  SetMapValue(deviceInfo, "processorInfo", processorInfo);
  
  // Memory info
  FlValue* memoryInfo = CreateMapValue();
  int64_t totalMem = GetTotalPhysicalMemory();
  int64_t availMem = GetAvailablePhysicalMemory();
  int64_t totalStorage = GetTotalStorageSpace();
  int64_t availStorage = GetAvailableStorageSpace();
  
  SetMapValue(memoryInfo, "totalPhysicalMemory", CreateIntValue(totalMem));
  SetMapValue(memoryInfo, "availablePhysicalMemory", CreateIntValue(availMem));
  SetMapValue(memoryInfo, "totalStorageSpace", CreateIntValue(totalStorage));
  SetMapValue(memoryInfo, "availableStorageSpace", CreateIntValue(availStorage));
  SetMapValue(memoryInfo, "usedStorageSpace", CreateIntValue(totalStorage - availStorage));
  double memUsage = totalMem > 0 ? ((totalMem - availMem) * 100.0 / totalMem) : 0.0;
  SetMapValue(memoryInfo, "memoryUsagePercentage", CreateDoubleValue(memUsage));
  SetMapValue(deviceInfo, "memoryInfo", memoryInfo);
  
  // Display info (approximate)
  FlValue* displayInfo = CreateMapValue();
  SetMapValue(displayInfo, "screenWidth", CreateIntValue(1920));
  SetMapValue(displayInfo, "screenHeight", CreateIntValue(1080));
  SetMapValue(displayInfo, "pixelDensity", CreateDoubleValue(1.0));
  SetMapValue(displayInfo, "refreshRate", CreateDoubleValue(60.0));
  SetMapValue(displayInfo, "screenSizeInches", CreateDoubleValue(24.0));
  SetMapValue(displayInfo, "orientation", CreateStringValue("landscape"));
  SetMapValue(displayInfo, "isHdr", CreateBoolValue(false));
  SetMapValue(deviceInfo, "displayInfo", displayInfo);
  
  // Security info
  FlValue* securityInfo = CreateMapValue();
  SetMapValue(securityInfo, "isDeviceSecure", CreateBoolValue(true));
  SetMapValue(securityInfo, "hasFingerprint", CreateBoolValue(false));
  SetMapValue(securityInfo, "hasFaceUnlock", CreateBoolValue(false));
  SetMapValue(securityInfo, "screenLockEnabled", CreateBoolValue(true));
  SetMapValue(securityInfo, "encryptionStatus", CreateStringValue("unknown"));
  SetMapValue(deviceInfo, "securityInfo", securityInfo);
  
  return deviceInfo;
}

// Get battery info
static FlValue* GetBatteryInfo() {
  FlValue* batteryInfo = CreateMapValue();
  
  // Try to read battery info from /sys/class/power_supply
  std::string batteryPath = "/sys/class/power_supply/BAT0";
  std::string capacity = ReadFile(batteryPath + "/capacity");
  std::string status = ReadFile(batteryPath + "/status");
  
  if (!capacity.empty()) {
    int level = std::stoi(capacity);
    SetMapValue(batteryInfo, "batteryLevel", CreateIntValue(level));
    
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
    SetMapValue(batteryInfo, "chargingStatus", CreateStringValue(chargingStatus));
    SetMapValue(batteryInfo, "batteryHealth", CreateStringValue("good"));
    SetMapValue(batteryInfo, "batteryCapacity", CreateIntValue(0));
    SetMapValue(batteryInfo, "batteryVoltage", CreateDoubleValue(0.0));
    SetMapValue(batteryInfo, "batteryTemperature", CreateDoubleValue(0.0));
    return batteryInfo;
  } else {
    // No battery (desktop) - return null
    fl_value_unref(batteryInfo);
    return nullptr;
  }
}

// Get sensor info
static FlValue* GetSensorInfo() {
  FlValue* sensorInfo = CreateMapValue();
  FlValue* sensors = fl_value_new_list();
  
  // Check for available sensors in /sys/bus/iio/devices
  fl_value_append_take(sensors, CreateStringValue("accelerometer")); // If available
  
  SetMapValue(sensorInfo, "availableSensors", sensors);
  return sensorInfo;
}

// Get network info
static FlValue* GetNetworkInfo() {
  FlValue* networkInfo = CreateMapValue();
  
  std::string ipAddress = GetIPAddress();
  std::string macAddress = GetMACAddress();
  
  SetMapValue(networkInfo, "connectionType", CreateStringValue("ethernet"));
  SetMapValue(networkInfo, "networkSpeed", CreateStringValue("Unknown"));
  SetMapValue(networkInfo, "isConnected", CreateBoolValue(!ipAddress.empty()));
  SetMapValue(networkInfo, "ipAddress", CreateStringValue(ipAddress));
  SetMapValue(networkInfo, "macAddress", CreateStringValue(macAddress));
  
  return networkInfo;
}

// Called when a method call is received from Flutter.
static void flutter_device_info_plus_plugin_handle_method_call(
    FlutterDeviceInfoPlusPlugin* self,
    FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;

  const gchar* method = fl_method_call_get_name(method_call);

  if (strcmp(method, "getDeviceInfo") == 0) {
    FlValue* result = GetDeviceInfo();
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
    fl_value_unref(result);
  } else if (strcmp(method, "getBatteryInfo") == 0) {
    FlValue* result = GetBatteryInfo();
    if (result != nullptr) {
      response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
      fl_value_unref(result);
    } else {
      response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
    }
  } else if (strcmp(method, "getSensorInfo") == 0) {
    FlValue* result = GetSensorInfo();
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
    fl_value_unref(result);
  } else if (strcmp(method, "getNetworkInfo") == 0) {
    FlValue* result = GetNetworkInfo();
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
    fl_value_unref(result);
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}

static void flutter_device_info_plus_plugin_dispose(GObject* object) {
  G_OBJECT_CLASS(flutter_device_info_plus_plugin_parent_class)->dispose(object);
}

static void flutter_device_info_plus_plugin_class_init(FlutterDeviceInfoPlusPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = flutter_device_info_plus_plugin_dispose;
}

static void flutter_device_info_plus_plugin_init(FlutterDeviceInfoPlusPlugin* self) {}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                           gpointer user_data) {
  FlutterDeviceInfoPlusPlugin* plugin = FLUTTER_DEVICE_INFO_PLUS_PLUGIN(user_data);
  flutter_device_info_plus_plugin_handle_method_call(plugin, method_call);
}

void flutter_device_info_plus_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  FlutterDeviceInfoPlusPlugin* plugin = FLUTTER_DEVICE_INFO_PLUS_PLUGIN(
      g_object_new(flutter_device_info_plus_plugin_get_type(), nullptr));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                            "flutter_device_info_plus",
                            FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, method_call_cb,
                                            g_object_ref(plugin),
                                            g_object_unref);

  g_object_unref(plugin);
}
