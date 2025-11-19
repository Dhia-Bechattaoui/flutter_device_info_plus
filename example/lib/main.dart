import 'package:flutter/material.dart';
import 'package:flutter_device_info_plus/flutter_device_info_plus.dart';

void main() {
  runApp(const MyApp());
}

/// Example app demonstrating all features of flutter_device_info_plus package.
class MyApp extends StatelessWidget {
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

/// Screen displaying all device information features.
class DeviceInfoScreen extends StatefulWidget {
  const DeviceInfoScreen({super.key});

  @override
  State<DeviceInfoScreen> createState() => _DeviceInfoScreenState();
}

class _DeviceInfoScreenState extends State<DeviceInfoScreen> {
  final FlutterDeviceInfoPlus _deviceInfo = const FlutterDeviceInfoPlus();
  DeviceInformation? _deviceInformation;
  BatteryInfo? _batteryInfo;
  SensorInfo? _sensorInfo;
  NetworkInfo? _networkInfo;
  String? _currentPlatform;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAllInfo();
  }

  Future<void> _loadAllInfo() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Demonstrate all available methods
      final platform = _deviceInfo.getCurrentPlatform();
      final deviceInfo = await _deviceInfo.getDeviceInfo();
      final batteryInfo = await _deviceInfo.getBatteryInfo();
      final sensorInfo = await _deviceInfo.getSensorInfo();
      final networkInfo = await _deviceInfo.getNetworkInfo();

