import 'package:flutter/material.dart';
import 'package:flutter_device_info_plus/flutter_device_info_plus.dart';

void main() {
  runApp(const MyApp());
}

/// Example app demonstrating flutter_device_info_plus package usage.
class MyApp extends StatelessWidget {
  /// Creates the main app widget.
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Device Info Plus Example',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const DeviceInfoScreen(),
      );
}

/// Screen displaying comprehensive device information.
class DeviceInfoScreen extends StatefulWidget {
  /// Creates the device info screen.
  const DeviceInfoScreen({super.key});

  @override
  State<DeviceInfoScreen> createState() => _DeviceInfoScreenState();
}

class _DeviceInfoScreenState extends State<DeviceInfoScreen> {
  final FlutterDeviceInfoPlus _deviceInfo = const FlutterDeviceInfoPlus();
  DeviceInformation? _deviceInformation;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final info = await _deviceInfo.getDeviceInfo();

      setState(() {
        _deviceInformation = info;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Device Information'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadDeviceInfo,
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: _buildBody(),
      );

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading device information...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading device info:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDeviceInfo,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_deviceInformation == null) {
      return const Center(
        child: Text('No device information available'),
      );
    }

    return _buildDeviceInfoList();
  }

  Widget _buildDeviceInfoList() {
    final info = _deviceInformation!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoCard(
          'Device Information',
          Icons.phone_android,
          [
            _InfoItem('Name', info.deviceName),
            _InfoItem('Manufacturer', info.manufacturer),
            _InfoItem('Model', info.model),
            _InfoItem('Brand', info.brand),
          ],
        ),
        _buildInfoCard(
          'System Information',
          Icons.computer,
          [
            _InfoItem('Operating System', info.operatingSystem),
            _InfoItem('Version', info.systemVersion),
            _InfoItem('Build Number', info.buildNumber),
            _InfoItem('Kernel Version', info.kernelVersion),
          ],
        ),
        _buildInfoCard(
          'Hardware Specifications',
          Icons.memory,
          [
            _InfoItem('CPU Architecture', info.processorInfo.architecture),
            _InfoItem('CPU Cores', '${info.processorInfo.coreCount}'),
            _InfoItem(
              'Max Frequency',
              '${info.processorInfo.maxFrequency} MHz',
            ),
            _InfoItem('Processor Name', info.processorInfo.processorName),
            _InfoItem(
              'Total RAM',
              '${info.memoryInfo.totalPhysicalMemoryMB.toStringAsFixed(0)} MB',
            ),
            _InfoItem(
              'Available RAM',
              '${info.memoryInfo.availablePhysicalMemoryMB.toStringAsFixed(0)} MB',
            ),
            _InfoItem(
              'Total Storage',
              '${info.memoryInfo.totalStorageSpaceGB.toStringAsFixed(1)} GB',
            ),
            _InfoItem(
              'Available Storage',
              '${info.memoryInfo.availableStorageSpaceGB.toStringAsFixed(1)} GB',
            ),
            _InfoItem(
              'Memory Usage',
              '${info.memoryInfo.memoryUsagePercentage.toStringAsFixed(1)}%',
            ),
          ],
        ),
        _buildInfoCard(
          'Display Information',
          Icons.screen_lock_portrait,
          [
            _InfoItem('Resolution', info.displayInfo.resolutionString),
            _InfoItem(
              'Pixel Density',
              '${info.displayInfo.pixelDensity.toStringAsFixed(2)}x',
            ),
            _InfoItem(
              'Pixels Per Inch',
              '${info.displayInfo.pixelsPerInch.toStringAsFixed(0)} PPI',
            ),
            _InfoItem('Refresh Rate', '${info.displayInfo.refreshRate} Hz'),
            _InfoItem(
              'Screen Size',
              '${info.displayInfo.screenSizeInches.toStringAsFixed(1)}"',
            ),
            _InfoItem(
              'Aspect Ratio',
              '${info.displayInfo.aspectRatio.toStringAsFixed(2)}:1',
            ),
            _InfoItem('Orientation', info.displayInfo.orientation),
            _InfoItem('HDR Support', info.displayInfo.isHdr ? 'Yes' : 'No'),
            _InfoItem(
              'High Density',
              info.displayInfo.isHighDensity ? 'Yes' : 'No',
            ),
            _InfoItem(
              'High Refresh Rate',
              info.displayInfo.isHighRefreshRate ? 'Yes' : 'No',
            ),
          ],
        ),
        if (info.batteryInfo != null)
          _buildInfoCard(
            'Battery Information',
            Icons.battery_full,
            [
              _InfoItem('Battery Level', '${info.batteryInfo!.batteryLevel}%'),
              _InfoItem('Charging Status', info.batteryInfo!.chargingStatus),
              _InfoItem('Battery Health', info.batteryInfo!.batteryHealth),
              _InfoItem('Capacity', '${info.batteryInfo!.batteryCapacity} mAh'),
              _InfoItem(
                'Voltage',
                '${info.batteryInfo!.batteryVoltage.toStringAsFixed(2)} V',
              ),
              _InfoItem(
                'Temperature',
                '${info.batteryInfo!.batteryTemperature.toStringAsFixed(1)}°C',
              ),
              _InfoItem(
                'Temperature (°F)',
                '${info.batteryInfo!.batteryTemperatureFahrenheit.toStringAsFixed(1)}°F',
              ),
              _InfoItem(
                'Is Charging',
                info.batteryInfo!.isCharging ? 'Yes' : 'No',
              ),
              _InfoItem(
                'Is Low Battery',
                info.batteryInfo!.isLowBattery ? 'Yes' : 'No',
              ),
            ],
          ),
        _buildInfoCard(
          'Sensor Information',
          Icons.sensors,
          [
            _InfoItem('Total Sensors', '${info.sensorInfo.sensorCount}'),
            _InfoItem(
              'Accelerometer',
              info.sensorInfo.hasAccelerometer ? 'Available' : 'Not Available',
            ),
            _InfoItem(
              'Gyroscope',
              info.sensorInfo.hasGyroscope ? 'Available' : 'Not Available',
            ),
            _InfoItem(
              'Magnetometer',
              info.sensorInfo.hasMagnetometer ? 'Available' : 'Not Available',
            ),
            _InfoItem(
              'Proximity',
              info.sensorInfo.hasProximity ? 'Available' : 'Not Available',
            ),
            _InfoItem(
              'Light Sensor',
              info.sensorInfo.hasLightSensor ? 'Available' : 'Not Available',
            ),
            _InfoItem(
              'Barometer',
              info.sensorInfo.hasBarometer ? 'Available' : 'Not Available',
            ),
            _InfoItem(
              'Step Counter',
              info.sensorInfo.hasStepCounter ? 'Available' : 'Not Available',
            ),
            _InfoItem(
              'Heart Rate',
              info.sensorInfo.hasHeartRate ? 'Available' : 'Not Available',
            ),
          ],
        ),
        _buildInfoCard(
          'Network Information',
          Icons.wifi,
          [
            _InfoItem('Connection Type', info.networkInfo.connectionType),
            _InfoItem('Network Speed', info.networkInfo.networkSpeed),
            _InfoItem('Connected', info.networkInfo.isConnected ? 'Yes' : 'No'),
            _InfoItem('IP Address', info.networkInfo.ipAddress),
            _InfoItem('MAC Address', info.networkInfo.macAddress),
            _InfoItem(
              'WiFi Connected',
              info.networkInfo.isWifiConnected ? 'Yes' : 'No',
            ),
            _InfoItem(
              'Mobile Connected',
              info.networkInfo.isMobileConnected ? 'Yes' : 'No',
            ),
            _InfoItem(
              'Ethernet Connected',
              info.networkInfo.isEthernetConnected ? 'Yes' : 'No',
            ),
          ],
        ),
        _buildInfoCard(
          'Security Information',
          Icons.security,
          [
            _InfoItem(
              'Device Secure',
              info.securityInfo.isDeviceSecure ? 'Yes' : 'No',
            ),
            _InfoItem(
              'Fingerprint',
              info.securityInfo.hasFingerprint ? 'Available' : 'Not Available',
            ),
            _InfoItem(
              'Face Unlock',
              info.securityInfo.hasFaceUnlock ? 'Available' : 'Not Available',
            ),
            _InfoItem(
              'Screen Lock',
              info.securityInfo.screenLockEnabled ? 'Enabled' : 'Disabled',
            ),
            _InfoItem('Encryption Status', info.securityInfo.encryptionStatus),
            _InfoItem(
              'Biometric Auth',
              info.securityInfo.hasBiometricAuth
                  ? 'Available'
                  : 'Not Available',
            ),
            _InfoItem(
              'Multi-Layer Security',
              info.securityInfo.hasMultiLayerSecurity ? 'Yes' : 'No',
            ),
            _InfoItem(
              'Security Score',
              '${info.securityInfo.securityScore}/100',
            ),
            _InfoItem('Security Level', info.securityInfo.securityLevel),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildInfoCard(String title, IconData icon, List<_InfoItem> items) =>
      Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...items.map((item) => _buildInfoRow(item.label, item.value)),
            ],
          ),
        ),
      );

  Widget _buildInfoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 140,
              child: Text(
                '$label:',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w400),
              ),
            ),
          ],
        ),
      );
}

class _InfoItem {
  const _InfoItem(this.label, this.value);

  final String label;
  final String value;
}
