import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'nearby/nearbyLogic.dart';
import 'nearby/nearbyDetails.dart';

class NearbyPageProvider extends StatelessWidget {
  const NearbyPageProvider({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => NearbyLogic(),
      child: const NearbyPage(),
    );
  }
}

class NearbyPage extends StatelessWidget {
  const NearbyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final nearbyLogic = Provider.of<NearbyLogic>(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => nearbyLogic.startScan(),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildSectionBox(
              context: context,
              title: "ONLINE",
              emptyText: "No device discovered",
              children: nearbyLogic.discoveredDevices
                  .map((d) => _buildOnlineDeviceTile(context, d, nearbyLogic))
                  .toList(),
            ),
            const SizedBox(height: 20),
            _buildSectionBox(
              context: context,
              title: "OFFLINE",
              emptyText: "No device contacted",
              children: nearbyLogic.offlinePairedDevices
                  .map((d) => _buildOfflineDeviceTile(context, d))
                  .toList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:
            nearbyLogic.isScanning ? nearbyLogic.stopScan : nearbyLogic.startScan,
        child: Icon(nearbyLogic.isScanning ? Icons.stop_rounded : Icons.search_rounded),
      ),
    );
  }

  Widget _buildSectionBox({
    required BuildContext context,
    required String title,
    required String emptyText,
    required List<Widget> children,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: const Alignment(-0.6, -1.0),
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: Column(
              children: [
                if (children.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        emptyText,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  )
                else
                  ...children,
              ],
            ),
          ),
        ),
        Positioned(
          top: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOnlineDeviceTile(BuildContext context, ChirpDevice chirpDevice, NearbyLogic logic) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
        leading: const Icon(Icons.phone_android),
        title: Text(chirpDevice.device.platformName.isNotEmpty
            ? chirpDevice.device.platformName
            : 'Unknown Device'),
        subtitle: Text(chirpDevice.device.remoteId.toString()),
        trailing: chirpDevice.isPaired
            ? _buildPairedDeviceActions(context, chirpDevice)
            : _buildUnpairedDeviceAction(context, chirpDevice, logic),
      ),
    );
  }

  Widget _buildOfflineDeviceTile(
      BuildContext context, ChirpDevice chirpDevice) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Icon(Icons.phone_android_rounded, color: Colors.grey[400]),
        title: Text(
          chirpDevice.device.platformName.isNotEmpty
              ? chirpDevice.device.platformName
              : "Unknown Device",
          style: TextStyle(color: Colors.grey[700]),
        ),
        subtitle: Text(
          chirpDevice.device.remoteId.toString(),
          style: TextStyle(color: Colors.grey[600]),
        ),
      ),
    );
  }

  Widget _buildPairedDeviceActions(BuildContext context, ChirpDevice d) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(icon: const Icon(Icons.chat_rounded), onPressed: () {}),
        IconButton(icon: const Icon(Icons.call_rounded), onPressed: () {}),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'details') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NearbyDetailsPage(device: d),
                ),
              );
            }
          },
          offset: const Offset(0, 48),
          itemBuilder: (context) => const [
            PopupMenuItem(value: "details", child: Text("Details")),
            PopupMenuItem(value: "disconnect", child: Text("Disconnect")),
            PopupMenuItem(value: "unpair", child: Text("Unpair Device")),
          ],
        ),
      ],
    );
  }

  Widget _buildUnpairedDeviceAction(
      BuildContext context, ChirpDevice d, NearbyLogic logic) {
    return IconButton(
      icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.green),
      onPressed: () {
        logic.pairWithDevice(d.device);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Pairing with ${d.device.platformName}...")),
        );
      },
    );
  }
}
