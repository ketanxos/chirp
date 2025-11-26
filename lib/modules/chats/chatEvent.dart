import 'package:flutter/material.dart';

class ChatEvent extends StatefulWidget {
  final String title;

  const ChatEvent({Key? key, required this.title}) : super(key: key);

  @override
  State<ChatEvent> createState() => _ChatEventState();
}

class _ChatEventState extends State<ChatEvent> {
  final TextEditingController _messageController = TextEditingController();
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      setState(() {
        _isComposing = _messageController.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Row(
          children: [
            const CircleAvatar(
              // TODO: Replace with contact's avatar
              child: Icon(Icons.person_rounded),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text(widget.title),
                  ),
                  const Text(
                    'online',
                    style: TextStyle(fontSize: 12.0),
                  ), // TODO: Replace with presence information
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Handle video call
            },
            icon: const Icon(Icons.videocam_rounded),
          ),
          IconButton(
            onPressed: () {
              // TODO: Handle voice call
            },
            icon: const Icon(Icons.call_rounded),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              // TODO: Handle menu selection
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'view_details',
                child: Text('View Details'),
              ),
              const PopupMenuItem<String>(
                value: 'search',
                child: Text('Search'),
              ),
              const PopupMenuItem<String>(
                value: 'new_group',
                child: Text('New Group'),
              ),
              const PopupMenuItem<String>(
                value: 'media',
                child: Text('Media'),
              ),
              const PopupMenuItem<String>(
                value: 'mute_notification',
                child: Text('Mute Notification'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'clear_chat',
                child: Text('Clear Chat'),
              ),
              const PopupMenuItem<String>(
                value: 'export_chat',
                child: Text('Export Chat'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              // TODO: In a real app, this would be a list of MessageBubble widgets
              children: const [
                // Example message bubbles
                // MessageBubble(text: 'Hi!', isMe: false),
                // MessageBubble(text: 'Hello!', isMe: true),
              ],
            ),
          ),
          _buildTextComposer(),
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(24.0),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.emoji_emotions_outlined),
                      onPressed: () {
                        // TODO: Implement emoji picker
                      },
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration.collapsed(
                          hintText: 'Type a message',
                        ),
                        onChanged: (text) {
                          setState(() {
                            _isComposing = text.isNotEmpty;
                          });
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.attach_file_rounded),
                      onPressed: () {
                        // TODO: Implement attachment options
                      },
                    ),
                    if (!_isComposing)
                      IconButton(
                        icon: const Icon(Icons.camera_alt_outlined),
                        onPressed: () {
                          // TODO: Implement camera functionality
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8.0),
            FloatingActionButton(
              mini: true,
              onPressed: _isComposing ? _sendMessage : _sendVoiceMessage,
              child: Icon(
                _isComposing ? Icons.send_rounded : Icons.mic_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() {
    // TODO: Implement send message functionality
    _messageController.clear();
  }

  void _sendVoiceMessage() {
    // TODO: Implement send voice message functionality
  }
}
