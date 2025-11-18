import 'package:flutter/material.dart';
import '../components/searchBar.dart';

class CallsPage extends StatelessWidget {
  const CallsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        searchBar(),
        Expanded(
          child: Center(
            child: Text('No recent calls'),
          ),
        ),
      ],
    );
  }
}