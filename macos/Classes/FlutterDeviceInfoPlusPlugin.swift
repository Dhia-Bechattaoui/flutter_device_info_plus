import Cocoa
import FlutterMacOS
import IOKit
import SystemConfiguration
import CoreWLAN
import Network
import LocalAuthentication
import Darwin

public class FlutterDeviceInfoPlusPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_device_info_plus", binaryMessenger: registrar.messenger)
    let instance = FlutterDeviceInfoPlusPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("macOS " + ProcessInfo.processInfo.operatingSystemVersionString)
    case "getDeviceInfo":
      result(getDeviceInfo())
    case "getBatteryInfo":
      result(getBatteryInfo())
    case "getSensorInfo":
      result(getSensorInfo())
    case "getNetworkInfo":
      getNetworkInfo { networkInfo in
        result(networkInfo)
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  private func getDeviceInfo() -> [String: Any] {
    let processInfo = ProcessInfo.processInfo
    let screen = NSScreen.main ?? NSScreen.screens.first ?? NSScreen()
    let frame = screen.frame
    
    var processorInfo = getProcessorInfo()
    var memoryInfo = getMemoryInfo()
    var displayInfo = getDisplayInfo()
    var securityInfo = getSecurityInfo()
    
    return [
      "deviceName": Host.current().localizedName ?? "Mac",
      "manufacturer": "Apple",
      "model": getModelIdentifier(),
      "brand": "Apple",
      "operatingSystem": "macOS",
      "systemVersion": processInfo.operatingSystemVersionString,
      "buildNumber": getBuildNumber(),
      "kernelVersion": getKernelVersion(),
      "processorInfo": processorInfo,
      "memoryInfo": memoryInfo,
      "displayInfo": displayInfo,
      "securityInfo": securityInfo
    ]
  }
  
  private func getModelIdentifier() -> String {
    var systemInfo = utsname()
    uname(&systemInfo)
    let machineMirror = Mirror(reflecting: systemInfo.machine)
    let identifier = machineMirror.children.reduce("") { identifier, element in
      guard let value = element.value as? Int8, value != 0 else { return identifier }
      return identifier + String(UnicodeScalar(UInt8(value))!)
    }
    return identifier
  }
  
  private func getBuildNumber() -> String {
    let processInfo = ProcessInfo.processInfo
    return processInfo.operatingSystemVersionString
  }
  
  private func getKernelVersion() -> String {
    var systemInfo = utsname()
    uname(&systemInfo)
    let release = withUnsafePointer(to: &systemInfo.release) {
      $0.withMemoryRebound(to: CChar.self, capacity: 1) {
        String(validatingUTF8: $0) ?? "Unknown"
      }
    }
    return release ?? "Unknown"
  }
  
  private func getProcessorInfo() -> [String: Any] {
    var architecture = "x86_64"
    var coreCount = ProcessInfo.processInfo.processorCount
    var maxFrequency = 0
    var processorName = "Intel Processor"
    var features: [String] = []
    
    // Try to get CPU info from IOKit
    let service = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
    if service != 0 {
      if let modelData = IORegistryEntryCreateCFProperty(service, "model" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? Data {
        if let modelString = String(data: modelData, encoding: .utf8) {
          processorName = modelString.trimmingCharacters(in: .whitespacesAndNewlines)
        }
      }
      IOObjectRelease(service)
    }
    
    // Detect architecture
    var systemInfo = utsname()
    uname(&systemInfo)
    let machineMirror = Mirror(reflecting: systemInfo.machine)
    let identifier = machineMirror.children.reduce("") { identifier, element in
      guard let value = element.value as? Int8, value != 0 else { return identifier }
      return identifier + String(UnicodeScalar(UInt8(value))!)
    }
    
    if identifier.contains("arm64") || identifier.contains("arm") {
      architecture = "arm64"
      processorName = "Apple Silicon"
      maxFrequency = 3200
      features = ["ARMv8", "NEON", "Apple Neural Engine"]
    } else {
      architecture = "x86_64"
      maxFrequency = 3600
      features = ["AVX", "AVX2", "SSE4"]
    }
    
    return [
      "architecture": architecture,
      "coreCount": coreCount,
      "maxFrequency": maxFrequency,
      "processorName": processorName,
      "features": features
    ]
  }
  
  private func getMemoryInfo() -> [String: Any] {
    let totalMemory = ProcessInfo.processInfo.physicalMemory
    
    // Get available memory
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
    
    let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
      $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
        task_info(mach_task_self_,
                  task_flavor_t(MACH_TASK_BASIC_INFO),
                  $0,
                  &count)
      }
    }
    
    var availableMemory: UInt64 = 0
    if kerr == KERN_SUCCESS {
      availableMemory = totalMemory - info.resident_size
    } else {
      availableMemory = totalMemory / 2
    }
    
    // Get storage info
    let fileManager = FileManager.default
    var totalStorage: Int64 = 0
    var availableStorage: Int64 = 0
    
    if let attributes = try? fileManager.attributesOfFileSystem(forPath: NSHomeDirectory()) {
      if let totalSize = attributes[.systemSize] as? NSNumber {
        totalStorage = totalSize.int64Value
      }
      if let freeSize = attributes[.systemFreeSize] as? NSNumber {
        availableStorage = freeSize.int64Value
      }
    }
    
    let usedStorage = totalStorage - availableStorage
    let memoryUsagePercentage = Double(totalMemory - availableMemory) / Double(totalMemory) * 100.0
    
    return [
      "totalPhysicalMemory": totalMemory,
      "availablePhysicalMemory": availableMemory,
      "totalStorageSpace": totalStorage,
      "availableStorageSpace": availableStorage,
      "usedStorageSpace": usedStorage,
      "memoryUsagePercentage": memoryUsagePercentage
    ]
  }
  
  private func getDisplayInfo() -> [String: Any] {
    let screen = NSScreen.main ?? NSScreen.screens.first ?? NSScreen()
    let frame = screen.frame
    let scale = screen.backingScaleFactor
    
    // Get refresh rate (default to 60Hz for macOS)
    let refreshRate: Double = 60.0
    
    // Calculate screen size in inches (approximate)
    let widthInches = Double(frame.width) / scale / 72.0
    let heightInches = Double(frame.height) / scale / 72.0
    let screenSizeInches = sqrt(widthInches * widthInches + heightInches * heightInches)
    
    // Check HDR support
    let isHdr = screen.colorSpace?.name == NSColorSpaceName.displayP3
    
    let orientation = frame.width > frame.height ? "landscape" : "portrait"
    
    return [
      "screenWidth": Int(frame.width),
      "screenHeight": Int(frame.height),
      "pixelDensity": Double(scale),
      "refreshRate": refreshRate,
      "screenSizeInches": screenSizeInches,
      "orientation": orientation,
      "isHdr": isHdr
    ]
  }
  
  private func getBatteryInfo() -> [String: Any]? {
    // macOS battery info (for laptops)
    let powerSource = IOPSCopyPowerSourcesInfo().takeRetainedValue()
    let powerSourcesList = IOPSCopyPowerSourcesList(powerSource).takeRetainedValue() as [CFTypeRef]
    
    if powerSourcesList.isEmpty {
      return nil // Desktop Mac, no battery
    }
    
    if let powerSource = powerSourcesList.first,
       let description = IOPSGetPowerSourceDescription(powerSource, powerSource).takeUnretainedValue() as? [String: Any] {
      
      let currentCapacity = description[kIOPSCurrentCapacityKey] as? Int ?? 0
      let maxCapacity = description[kIOPSMaxCapacityKey] as? Int ?? 100
      let batteryLevel = maxCapacity > 0 ? (currentCapacity * 100 / maxCapacity) : 0
      
      let isCharging = description[kIOPSPowerSourceStateKey] as? String == kIOPSACPowerValue
      let chargingStatus = isCharging ? "charging" : "discharging"
      
      return [
        "batteryLevel": batteryLevel,
        "chargingStatus": chargingStatus,
        "batteryHealth": "good",
        "batteryCapacity": maxCapacity,
        "batteryVoltage": 0.0,
        "batteryTemperature": 0.0
      ]
    }
    
    return nil
  }
  
  private func getSensorInfo() -> [String: Any] {
    var availableSensors: [String] = []
    
    // Check for Touch ID
    let context = LAContext()
    var error: NSError?
    if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
      if #available(macOS 10.12.2, *) {
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
          availableSensors.append("fingerprint")
        }
      }
    }
    
    return ["availableSensors": availableSensors]
  }
  
  private func getNetworkInfo(completion: @escaping ([String: Any]) -> Void) {
    var networkInfo: [String: Any] = [
      "connectionType": "none",
      "networkSpeed": "Unknown",
      "isConnected": false,
      "ipAddress": "unknown",
      "macAddress": "unknown"
    ]
    
    if #available(macOS 10.14, *) {
      let monitor = NWPathMonitor()
      let queue = DispatchQueue(label: "NetworkMonitor")
      
      monitor.pathUpdateHandler = { path in
        var connectionType = "none"
        var isConnected = path.status == .satisfied
        
        if path.usesInterfaceType(.wifi) {
          connectionType = "wifi"
          networkInfo["networkSpeed"] = "WiFi"
        } else if path.usesInterfaceType(.cellular) {
          connectionType = "mobile"
          networkInfo["networkSpeed"] = "Cellular"
        } else if path.usesInterfaceType(.wiredEthernet) {
          connectionType = "ethernet"
          networkInfo["networkSpeed"] = "Ethernet"
        }
        
        networkInfo["connectionType"] = connectionType
        networkInfo["isConnected"] = isConnected
        
        self.getIPAddress { ipAddress in
          networkInfo["ipAddress"] = ipAddress ?? "unknown"
          self.getMACAddress { macAddress in
            networkInfo["macAddress"] = macAddress ?? "unknown"
            completion(networkInfo)
          }
        }
      }
      
      monitor.start(queue: queue)
    } else {
      completion(networkInfo)
    }
  }
  
  private func getIPAddress(completion: @escaping (String?) -> Void) {
    var address: String?
    var ifaddr: UnsafeMutablePointer<ifaddrs>?
    
    guard getifaddrs(&ifaddr) == 0 else {
      completion(nil)
      return
    }
    
    var ptr = ifaddr
    while ptr != nil {
      defer { ptr = ptr?.pointee.ifa_next }
      
      let interface = ptr?.pointee
      let addrFamily = interface?.ifa_addr.pointee.sa_family
      
      if addrFamily == UInt8(AF_INET) {
        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        getnameinfo(interface?.ifa_addr,
                    socklen_t(interface?.ifa_addr.pointee.sa_len),
                    &hostname,
                    socklen_t(hostname.count),
                    nil,
                    socklen_t(0),
                    NI_NUMERICHOST)
        address = String(cString: hostname)
        
        if address != "127.0.0.1" {
          break
        }
      }
    }
    
    freeifaddrs(ifaddr)
    completion(address)
  }
  
  private func getMACAddress(completion: @escaping (String?) -> Void) {
    var address: String?
    var ifaddr: UnsafeMutablePointer<ifaddrs>?
    
    guard getifaddrs(&ifaddr) == 0 else {
      completion(nil)
      return
    }
    
    var ptr = ifaddr
    while ptr != nil {
      defer { ptr = ptr?.pointee.ifa_next }
      
      let interface = ptr?.pointee
      if let addr = interface?.ifa_addr,
         addr.pointee.sa_family == UInt8(AF_LINK),
         let data = interface?.ifa_data {
        let ptr = unsafeBitCast(data, to: UnsafeMutablePointer<sockaddr_dl>.self)
        let len = Int(ptr.pointee.sdl_alen)
        if len == 6 {
          let macBytes = withUnsafePointer(to: &ptr.pointee.sdl_data) {
            $0.withMemoryRebound(to: UInt8.self, capacity: 6) {
              Array(UnsafeBufferPointer(start: $0.advanced(by: Int(ptr.pointee.sdl_nlen)), count: 6))
            }
          }
          address = macBytes.map { String(format: "%02X", $0) }.joined(separator: ":")
          break
        }
      }
    }
    
    freeifaddrs(ifaddr)
    completion(address)
  }
  
  private func getSecurityInfo() -> [String: Any] {
    let context = LAContext()
    var error: NSError?
    let hasBiometrics = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    
    var hasFingerprint = false
    if hasBiometrics {
      hasFingerprint = true
    }
    
    let hasPasscode = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    
    return [
      "isDeviceSecure": hasPasscode,
      "hasFingerprint": hasFingerprint,
      "hasFaceUnlock": false,
      "screenLockEnabled": hasPasscode,
      "encryptionStatus": "encrypted" // macOS FileVault
    ]
  }
}
