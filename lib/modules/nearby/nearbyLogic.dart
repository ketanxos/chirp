import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:nsd/nsd.dart' as nsd;

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

class WifiChirpDevice {
  final nsd.Service service;
  bool isPaired;

  WifiChirpDevice({required this.service, this.isPaired = false});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is WifiChirpDevice &&
              runtimeType == other.runtimeType &&
              service.name == other.service.name &&
              service.type == other.service.type;

  @override
  int get hashCode => service.hashCode;
}

class PairingRequest {
  final WifiChirpDevice device;
  final Socket socket;

  PairingRequest(this.device, this.socket);
}

class NearbyLogic extends ChangeNotifier {
  final List<ChirpDevice> _discoveredDevices = [];
  final List<WifiChirpDevice> _wifiDiscoveredDevices = [];
  final List<ChirpDevice> _pairedDevices = [];
  final Map<String, Socket> _pairedDeviceSockets = {};

  final StreamController<PairingRequest> _pairingRequestController =
  StreamController.broadcast();
  Stream<PairingRequest> get onPairingRequest =>
      _pairingRequestController.stream;

  nsd.Discovery? _nsdDiscovery;
  nsd.Registration? _nsdRegistration;
  ServerSocket? _serverSocket;

  static const String _serviceType = '_chirp._tcp';
  final String _deviceId =
      'chirp-device-${DateTime.now().millisecondsSinceEpoch}';

  Timer? _refreshTimer;

  List<dynamic> get discoveredDevices {
    final allDevices = <dynamic>[];
    allDevices.addAll(_discoveredDevices);
    allDevices.addAll(_wifiDiscoveredDevices.where((wifiDevice) {
      return !_discoveredDevices.any((btDevice) =>
      btDevice.device.remoteId == wifiDevice.service.name);
    }));
    return allDevices;
  }

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
    _registerNsdService();
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

  Future<void> _registerNsdService() async {
    try {
      final service = nsd.Service(
        name: _deviceId,
        type: _serviceType,
        port: 0,
      );

      _nsdRegistration = await nsd.register(service);
      await _startSocketServer(_nsdRegistration!.service.port!);

      if (kDebugMode) {
        print("Service registered: ${_nsdRegistration?.service}");
      }
    } catch (e) {
      if (kDebugMode) print("Error registering NSD service: $e");
    }
  }

  Future<void> _startSocketServer(int port) async {
    try {
      _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, port);
      if (kDebugMode)
        print('Socket server started on port ${_serverSocket?.port}');

      _serverSocket?.listen((socket) {
        socket.listen((List<int> data) {
          final message = String.fromCharCodes(data).trim();
          if (kDebugMode) print('Received from client: $message');

          if (message.startsWith('PAIR_REQUEST:')) {
            final deviceId = message.split(':')[1];
            final device = _wifiDiscoveredDevices.firstWhere(
                    (d) => d.service.name == deviceId,
                orElse: () {
                  return WifiChirpDevice(
                    service: nsd.Service(
                      name: deviceId,
                      type: _serviceType,
                      host: socket.remoteAddress.address,
                      port: socket.remotePort,
                    ),
                  );
                });

            _pairingRequestController.add(PairingRequest(device, socket));
          }
        });
      });
    } catch (e) {
      if (kDebugMode) print('Error starting socket server: $e');
    }
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
    _wifiDiscoveredDevices.clear();

    await _startNsdDiscovery();

