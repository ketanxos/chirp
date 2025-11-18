import 'dart:async';
import 'package:chirp/modules/nearby/nearbyLogic.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NearbyEvents extends StatefulWidget {
  final Widget child;
  const NearbyEvents({super.key, required this.child});

  @override
  State<NearbyEvents> createState() => _NearbyEventsState();
}

class _NearbyEventsState extends State<NearbyEvents> {
  StreamSubscription<PairingRequest>? _pairingRequestSubscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nearbyLogic = Provider.of<NearbyLogic>(context, listen: false);
    _pairingRequestSubscription?.cancel();
    _pairingRequestSubscription =
        nearbyLogic.onPairingRequest.listen(_showPairingDialog);
  }

  @override
  void dispose() {
    _pairingRequestSubscription?.cancel();
    super.dispose();
  }

  void _showPairingDialog(PairingRequest request) {
    final nearbyLogic = Provider.of<NearbyLogic>(context, listen: false);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pairing Request'),
          content: Text(
              'Device ${request.device.service.name ?? 'Unknown'} wants to pair with you.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Reject'),
              onPressed: () {
                nearbyLogic.rejectPairing(request);
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Accept'),
              onPressed: () {
                nearbyLogic.acceptPairing(request);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
