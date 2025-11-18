import 'package:flutter/material.dart';
import 'package:chirp/modules/nearby/nearbyLogic.dart';

class NearbyDetailsPage extends StatelessWidget {
  const NearbyDetailsPage({super.key, required this.device});

  final ChirpDevice device;

  @override
  Widget build(BuildContext context) {
    final deviceName = device.device.platformName.isNotEmpty
        ? device.device.platformName
        : 'Unknown Device';
    return Scaffold(
      appBar: AppBar(
        title: Text(deviceName),
      ),
      body: const Center(
        child: Text('Details about the device will be shown here.'),
      ),
    );
  }
}
