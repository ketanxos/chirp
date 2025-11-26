import 'package:chirp/modules/chats/chatEvent.dart';
import 'package:flutter/material.dart';
import '../components/searchBar.dart';
import 'package:chirp/components/chatTile.dart';

class ChatsPage extends StatelessWidget {
  const ChatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const searchBar(),
        Expanded(
          child: ListView(
            children: [
              ChatTile(
                name: 'Example Device',
                lastMessage: 'Hello!',
                time: '10:00 AM',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChatEvent(title: 'Example Device'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
