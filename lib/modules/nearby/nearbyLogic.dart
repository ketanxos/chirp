import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ChirpDevice {
  final BluetoothDevice device;
  final bool isPaired;

  ChirpDevice({required this.device, this.isPaired = false});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ChirpDevice &&
              runtimeType == other.runtimeType &&
              device.remoteId == other.device.remoteId;

  @override
  int get hashCode => device.remoteId.hashCode;
}

class NearbyLogic extends ChangeNotifier {
  final List<ChirpDevice> _discoveredDevices = [];
  final List<ChirpDevice> _pairedDevices = [];
  Timer? _refreshTimer;

  List<ChirpDevice> get discoveredDevices => _discoveredDevices;

  List<ChirpDevice> get offlinePairedDevices {
    return _pairedDevices.where((pairedDevice) {
      return !_discoveredDevices.any(
              (d) => d.device.remoteId == pairedDevice.device.remoteId);
    }).toList();
  }

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;

  NearbyLogic() {
    _loadMockPairedDevices();
    _listenToAdapterState();
    _startAutoRefresh();
  }

  void _loadMockPairedDevices() {}

  void _listenToAdapterState() {
    _adapterStateSubscription =
        FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
          if (kDebugMode) print("Bluetooth State: $state");
          if (state != BluetoothAdapterState.on) stopScan();
        });
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      startScan();
    });
  }

  Future<void> startScan() async {
    if (_isScanning) return;

    if (!await FlutterBluePlus.isSupported) {
      if (kDebugMode) print("Bluetooth not supported");
      return;
    }

    await FlutterBluePlus.turnOn();

    _isScanning = true;
    notifyListeners();

    _discoveredDevices.clear();

    try {
      _scanSubscription =
          FlutterBluePlus.scanResults.listen((List<ScanResult> results) {
            for (final r in results) {
              if (r.device.platformName.isNotEmpty) {
                final isPaired = _pairedDevices.any(
                        (p) => p.device.remoteId == r.device.remoteId);

                final newDevice =
                ChirpDevice(device: r.device, isPaired: isPaired);

                if (!_discoveredDevices.contains(newDevice)) {
                  _discoveredDevices.add(newDevice);
                }
              }
            }
            notifyListeners();
          });

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        androidUsesFineLocation: true,
      );
    } catch (e) {
      if (kDebugMode) print("Error starting scan: $e");
    }

    FlutterBluePlus.isScanning.listen((bool scanning) {
      if (!scanning) {
        _isScanning = false;
        notifyListeners();
      }
    });
  }

  void stopScan() {
    FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();
    _isScanning = false;
    notifyListeners();
  }

  void pairWithDevice(BluetoothDevice device) {
    final newPaired = ChirpDevice(device: device, isPaired: true);

    if (!_pairedDevices.contains(newPaired)) {
      _pairedDevices.add(newPaired);
    }

    final index = _discoveredDevices
        .indexWhere((d) => d.device.remoteId == device.remoteId);

    if (index != -1) {
      _discoveredDevices[index] = newPaired;
    }

    print("Paired with ${device.platformName}");
    notifyListeners();
  }

  @override
  void dispose() {
    stopScan();
    _adapterStateSubscription?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }
}
