import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
import 'screens/camera_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/feed_screen.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            return const MainScreen();
          }
          return const LoginPage();
        },
      ),
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
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

  Future<void> _logout() async {
    try {
      await _auth.signOut();
      // Navigation is handled by the StreamBuilder in main.dart
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error signing out'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // Feed Screen
          CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.black,
                title: Text(
                  'BePeel',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.favorite_border, color: Colors.white),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= _posts.length) return null;
                    final post = _posts[index];
                    return _buildPost(post);
                  },
                ),
              ),
            ],
          ),

          // Camera Screen (Placeholder)
          const CameraScreen(),

          // Profile Screen
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

  Widget _buildPost(Map<String, dynamic> post) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.grey[800],
                child: Icon(post['profilePic'], color: Colors.white),
              ),
              SizedBox(width: 10),
              Text(
                post['username'],
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              IconButton(
                icon: Icon(Icons.more_vert, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
        ),
        Container(
          height: 400,
          color: Colors.grey[800],
          child: Center(
            child: Icon(
              post['image'],
              size: 100,
              color: Colors.grey[600],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.favorite_border, color: Colors.white),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(Icons.chat_bubble_outline, color: Colors.white),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
                    onPressed: () {},
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.bookmark_border, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
              Text(
                '${post['likes']} likes',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  style: TextStyle(color: Colors.white),
                  children: [
                    TextSpan(
                      text: '${post['username']} ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: post['caption']),
                  ],
                ),
              ),
              SizedBox(height: 4),
              Text(
                'View all ${post['comments']} comments',
                style: TextStyle(
                  color: Colors.grey[400],
                ),
              ),
              SizedBox(height: 4),
              Text(
                post['timeAgo'],
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Divider(color: Colors.grey[800]),
      ],
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