      setState(() {
        _currentPlatform = platform;
        _deviceInformation = deviceInfo;
        _batteryInfo = batteryInfo;
        _sensorInfo = sensorInfo;
        _networkInfo = networkInfo;
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
          title: const Text('Device Info Plus - All Features'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadAllInfo,
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
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAllInfo,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Platform Detection Feature
        _buildInfoCard(
          'Platform Detection',
          Icons.devices,
          [
            _InfoItem('Current Platform', _currentPlatform ?? 'Unknown'),
          ],
        ),

        // getDeviceInfo() - Main Method
        if (_deviceInformation != null) ...[
          _buildInfoCard(
            'Device Information (getDeviceInfo)',
            Icons.phone_android,
            [
              _InfoItem('Name', _deviceInformation!.deviceName),
              _InfoItem('Manufacturer', _deviceInformation!.manufacturer),
              _InfoItem('Model', _deviceInformation!.model),
              _InfoItem('Brand', _deviceInformation!.brand),
            ],
          ),
          _buildInfoCard(
            'System Information',
            Icons.computer,
            [
              _InfoItem('OS', _deviceInformation!.operatingSystem),
              _InfoItem('Version', _deviceInformation!.systemVersion),
              _InfoItem('Build', _deviceInformation!.buildNumber),
              _InfoItem('Kernel', _deviceInformation!.kernelVersion),
            ],
          ),
          _buildInfoCard(
            'Processor Information',
            Icons.memory,
            [
              _InfoItem('Architecture',
                  _deviceInformation!.processorInfo.architecture),
              _InfoItem(
                  'Cores', '${_deviceInformation!.processorInfo.coreCount}'),
              _InfoItem('Max Frequency',
                  '${_deviceInformation!.processorInfo.maxFrequency} MHz'),
              _InfoItem(
                  'Name', _deviceInformation!.processorInfo.processorName),
              _InfoItem('Features',
                  _deviceInformation!.processorInfo.features.join(', ')),
            ],
          ),
          _buildInfoCard(
            'Memory Information',
            Icons.storage,
            [
              _InfoItem('Total RAM',
                  '${_deviceInformation!.memoryInfo.totalPhysicalMemoryMB.toStringAsFixed(0)} MB'),
              _InfoItem('Available RAM',
                  '${_deviceInformation!.memoryInfo.availablePhysicalMemoryMB.toStringAsFixed(0)} MB'),
              _InfoItem('Total Storage',
                  '${_deviceInformation!.memoryInfo.totalStorageSpaceGB.toStringAsFixed(1)} GB'),
              _InfoItem('Available Storage',
                  '${_deviceInformation!.memoryInfo.availableStorageSpaceGB.toStringAsFixed(1)} GB'),
              _InfoItem('Memory Usage',
                  '${_deviceInformation!.memoryInfo.memoryUsagePercentage.toStringAsFixed(1)}%'),
            ],
          ),
          _buildInfoCard(
            'Display Information',
            Icons.screen_lock_portrait,
            [
              _InfoItem('Resolution',
                  _deviceInformation!.displayInfo.resolutionString),
              _InfoItem('Pixel Density',
                  '${_deviceInformation!.displayInfo.pixelDensity.toStringAsFixed(2)}x'),
              _InfoItem(
                  'PPI',
                  _deviceInformation!.displayInfo.pixelsPerInch
                      .toStringAsFixed(0)),
              _InfoItem('Refresh Rate',
                  '${_deviceInformation!.displayInfo.refreshRate} Hz'),
              _InfoItem('Screen Size',
                  '${_deviceInformation!.displayInfo.screenSizeInches.toStringAsFixed(1)}"'),
              _InfoItem(
                  'Orientation', _deviceInformation!.displayInfo.orientation),
              _InfoItem('HDR Support',
                  _deviceInformation!.displayInfo.isHdr ? 'Yes' : 'No'),
            ],
          ),
          _buildInfoCard(
            'Security Information',
            Icons.security,
            [
              _InfoItem(
                  'Device Secure',
                  _deviceInformation!.securityInfo.isDeviceSecure
                      ? 'Yes'
                      : 'No'),
              _InfoItem(
                  'Fingerprint',
                  _deviceInformation!.securityInfo.hasFingerprint
                      ? 'Available'
                      : 'Not Available'),
              _InfoItem(
                  'Face Unlock',
                  _deviceInformation!.securityInfo.hasFaceUnlock
                      ? 'Available'
                      : 'Not Available'),
              _InfoItem(
                  'Screen Lock',
                  _deviceInformation!.securityInfo.screenLockEnabled
                      ? 'Enabled'
                      : 'Disabled'),
              _InfoItem('Encryption',
                  _deviceInformation!.securityInfo.encryptionStatus),
              _InfoItem('Security Score',
                  '${_deviceInformation!.securityInfo.securityScore}/100'),
              _InfoItem('Security Level',
                  _deviceInformation!.securityInfo.securityLevel),
            ],
          ),
        ],

        // getBatteryInfo() - Individual Method
        _buildInfoCard(
          'Battery Information (getBatteryInfo)',
          Icons.battery_full,
          _batteryInfo != null
              ? [
                  _InfoItem('Level', '${_batteryInfo!.batteryLevel}%'),
                  _InfoItem('Status', _batteryInfo!.chargingStatus),
                  _InfoItem('Health', _batteryInfo!.batteryHealth),
                  _InfoItem('Capacity', '${_batteryInfo!.batteryCapacity} mAh'),
                  _InfoItem('Voltage',
                      '${_batteryInfo!.batteryVoltage.toStringAsFixed(2)} V'),
                  _InfoItem('Temperature',
                      '${_batteryInfo!.batteryTemperature.toStringAsFixed(1)}°C'),
                  _InfoItem(
                      'Is Charging', _batteryInfo!.isCharging ? 'Yes' : 'No'),
                  _InfoItem(
                      'Is Low', _batteryInfo!.isLowBattery ? 'Yes' : 'No'),
                ]
              : [
                  const _InfoItem(
                      'Status', 'Not Available (Desktop/No Battery)'),
                ],
        ),

        // getSensorInfo() - Individual Method
        _buildInfoCard(
          'Sensor Information (getSensorInfo)',
          Icons.sensors,
          _sensorInfo != null
              ? [
                  _InfoItem('Total Sensors', '${_sensorInfo!.sensorCount}'),
                  _InfoItem(
                      'Accelerometer',
                      _sensorInfo!.hasAccelerometer
                          ? 'Available'
                          : 'Not Available'),
                  _InfoItem(
                      'Gyroscope',
                      _sensorInfo!.hasGyroscope
                          ? 'Available'
                          : 'Not Available'),
                  _InfoItem(
                      'Magnetometer',
                      _sensorInfo!.hasMagnetometer
                          ? 'Available'
                          : 'Not Available'),
                  _InfoItem(
                      'Proximity',
                      _sensorInfo!.hasProximity
                          ? 'Available'
                          : 'Not Available'),
                  _InfoItem(
                      'Light Sensor',
                      _sensorInfo!.hasLightSensor
                          ? 'Available'
                          : 'Not Available'),
                  _InfoItem(
                      'Barometer',
                      _sensorInfo!.hasBarometer
                          ? 'Available'
                          : 'Not Available'),
                  _InfoItem(
                      'Step Counter',
                      _sensorInfo!.hasStepCounter
                          ? 'Available'
                          : 'Not Available'),
                  _InfoItem(
                      'Heart Rate',
                      _sensorInfo!.hasHeartRate
                          ? 'Available'
                          : 'Not Available'),
                  _InfoItem(
                      'Available Sensors',
                      _sensorInfo!.availableSensors
                          .map((s) => s.toString().split('.').last)
                          .join(', ')),
                ]
              : [
                  const _InfoItem('Status', 'Loading...'),
                ],
        ),

        // getNetworkInfo() - Individual Method
        _buildInfoCard(
          'Network Information (getNetworkInfo)',
          Icons.wifi,
          _networkInfo != null
              ? [
                  _InfoItem('Connection Type', _networkInfo!.connectionType),
                  _InfoItem('Network Speed', _networkInfo!.networkSpeed),
                  _InfoItem(
                      'Connected', _networkInfo!.isConnected ? 'Yes' : 'No'),
                  _InfoItem('IP Address', _networkInfo!.ipAddress),
                  _InfoItem('MAC Address', _networkInfo!.macAddress),
                  _InfoItem(
                      'WiFi', _networkInfo!.isWifiConnected ? 'Yes' : 'No'),
                  _InfoItem(
                      'Mobile', _networkInfo!.isMobileConnected ? 'Yes' : 'No'),
                  _InfoItem('Ethernet',
                      _networkInfo!.isEthernetConnected ? 'Yes' : 'No'),
                ]
              : [
                  const _InfoItem('Status', 'Loading...'),
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
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
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
