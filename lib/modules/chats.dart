import 'package:flutter/material.dart';
import '../components/searchBar.dart';

class ChatsPage extends StatelessWidget {
  const ChatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        searchBar(),
        Expanded(
          child: Center(
            child: Text('No recent chats'),
          ),
        ),
      ],
    );
  }
}