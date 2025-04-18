import 'package:flutter/material.dart';
import 'screens/feed_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/profile_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BePeel',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Dummy posts data
  final List<Map<String, dynamic>> _posts = [
    {
      'username': 'johndoe',
      'profilePic': Icons.person,
      'image': Icons.image,
      'likes': '1,234',
      'caption': 'Beautiful day at the beach! 🏖️ #summer #vacation',
      'comments': '24',
      'timeAgo': '2 hours ago',
    },
    {
      'username': 'janedoe',
      'profilePic': Icons.person,
      'image': Icons.image,
      'likes': '3,456',
      'caption': 'New recipe I tried today! 🍳 #cooking #foodie',
      'comments': '42',
      'timeAgo': '5 hours ago',
    },
    {
      'username': 'traveler',
      'profilePic': Icons.person,
      'image': Icons.image,
      'likes': '5,678',
      'caption': 'Exploring new places ✈️ #travel #adventure',
      'comments': '89',
      'timeAgo': '1 day ago',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          FeedScreen(posts: _posts),
          const CameraScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Camera',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}
