import Flutter
import UIKit
import CoreMotion
import SystemConfiguration.CaptiveNetwork
import Network
import LocalAuthentication
import Darwin

@available(iOS 12.0, *)
public class FlutterDeviceInfoPlusPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_device_info_plus", binaryMessenger: registrar.messenger())
    let instance = FlutterDeviceInfoPlusPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
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
    let device = UIDevice.current
    let screen = UIScreen.main
    let bounds = screen.bounds
    let scale = screen.scale
    
    // Get processor info
    var processorInfo = getProcessorInfo()
    
    // Get memory info
    var memoryInfo = getMemoryInfo()
    
    // Get display info
    var displayInfo = getDisplayInfo()
    
    // Get security info
    var securityInfo = getSecurityInfo()
    
    return [
      "deviceName": device.name,
      "manufacturer": "Apple",
      "model": getDeviceModel(),
      "brand": "Apple",
      "operatingSystem": "iOS",
      "systemVersion": device.systemVersion,
      "buildNumber": getBuildNumber(),
      "kernelVersion": getKernelVersion(),
      "processorInfo": processorInfo,
      "memoryInfo": memoryInfo,
      "displayInfo": displayInfo,
      "securityInfo": securityInfo
    ]
  }
  
  private func getDeviceModel() -> String {
    var systemInfo = utsname()
    uname(&systemInfo)
    let machineMirror = Mirror(reflecting: systemInfo.machine)
    let identifier = machineMirror.children.reduce("") { identifier, element in
      guard let value = element.value as? Int8, value != 0 else { return identifier }
      return identifier + String(UnicodeScalar(UInt8(value))!)
    }
    
    // Map identifier to readable name
    let modelMap: [String: String] = [
      "iPhone14,7": "iPhone 13 mini",
      "iPhone14,8": "iPhone 13",
      "iPhone14,2": "iPhone 13 Pro",
      "iPhone14,3": "iPhone 13 Pro Max",
      "iPhone15,2": "iPhone 14",
      "iPhone15,3": "iPhone 14 Pro",
      "iPhone15,4": "iPhone 14 Plus",
      "iPhone15,5": "iPhone 14 Pro Max",
      "iPhone16,1": "iPhone 15",
      "iPhone16,2": "iPhone 15 Plus",
      "iPhone16,3": "iPhone 15 Pro",
      "iPhone16,4": "iPhone 15 Pro Max",
      "iPad13,1": "iPad Air (4th generation)",
      "iPad13,2": "iPad Air (4th generation)",
      "iPad13,16": "iPad Air (5th generation)",
      "iPad13,17": "iPad Air (5th generation)",
      "iPad14,1": "iPad mini (6th generation)",
      "iPad14,2": "iPad mini (6th generation)",
      "i386": "iPhone Simulator",
      "x86_64": "iPhone Simulator",
      "arm64": "iPhone Simulator"
    ]
    
    return modelMap[identifier] ?? identifier
  }
  
  private func getBuildNumber() -> String {
    if let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
      return buildNumber
    }
    return UIDevice.current.systemVersion
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
    var architecture = "arm64"
    var coreCount = ProcessInfo.processInfo.processorCount
    var maxFrequency = 0
    var processorName = "Apple Silicon"
    var features: [String] = []
    
    // Try to get more specific info
    var systemInfo = utsname()
    uname(&systemInfo)
    let machineMirror = Mirror(reflecting: systemInfo.machine)
    let identifier = machineMirror.children.reduce("") { identifier, element in
      guard let value = element.value as? Int8, value != 0 else { return identifier }
      return identifier + String(UnicodeScalar(UInt8(value))!)
    }
    
    // Detect processor based on device identifier
    if identifier.contains("iPhone") || identifier.contains("iPad") {
      if identifier.contains("iPhone15") || identifier.contains("iPhone16") {
        processorName = "Apple A17 Pro"
        maxFrequency = 3780
      } else if identifier.contains("iPhone14") {
        processorName = "Apple A15 Bionic"
        maxFrequency = 3230
      } else {
        processorName = "Apple A-series"
        maxFrequency = 3000
      }
      features = ["ARMv8", "NEON", "Apple Neural Engine"]
    } else {
      processorName = "Apple Silicon"
      maxFrequency = 3200
      features = ["ARMv8", "NEON"]
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
    
    // Get available memory (approximate)
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
      availableMemory = totalMemory / 2 // Fallback estimate
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
    let screen = UIScreen.main
    let bounds = screen.bounds
    let scale = screen.scale
    let nativeBounds = screen.nativeBounds
    
    // Get refresh rate (available on iOS 10.3+)
    var refreshRate: Double = 60.0
    if #available(iOS 10.3, *) {
      refreshRate = screen.maximumFramesPerSecond > 0 ? Double(screen.maximumFramesPerSecond) : 60.0
    }
    
    // Calculate screen size in inches (approximate)
    let widthInches = Double(nativeBounds.width) / Double(scale) / 163.0
    let heightInches = Double(nativeBounds.height) / Double(scale) / 163.0
    let screenSizeInches = sqrt(widthInches * widthInches + heightInches * heightInches)
    
    // Check HDR support
    var isHdr = false
    if #available(iOS 10.0, *) {
      isHdr = screen.traitCollection.displayGamut == .P3
    }
    
    let orientation = bounds.width > bounds.height ? "landscape" : "portrait"
    
    return [
      "screenWidth": Int(nativeBounds.width),
      "screenHeight": Int(nativeBounds.height),
      "pixelDensity": Double(scale),
      "refreshRate": refreshRate,
      "screenSizeInches": screenSizeInches,
      "orientation": orientation,
      "isHdr": isHdr
    ]
  }
  
  private func getBatteryInfo() -> [String: Any]? {
    UIDevice.current.isBatteryMonitoringEnabled = true
    
    let batteryLevel = Int(UIDevice.current.batteryLevel * 100)
    let batteryState = UIDevice.current.batteryState
    
    var chargingStatus = "unknown"
    switch batteryState {
    case .charging:
      chargingStatus = "charging"
    case .full:
      chargingStatus = "full"
    case .unplugged:
      chargingStatus = "discharging"
    default:
      chargingStatus = "unknown"
    }
    
    // Battery health is not directly available on iOS
    let batteryHealth = "unknown"
    
    // Battery capacity, voltage, and temperature are not available on iOS
    return [
      "batteryLevel": batteryLevel,
      "chargingStatus": chargingStatus,
      "batteryHealth": batteryHealth,
      "batteryCapacity": 0,
      "batteryVoltage": 0.0,
      "batteryTemperature": 0.0
    ]
  }
  
  private func getSensorInfo() -> [String: Any] {
    let motionManager = CMMotionManager()
    var availableSensors: [String] = []
    
    if motionManager.isAccelerometerAvailable {
      availableSensors.append("accelerometer")
    }
    if motionManager.isGyroAvailable {
      availableSensors.append("gyroscope")
    }
    if motionManager.isMagnetometerAvailable {
      availableSensors.append("magnetometer")
    }
    if motionManager.isDeviceMotionAvailable {
      availableSensors.append("gravity")
      availableSensors.append("rotationVector")
    }
    
    // Check for biometric sensors
    let context = LAContext()
    var error: NSError?
    if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
      if #available(iOS 11.0, *) {
        switch context.biometryType {
        case .faceID:
          availableSensors.append("faceRecognition")
        case .touchID:
          availableSensors.append("fingerprint")
        default:
          break
        }
      } else {
        availableSensors.append("fingerprint")
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
    
    if #available(iOS 12.0, *) {
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
        
        // Get IP address
        self.getIPAddress { ipAddress in
          networkInfo["ipAddress"] = ipAddress ?? "unknown"
          completion(networkInfo)
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
  
  private func getSecurityInfo() -> [String: Any] {
    let context = LAContext()
    var error: NSError?
    let hasBiometrics = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    
    var hasFingerprint = false
    var hasFaceUnlock = false
    
    if hasBiometrics {
      if #available(iOS 11.0, *) {
        switch context.biometryType {
        case .faceID:
          hasFaceUnlock = true
        case .touchID:
          hasFingerprint = true
        default:
          break
        }
      } else {
        hasFingerprint = true
      }
    }
    
    // Check if device has passcode
    let hasPasscode = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    
    return [
      "isDeviceSecure": hasPasscode,
      "hasFingerprint": hasFingerprint,
      "hasFaceUnlock": hasFaceUnlock,
      "screenLockEnabled": hasPasscode,
      "encryptionStatus": "encrypted" // iOS devices are always encrypted
    ]
  }
}