    try {
      _scanSubscription =
          FlutterBluePlus.scanResults.listen((List<ScanResult> results) {
            for (final r in results) {
              if (r.device.platformName.isNotEmpty) {
                final isPaired = _pairedDevices
                    .any((p) => p.device.remoteId == r.device.remoteId);

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

  Future<void> _startNsdDiscovery() async {
    if (_nsdDiscovery != null) return;

    try {
      _nsdDiscovery = await nsd.startDiscovery(
        _serviceType,
        ipLookupType: nsd.IpLookupType.any,
      );

      _nsdDiscovery!.addListener(() {
        for (var service in _nsdDiscovery!.services) {
          final name = service.name;
          final type = service.type;
          final host = service.host;
          final port = service.port;

          if (name == null) continue;

          final existing = _wifiDiscoveredDevices
              .where((d) => d.service.name == name)
              .toList();
          if (existing.isEmpty) {
            final wifiDev = WifiChirpDevice(service: service);
            _wifiDiscoveredDevices.add(wifiDev);
          }
        }

        _wifiDiscoveredDevices.removeWhere((wifiDev) {
          return !_nsdDiscovery!.services.any((s) =>
          s.name == wifiDev.service.name &&
              s.type == wifiDev.service.type);
        });

        notifyListeners();
      });

      _nsdDiscovery!.addServiceListener((nsd.Service service, nsd.ServiceStatus status) {
        final name = service.name;
        if (name == null) return;

        if (status == nsd.ServiceStatus.found) {
          final newDev = WifiChirpDevice(service: service);
          if (!_wifiDiscoveredDevices.contains(newDev)) {
            _wifiDiscoveredDevices.add(newDev);
            notifyListeners();
          }
        } else if (status == nsd.ServiceStatus.lost) {
          _wifiDiscoveredDevices
              .removeWhere((d) => d.service.name == name && d.service.type == service.type);
          notifyListeners();
        }
      });
    } catch (e) {
      if (kDebugMode) print('Error starting NSD discovery: $e');
    }
  }

  void _stopNsdDiscovery() {
    if (_nsdDiscovery != null) {
      nsd.stopDiscovery(_nsdDiscovery!);
      _nsdDiscovery = null;
    }
  }

  void stopScan() {
    FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();
    _stopNsdDiscovery();
    _isScanning = false;
    notifyListeners();
  }

  void pairWithDevice(dynamic device) {
    if (device is ChirpDevice) {
      _pairWithBluetoothDevice(device.device);
    } else if (device is WifiChirpDevice) {
      _sendPairingRequest(device);
    }
  }

  void _pairWithBluetoothDevice(BluetoothDevice device) {
    final newPaired = ChirpDevice(device: device, isPaired: true);
    if (!_pairedDevices.contains(newPaired)) {
      _pairedDevices.add(newPaired);
    }

    final index = _discoveredDevices
        .indexWhere((d) => d.device.remoteId == device.remoteId);
    if (index != -1) {
      _discoveredDevices[index] = newPaired;
    }

    if (kDebugMode) print("Paired with ${device.platformName}");
    notifyListeners();
  }

  Future<void> _sendPairingRequest(WifiChirpDevice device) async {
    final host = device.service.host;
    final port = device.service.port;
    final name = device.service.name;

    if (host == null || port == null || name == null) {
      if (kDebugMode) print("Cannot connect: host or port or name is null");
      return;
    }

    try {
      final socket = await Socket.connect(host, port);
      socket.write('PAIR_REQUEST:$_deviceId');

      socket.listen((List<int> data) {
        final response = String.fromCharCodes(data).trim();

        if (response == 'PAIR_ACCEPTED') {
          if (kDebugMode) print('Pairing accepted by $name');

          final index = _wifiDiscoveredDevices
              .indexWhere((d) => d.service.name == name);

          if (index != -1) {
            _wifiDiscoveredDevices[index].isPaired = true;
            _pairedDeviceSockets[name] = socket;
            notifyListeners();
          }
        } else {
          if (kDebugMode) print('Pairing rejected by $name');
          socket.destroy();
        }
      }, onDone: () {
        if (kDebugMode) print('Pairing socket closed by remote');
        _pairedDeviceSockets.remove(name);
        socket.destroy();
      });
    } catch (e) {
      if (kDebugMode) print('Error sending pairing request: $e');
    }
  }

  void acceptPairing(PairingRequest request) {
    request.socket.write('PAIR_ACCEPTED');

    final service = request.device.service;
    final name = service.name;

    if (name == null) {
      return;
    }

    final index = _wifiDiscoveredDevices
        .indexWhere((d) => d.service.name == name);

    if (index != -1) {
      _wifiDiscoveredDevices[index].isPaired = true;
    } else {
      request.device.isPaired = true;
      _wifiDiscoveredDevices.add(request.device);
    }

    _pairedDeviceSockets[name] = request.socket;
    notifyListeners();
  }

  void rejectPairing(PairingRequest request) {
    request.socket.write('PAIR_REJECTED');
    request.socket.destroy();
  }

  void sendMessage(String deviceName, String message) {
    final socket = _pairedDeviceSockets[deviceName];
    if (socket != null) {
      socket.write(message);
    } else {
      if (kDebugMode) print('No socket found for device $deviceName');
    }
  }

  @override
  void dispose() {
    stopScan();
    _adapterStateSubscription?.cancel();
    _refreshTimer?.cancel();

    if (_nsdRegistration != null) {
      nsd.unregister(_nsdRegistration!);
    }

    _serverSocket?.close();
    _pairingRequestController.close();
    _pairedDeviceSockets.values.forEach((socket) => socket.destroy());

    super.dispose();
  }
}
