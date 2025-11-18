import 'package:flutter/material.dart';
import 'modules/about.dart';
import 'modules/calls.dart';
import 'modules/chats.dart';
import 'modules/nearby.dart';
import 'modules/music.dart';
import 'modules/profile.dart';
import 'modules/settings.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chirp',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
      routes: {
        '/profile': (context) => const ProfilePage(),
        '/settings': (context) => const SettingsPage(),
        '/about': (context) => const AboutPage(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController(initialPage: 0);
  static const List<Widget> _widgetOptions = <Widget>[
    ChatsPage(),
    CallsPage(),
    MusicPage(),
    NearbyPageProvider(),
  ];

  static const List<String> _titles = <String>[
    'Chats',
    'Calls',
    'Music',
    'Nearby',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    _pageController.jumpToPage(index);
  }

  void _onPageChanged(int index) {
    setState(() => _selectedIndex = index);
  }

  Widget _buildNavItem(IconData icon, String label, int index, bool isSelected) {
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 30, color: isSelected ? Colors.blue : Colors.grey),
          Text(
            label,
            style: TextStyle(
              fontSize: isSelected ? 16 : 14,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
              color: isSelected ? Colors.blue : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 65,
        title: Padding(
          padding: const EdgeInsets.only(top: 12, left: 12),
          child: Text(_titles[_selectedIndex],
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 28)),
        ),
        actions: <Widget>[
          PopupMenuButton<String>(
            iconSize: 32,
            icon: const Padding(
              padding: EdgeInsets.only(top: 4, right: 8),
              child: Icon(Icons.more_vert_rounded),
            ),
            offset: const Offset(0, 58),
            onSelected: (value) {
              if (value == 'Theme') {
              } else if (value == 'Version') {
              } else {
                Navigator.pushNamed(context, value);
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'Theme',
                  child: Row(
                    children: [
                      Icon(Icons.brightness_6_rounded, color: Colors.black),
                      SizedBox(width: 10),
                      Text('Theme'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: '/profile',
                  child: Row(
                    children: [
                      Icon(Icons.person_rounded, color: Colors.black),
                      SizedBox(width: 10),
                      Text('Profile'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: '/settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings_rounded, color: Colors.black),
                      SizedBox(width: 10),
                      Text('Settings'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: '/about',
                  child: Row(
                    children: [
                      Icon(Icons.info_rounded, color: Colors.black),
                      SizedBox(width: 10),
                      Text('About'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  enabled: false,
                  child: Center(
                    child: Text('Version 1.0.2',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
              ];
            },
          ),
        ],
      ),

      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: _widgetOptions,
      ),

      bottomNavigationBar: BottomAppBar(
        padding: EdgeInsets.zero,
        color: Colors.white,
        elevation: 0,
        child: SizedBox(
          height: 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(Icons.chat_rounded, 'Chats', 0, _selectedIndex == 0),
              _buildNavItem(Icons.call_rounded, 'Calls', 1, _selectedIndex == 1),
              _buildNavItem(Icons.music_note_rounded, 'Music', 2, _selectedIndex == 2),
              _buildNavItem(Icons.wifi_tethering_rounded, 'Nearby', 3, _selectedIndex == 3),
            ],
          ),
        ),
      ),
    );
  }
}
