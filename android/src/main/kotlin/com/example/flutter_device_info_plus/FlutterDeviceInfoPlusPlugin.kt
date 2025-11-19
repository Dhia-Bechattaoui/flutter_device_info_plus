package com.example.flutter_device_info_plus

import android.app.ActivityManager
import android.app.KeyguardManager
import android.content.Context
import android.content.pm.PackageManager
import android.hardware.Sensor
import android.hardware.SensorManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.wifi.WifiInfo
import android.net.wifi.WifiManager
import android.os.BatteryManager
import android.os.Build
import android.os.Environment
import android.os.StatFs
import android.provider.Settings
import android.util.DisplayMetrics
import android.view.WindowManager
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileReader
import java.net.NetworkInterface
import java.util.*

class FlutterDeviceInfoPlusPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_device_info_plus")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
        when (call.method) {
            "getDeviceInfo" -> {
                try {
                    result.success(getDeviceInfo())
                } catch (e: Exception) {
                    result.error("ERROR", "Failed to get device info: ${e.message}", null)
                }
            }
            "getBatteryInfo" -> {
                try {
                    result.success(getBatteryInfo())
                } catch (e: Exception) {
                    result.error("ERROR", "Failed to get battery info: ${e.message}", null)
                }
            }
            "getSensorInfo" -> {
                try {
                    result.success(getSensorInfo())
                } catch (e: Exception) {
                    result.error("ERROR", "Failed to get sensor info: ${e.message}", null)
                }
            }
            "getNetworkInfo" -> {
                try {
                    result.success(getNetworkInfo())
                } catch (e: Exception) {
                    result.error("ERROR", "Failed to get network info: ${e.message}", null)
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun getDeviceInfo(): Map<String, Any?> {
        val windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
        val displayMetrics = DisplayMetrics()
        windowManager.defaultDisplay.getMetrics(displayMetrics)
        windowManager.defaultDisplay.getRealMetrics(displayMetrics)

        val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val memInfo = ActivityManager.MemoryInfo()
        activityManager.getMemoryInfo(memInfo)

        val statFs = StatFs(Environment.getDataDirectory().path)
        val totalStorage = statFs.blockCountLong * statFs.blockSizeLong
        val availableStorage = statFs.availableBlocksLong * statFs.blockSizeLong
        val usedStorage = totalStorage - availableStorage

        // Get CPU info
        val cpuInfo = getCpuInfo()

        return mapOf(
            "deviceName" to Build.MODEL,
            "manufacturer" to Build.MANUFACTURER,
            "model" to Build.MODEL,
            "brand" to Build.BRAND,
            "operatingSystem" to "Android",
            "systemVersion" to Build.VERSION.RELEASE,
            "buildNumber" to Build.ID,
            "kernelVersion" to (System.getProperty("os.version") as String? ?: "Unknown"),
            "processorInfo" to cpuInfo,
            "memoryInfo" to mapOf(
                "totalPhysicalMemory" to memInfo.totalMem,
                "availablePhysicalMemory" to memInfo.availMem,
                "totalStorageSpace" to totalStorage,
                "availableStorageSpace" to availableStorage,
                "usedStorageSpace" to usedStorage,
                "memoryUsagePercentage" to ((memInfo.totalMem - memInfo.availMem).toDouble() / memInfo.totalMem * 100)
            ),
            "displayInfo" to mapOf(
                "screenWidth" to displayMetrics.widthPixels,
                "screenHeight" to displayMetrics.heightPixels,
                "pixelDensity" to (displayMetrics.densityDpi / 160.0),
                "refreshRate" to windowManager.defaultDisplay.refreshRate.toDouble(),
                "screenSizeInches" to calculateScreenSizeInches(displayMetrics.widthPixels, displayMetrics.heightPixels, displayMetrics.densityDpi),
                "orientation" to if (displayMetrics.widthPixels > displayMetrics.heightPixels) "landscape" else "portrait",
                "isHdr" to (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N && windowManager.defaultDisplay.hdrCapabilities != null)
            ),
            "securityInfo" to getSecurityInfo()
        )
    }

    private fun getCpuInfo(): Map<String, Any?> {
        val architecture = when {
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP -> {
                Build.SUPPORTED_ABIS[0] ?: Build.CPU_ABI
            }
            else -> Build.CPU_ABI
        }

        var coreCount = Runtime.getRuntime().availableProcessors()
        var maxFrequency = 0
        var processorName = "Unknown"
        val features = mutableListOf<String>()

        try {
            // Try to read from /proc/cpuinfo
            val cpuInfoFile = File("/proc/cpuinfo")
            if (cpuInfoFile.exists()) {
                val reader = FileReader(cpuInfoFile)
                val content = reader.readText()
                reader.close()

                // Count cores
                val processorMatches = Regex("processor\\s*:").findAll(content)
                coreCount = processorMatches.count().coerceAtLeast(1)

                // Get processor name
                val processorNameMatch = Regex("Hardware\\s*:\\s*(.+)").find(content)
                if (processorNameMatch != null) {
                    processorName = processorNameMatch.groupValues[1].trim()
                } else {
                    val modelNameMatch = Regex("model name\\s*:\\s*(.+)").find(content)
                    if (modelNameMatch != null) {
                        processorName = modelNameMatch.groupValues[1].trim()
                    }
                }

                // Get max frequency - Method 1: /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq
                try {
                    val maxFreqFile = File("/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq")
                    if (maxFreqFile.exists() && maxFreqFile.canRead()) {
                        val freqKHz = maxFreqFile.readText().trim().toIntOrNull()
                        if (freqKHz != null && freqKHz > 0) {
                            maxFrequency = freqKHz / 1000 // Convert kHz to MHz
                        }
                    }
                } catch (e: Exception) {
                    // File not accessible
                }

                // Detect features from /proc/cpuinfo Features line
                val featuresMatch = Regex("Features\\s*:\\s*(.+)", RegexOption.IGNORE_CASE).find(content)
                if (featuresMatch != null) {
                    val featuresStr = featuresMatch.groupValues[1].trim().lowercase()
                    // Common ARM features
                    if (featuresStr.contains("fp")) features.add("VFP")
                    if (featuresStr.contains("asimd") || featuresStr.contains("neon")) features.add("NEON")
                    if (featuresStr.contains("aes")) features.add("AES")
                    if (featuresStr.contains("pmull")) features.add("PMULL")
                    if (featuresStr.contains("sha1")) features.add("SHA1")
                    if (featuresStr.contains("sha2")) features.add("SHA2")
                    if (featuresStr.contains("crc32")) features.add("CRC32")
                    if (featuresStr.contains("atomics")) features.add("ATOMICS")
                    if (featuresStr.contains("asimdrdm")) features.add("ASIMDRDM")
                    if (featuresStr.contains("jscvt")) features.add("JSCVT")
                    if (featuresStr.contains("fcma")) features.add("FCMA")
                    if (featuresStr.contains("lrcpc")) features.add("LRCPC")
                } else {
                    // Fallback: check for common features in content
                    if (content.contains("neon", ignoreCase = true)) features.add("NEON")
                    if (content.contains("vfp", ignoreCase = true)) features.add("VFP")
                    if (content.contains("asimd", ignoreCase = true)) features.add("ASIMD")
                }
                
                // Add architecture-specific features
                if (architecture.contains("arm64") || architecture.contains("aarch64")) {
                    if (!features.contains("ARMv8")) features.add("ARMv8")
                    if (!features.contains("AArch64")) features.add("AArch64")
                } else if (architecture.contains("arm")) {
                    if (!features.contains("ARM")) features.add("ARM")
                }
            }
        } catch (e: Exception) {
            // Fallback values
        }

        // Fallback processor name
        if (processorName == "Unknown") {
            processorName = when {
                architecture.contains("arm64") -> "ARM64 Processor"
                architecture.contains("arm") -> "ARM Processor"
                architecture.contains("x86_64") -> "x86_64 Processor"
                architecture.contains("x86") -> "x86 Processor"
                else -> "Unknown Processor"
            }
        }

        // Normalize architecture name
        val normalizedArch = when {
            architecture.contains("arm64") || architecture.contains("aarch64") -> "arm64"
            architecture.contains("armeabi-v7a") -> "armv7"
            architecture.contains("armeabi") -> "arm"
            architecture.contains("x86_64") -> "x86_64"
            architecture.contains("x86") -> "x86"
            else -> architecture
        }

        return mapOf(
            "architecture" to normalizedArch,
            "coreCount" to coreCount,
            "maxFrequency" to maxFrequency,
            "processorName" to processorName,
            "features" to features
        )
    }

    private fun getBatteryInfo(): Map<String, Any?>? {
        val batteryManager = context.getSystemService(Context.BATTERY_SERVICE) as? BatteryManager
            ?: return null

        val batteryIntent = context.registerReceiver(null, android.content.IntentFilter(android.content.Intent.ACTION_BATTERY_CHANGED))
            ?: return null

        val level = batteryIntent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
        val scale = batteryIntent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
        val batteryLevel = if (level >= 0 && scale > 0) {
            (level * 100 / scale)
        } else {
            batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
        }

        val status = batteryIntent.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
        val chargingStatus = when (status) {
            BatteryManager.BATTERY_STATUS_CHARGING -> "charging"
            BatteryManager.BATTERY_STATUS_DISCHARGING -> "discharging"
            BatteryManager.BATTERY_STATUS_FULL -> "full"
            BatteryManager.BATTERY_STATUS_NOT_CHARGING -> "not_charging"
            else -> "unknown"
        }

        val health = batteryIntent.getIntExtra(BatteryManager.EXTRA_HEALTH, -1)
        val batteryHealth = when (health) {
            BatteryManager.BATTERY_HEALTH_GOOD -> "good"
            BatteryManager.BATTERY_HEALTH_OVERHEAT -> "overheat"
            BatteryManager.BATTERY_HEALTH_DEAD -> "dead"
            BatteryManager.BATTERY_HEALTH_OVER_VOLTAGE -> "over_voltage"
            BatteryManager.BATTERY_HEALTH_UNSPECIFIED_FAILURE -> "failure"
            BatteryManager.BATTERY_HEALTH_COLD -> "cold"
            else -> "unknown"
        }

        val voltage = batteryIntent.getIntExtra(BatteryManager.EXTRA_VOLTAGE, -1) / 1000.0
        val temperature = batteryIntent.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, -1) / 10.0

        // Try to get battery capacity (mAh) - this may not be available on all devices
        var batteryCapacity = 0
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                batteryCapacity = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CHARGE_COUNTER) / 1000
            }
        } catch (e: Exception) {
            // Not available
        }

        return mapOf(
            "batteryLevel" to batteryLevel,
            "chargingStatus" to chargingStatus,
            "batteryHealth" to batteryHealth,
            "batteryCapacity" to batteryCapacity,
            "batteryVoltage" to voltage,
            "batteryTemperature" to temperature
        )
    }

    private fun getSensorInfo(): Map<String, Any?> {
        val sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as? SensorManager
            ?: return mapOf("availableSensors" to emptyList<String>())

        val availableSensors = mutableListOf<String>()

        // Check for common sensors
        if (sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER) != null) {
            availableSensors.add("accelerometer")
        }
        if (sensorManager.getDefaultSensor(Sensor.TYPE_GYROSCOPE) != null) {
            availableSensors.add("gyroscope")
        }
        if (sensorManager.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD) != null) {
            availableSensors.add("magnetometer")
        }
        if (sensorManager.getDefaultSensor(Sensor.TYPE_PROXIMITY) != null) {
            availableSensors.add("proximity")
        }
        if (sensorManager.getDefaultSensor(Sensor.TYPE_LIGHT) != null) {
            availableSensors.add("light")
        }
        if (sensorManager.getDefaultSensor(Sensor.TYPE_PRESSURE) != null) {
            availableSensors.add("barometer")
        }
        if (sensorManager.getDefaultSensor(Sensor.TYPE_AMBIENT_TEMPERATURE) != null) {
            availableSensors.add("temperature")
        }
        if (sensorManager.getDefaultSensor(Sensor.TYPE_RELATIVE_HUMIDITY) != null) {
            availableSensors.add("humidity")
        }
        if (sensorManager.getDefaultSensor(Sensor.TYPE_STEP_COUNTER) != null) {
            availableSensors.add("stepCounter")
        }
        if (sensorManager.getDefaultSensor(Sensor.TYPE_HEART_RATE) != null) {
            availableSensors.add("heartRate")
        }
        if (sensorManager.getDefaultSensor(Sensor.TYPE_GRAVITY) != null) {
            availableSensors.add("gravity")
        }
        if (sensorManager.getDefaultSensor(Sensor.TYPE_LINEAR_ACCELERATION) != null) {
            availableSensors.add("linearAcceleration")
        }
        if (sensorManager.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR) != null) {
            availableSensors.add("rotationVector")
        }

        // Check for biometric sensors
        val packageManager = context.packageManager
        if (packageManager.hasSystemFeature(PackageManager.FEATURE_FINGERPRINT)) {
            availableSensors.add("fingerprint")
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P && packageManager.hasSystemFeature(PackageManager.FEATURE_FACE)) {
            availableSensors.add("faceRecognition")
        }

        return mapOf("availableSensors" to availableSensors)
    }

    private fun getNetworkInfo(): Map<String, Any?> {
        val connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager
            ?: return getDefaultNetworkInfo()

        val network = connectivityManager.activeNetwork ?: return getDefaultNetworkInfo()
        val capabilities = connectivityManager.getNetworkCapabilities(network)
            ?: return getDefaultNetworkInfo()

        val connectionType = when {
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> "wifi"
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> "mobile"
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> "ethernet"
            else -> "none"
        }

        val isConnected = capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) &&
                capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED)

        // Get IP address
        var ipAddress = "unknown"
        try {
            val interfaces = NetworkInterface.getNetworkInterfaces()
            while (interfaces.hasMoreElements()) {
                val networkInterface = interfaces.nextElement()
                val addresses = networkInterface.inetAddresses
                while (addresses.hasMoreElements()) {
                    val address = addresses.nextElement()
                    if (!address.isLoopbackAddress && address is java.net.Inet4Address) {
                        ipAddress = address.hostAddress ?: "unknown"
                        break
                    }
                }
                if (ipAddress != "unknown") break
            }
        } catch (e: Exception) {
            // Ignore
        }

        // Get MAC address (requires location permission on Android 6.0+)
        var macAddress = "unknown"
        try {
            if (connectionType == "wifi") {
                val wifiManager = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager
                val wifiInfo: WifiInfo? = wifiManager?.connectionInfo
                macAddress = wifiInfo?.macAddress ?: "unknown"
            } else {
                val interfaces = NetworkInterface.getNetworkInterfaces()
                while (interfaces.hasMoreElements()) {
                    val networkInterface = interfaces.nextElement()
                    val hardwareAddress = networkInterface.hardwareAddress
                    if (hardwareAddress != null && hardwareAddress.isNotEmpty()) {
                        macAddress = hardwareAddress.joinToString(":") { "%02X".format(it) }
                        break
                    }
                }
            }
        } catch (e: Exception) {
            // Ignore - may require permissions
        }

        // Get network speed (approximate)
        val networkSpeed = when {
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> {
                val linkSpeed = try {
                    val wifiManager = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager
                    val wifiInfo: WifiInfo? = wifiManager?.connectionInfo
                    wifiInfo?.linkSpeed ?: 0
                } catch (e: Exception) {
                    0
                }
                if (linkSpeed > 0) "${linkSpeed} Mbps" else "WiFi"
            }
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> {
                // Check network type using link bandwidth or other available methods
                val linkDownstream = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    capabilities.linkDownstreamBandwidthKbps
                } else {
                    0
                }
                when {
                    linkDownstream > 100000 -> "5G" // Approximate 5G speeds
                    linkDownstream > 10000 -> "4G"  // Approximate 4G speeds
                    linkDownstream > 1000 -> "3G"   // Approximate 3G speeds
                    else -> "Mobile"
                }
            }
            else -> "Unknown"
        }

        return mapOf(
            "connectionType" to connectionType,
            "networkSpeed" to networkSpeed,
            "isConnected" to isConnected,
            "ipAddress" to ipAddress,
            "macAddress" to macAddress
        )
    }

    private fun getDefaultNetworkInfo(): Map<String, Any?> {
        return mapOf(
            "connectionType" to "none",
            "networkSpeed" to "Unknown",
            "isConnected" to false,
            "ipAddress" to "unknown",
            "macAddress" to "unknown"
        )
    }

    private fun getSecurityInfo(): Map<String, Any?> {
        val packageManager = context.packageManager
        val hasFingerprint = packageManager.hasSystemFeature(PackageManager.FEATURE_FINGERPRINT)
        val hasFaceUnlock = Build.VERSION.SDK_INT >= Build.VERSION_CODES.P && 
                packageManager.hasSystemFeature(PackageManager.FEATURE_FACE)

        // Check if device has screen lock enabled
        // Note: Direct access to lock screen settings requires special permissions
        // This is an approximation
        val keyguardManager = context.getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
        val isDeviceSecure = keyguardManager?.isKeyguardSecure ?: false
        val screenLockEnabled = isDeviceSecure

        val encryptionStatus = when {
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.M -> {
                when (Build.VERSION.SECURITY_PATCH) {
                    "2015-11-01" -> "encrypted"
                    else -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) "encrypted" else "unknown"
                }
            }
            else -> "unknown"
        }

        return mapOf(
            "isDeviceSecure" to isDeviceSecure,
            "hasFingerprint" to hasFingerprint,
            "hasFaceUnlock" to hasFaceUnlock,
            "screenLockEnabled" to screenLockEnabled,
            "encryptionStatus" to encryptionStatus
        )
    }

    private fun calculateScreenSizeInches(widthPx: Int, heightPx: Int, densityDpi: Int): Double {
        val widthInches = widthPx / (densityDpi.toDouble())
        val heightInches = heightPx / (densityDpi.toDouble())
        return Math.sqrt((widthInches * widthInches) + (heightInches * heightInches))
    }
}

