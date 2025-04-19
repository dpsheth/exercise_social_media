import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
import 'screens/camera_screen.dart';

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
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200.0,
                floating: false,
                pinned: true,
                backgroundColor: Colors.black,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black, Colors.grey[900]!],
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.grey[800],
                            child: Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  _auth.currentUser?.displayName ?? 'User',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  _auth.currentUser?.email ?? '',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.logout, color: Colors.white),
                            onPressed: _logout,
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatColumn('Posts', '12'),
                          _buildStatColumn('Followers', '1.2K'),
                          _buildStatColumn('Following', '500'),
                        ],
                      ),
                      SizedBox(height: 20),
                      Text(
                        'My Posts',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 2,
                  crossAxisSpacing: 2,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return Container(
                      color: Colors.grey[800],
                      child: Center(
                        child: Icon(
                          Icons.image,
                          color: Colors.grey[600],
                          size: 40,
                        ),
                      ),
                    );
                  },
                  childCount: 12, // Number of posts
                ),
              ),
            ],
          ),
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
        // Username and profile section
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
            ],
          ),
        ),
        // Image with double tap detection and animation
        Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onDoubleTap: () {
                setState(() {
                  if (post['isLiked'] != true) {
                    post['isLiked'] = true;
                    post['showLikeAnimation'] = true;
                    Future.delayed(const Duration(milliseconds: 800), () {
                      if (mounted) {
                        setState(() {
                          post['showLikeAnimation'] = false;
                        });
                      }
                    });
                  }
                });
              },
              child: Container(
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
            ),
            if (post['showLikeAnimation'] == true)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 400),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 2.0 * value * (1 - value) + 1.0,
                    child: Opacity(
                      opacity: value > 0.5 ? 2 * (1 - value) : 2 * value,
                      child: const Icon(
                        Icons.thumb_up,
                        color: Colors.white,
                        size: 100,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
        // Caption
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            post['caption'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
        // Thumbs up/down buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(
                post['isLiked'] == true ? Icons.thumb_up : Icons.thumb_up_outlined,
                color: post['isLiked'] == true ? Colors.blue : Colors.white,
              ),
              onPressed: () {
                setState(() {
                  if (post['isLiked'] != true) {
                    post['isLiked'] = true;
                    post['showLikeAnimation'] = true;
                    Future.delayed(const Duration(milliseconds: 800), () {
                      if (mounted) {
                        setState(() {
                          post['showLikeAnimation'] = false;
                        });
                      }
                    });
                  }
                });
              },
            ),
            const SizedBox(width: 20),
            IconButton(
              icon: Icon(
                post['isLiked'] == false ? Icons.thumb_down : Icons.thumb_down_outlined,
                color: post['isLiked'] == false ? Colors.red : Colors.white,
              ),
              onPressed: () {
                setState(() {
                  post['isLiked'] = false;
                });
              },
            ),
          ],
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
