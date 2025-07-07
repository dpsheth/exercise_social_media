import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'login_page.dart';
import 'screens/camera_screen.dart';
import 'screens/profile_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase with error handling
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'YOUR_API_KEY',  // Replace with your actual API key
        appId: 'YOUR_APP_ID',    // Replace with your actual App ID
        messagingSenderId: 'YOUR_SENDER_ID',
        projectId: 'bepeel-6b4b5',  // Your Firebase project ID
        storageBucket: 'bepeel-6b4b5.appspot.com',
      ),
    );
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Error initializing Firebase: $e');
    // Continue running the app even if Firebase initialization fails
  }
  
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

class _VideoPreview extends StatefulWidget {
  final File file;

  const _VideoPreview({Key? key, required this.file}) : super(key: key);

  @override
  _VideoPreviewState createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<_VideoPreview> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(
      widget.file,
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: true,
      ),
    )..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
            _controller.setLooping(true);
          });
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Calculate aspect ratio, default to 16:9 if not available
    final aspectRatio = _controller.value.aspectRatio > 0
        ? _controller.value.aspectRatio
        : 16 / 9;

    return Center(
      child: GestureDetector(
        onTap: _togglePlayPause,
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: Container(
            color: Colors.black,
            child: VideoPlayer(_controller),
          ),
        ),
      ),
    );
  }
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();
  String? _scrollToPostId;
  bool _hasScrolledToPost = false;

  // Posts list - starts empty
  final List<Map<String, dynamic>> _posts = [];
  StreamSubscription<QuerySnapshot>? _postsSubscription;

  @override
  void initState() {
    super.initState();
    _loadPosts();
    
    // Listen to scroll events to handle post scrolling
    _scrollController.addListener(_onScroll);
  }
  
  void _onScroll() {
    // Reset the scroll flag when user scrolls manually
    if (_hasScrolledToPost) {
      _hasScrolledToPost = false;
      _scrollToPostId = null;
    }
  }
  
  void _scrollToPostIfNeeded() {
    if (_scrollToPostId == null || _hasScrolledToPost || _posts.isEmpty) return;
    
    final postIndex = _posts.indexWhere((post) => post['id'] == _scrollToPostId);
    if (postIndex != -1) {
      // Wait for the next frame to ensure the list is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        
        // Estimate the position based on the post index
        final double estimatedHeight = 600; // Approximate height of each post
        final double targetPosition = postIndex * estimatedHeight;
        
        _scrollController.animateTo(
          targetPosition,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        
        _hasScrolledToPost = true;
      });
    }
  }

  @override
  void dispose() {
    _postsSubscription?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _loadPosts() {
    _postsSubscription?.cancel();
    _postsSubscription = _firestore
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) async {
      if (mounted) {
        final posts = <Map<String, dynamic>>[];
        final currentUserId = _auth.currentUser?.uid;
        
        // Process each post
        for (var doc in snapshot.docs) {
          final data = doc.data();
          
          // Get the latest user data to ensure we have the most recent profile picture
          String? profileImageUrl = data['profileImageUrl'];
          
          // If we don't have a profile image URL or it's empty, try to get it from the user's document
          if (profileImageUrl == null || profileImageUrl.isEmpty) {
            try {
              final userDoc = await _firestore.collection('users').doc(data['userId']).get();
              if (userDoc.exists) {
                profileImageUrl = userDoc.data()?['profileImageUrl'] ?? '';
              }
            } catch (e) {
              debugPrint('Error fetching user data: $e');
            }
          }
          
          // Check if the current user has liked/disliked this post
          bool isLiked = false;
          bool isDisliked = false;
          
          if (currentUserId != null) {
            try {
              final likeDoc = await _firestore
                  .collection('posts')
                  .doc(doc.id)
                  .collection('likes')
                  .doc(currentUserId)
                  .get();
                  
              if (likeDoc.exists) {
                final likeData = likeDoc.data();
                isLiked = likeData?['isLiked'] == true;
                isDisliked = likeData?['isLiked'] == false;
              }
            } catch (e) {
              debugPrint('Error checking like status: $e');
            }
          }
          
          posts.add({
            'id': doc.id,
            'username': data['username'],
            'profileImageUrl': profileImageUrl,
            'mediaFile': File(data['mediaUrl']),
            'isVideo': data['isVideo'] ?? false,
            'caption': data['caption'],
            'likes': data['likes']?.toString() ?? '0',
            'comments': data['comments']?.toString() ?? '0',
            'timeAgo': _formatTimeAgo(data['timestamp']?.toDate() ?? DateTime.now()),
            'isLiked': isLiked,
            'isDisliked': isDisliked,
            'userId': data['userId'],
            'timestamp': data['timestamp'],
          });
        }
        
        if (mounted) {
          setState(() {
            _posts.clear();
            _posts.addAll(posts);
          });
          
          // Scroll to the specified post if needed
          _scrollToPostIfNeeded();
        }
      }
    }, onError: (error) {
      debugPrint('Error loading posts: $error');
    });
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    
    final weeks = (difference.inDays / 7).floor();
    if (weeks < 4) return '$weeks${weeks == 1 ? 'w' : 'w'} ago';
    
    final months = (difference.inDays / 30).floor();
    if (months < 12) return '$months${months == 1 ? 'mo' : 'mo'} ago';
    
    final years = (difference.inDays / 365).floor();
    return '$years${years == 1 ? 'y' : 'y'} ago';
  }


  Future<void> _handleCameraResult(dynamic result) async {
    if (result != null && result is Map<String, dynamic>) {
      final user = _auth.currentUser;
      if (user == null) return;

      try {
        // Get user data from Firestore
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        final userData = userDoc.data() ?? {};
        
        // Get the username and profile image URL
        final username = userData['username'] ?? 'user';
        final profileImageUrl = userData['profileImageUrl'] ?? '';
        
        final mediaFile = result['media'] as File;
        
        // In a real app, you would upload the file to Firebase Storage here
        // For now, we'll just store the file path
        final mediaUrl = mediaFile.path;
        
        // Add post to Firestore
        await _firestore.collection('posts').add({
          'userId': user.uid,
          'username': username,
          'profileImageUrl': profileImageUrl,
          'mediaUrl': mediaUrl,
          'isVideo': result['isVideo'] ?? false,
          'caption': result['caption'] ?? '',
          'timestamp': FieldValue.serverTimestamp(),
          'likes': 0,
          'comments': 0,
        });
        
        // The UI will update automatically via the stream listener
      } catch (e) {
        debugPrint('Error creating post: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to create post')),
          );
        }
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
            controller: _scrollController,
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
              if (_posts.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.photo_camera_outlined,
                            size: 80,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'No Posts Yet',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Tap the camera button to share your first post!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 30),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CameraScreen(),
                                ),
                              );
                              if (result != null) {
                                await _handleCameraResult(result);
                              }
                            },
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Create First Post'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
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

          // Empty container for camera tab - we'll handle camera in onTap
          Container(),

          // Profile Screen
          ProfileScreen(
            userId: FirebaseAuth.instance.currentUser?.uid ?? '',
            isCurrentUser: true,
            onPostSelected: (postId) {
              setState(() {
                _selectedIndex = 0; // Switch to feed tab
                _scrollToPostId = postId;
                _hasScrolledToPost = false;
                _scrollToPostIfNeeded();
              });
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) async {
          if (index == 1) {
            // Camera tab - show camera screen as a new route
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CameraScreen(),
              ),
            );
            
            if (result != null) {
              await _handleCameraResult(result);
            }
            // Always switch to feed tab after camera is closed
            if (mounted) {
              setState(() {
                _selectedIndex = 0;
              });
            }
          } else {
            // For other tabs (feed and profile)
            if (mounted) {
              setState(() {
                _selectedIndex = index;
              });
            }
          }
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

  Widget _buildPostHeader(Map<String, dynamic> post) {
    final profileImageUrl = post['profileImageUrl'];
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.grey[800],
        backgroundImage: profileImageUrl != null && profileImageUrl.isNotEmpty
            ? CachedNetworkImageProvider(profileImageUrl) as ImageProvider
            : null,
        child: profileImageUrl == null || profileImageUrl.isEmpty
            ? const Icon(
                Icons.person,
                color: Colors.white,
              )
            : null,
      ),
      title: Text(
        post['username'] ?? 'User',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        post['timeAgo'] ?? '',
        style: TextStyle(color: Colors.grey[400]),
      ),
      trailing: const Icon(
        Icons.more_vert,
        color: Colors.white,
      ),
    );
  }

  Widget _buildPost(Map<String, dynamic> post) {
    final isVideo = post['isVideo'] == true;
    final mediaFile = post['mediaFile'] as File?;
    
    if (mediaFile == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPostHeader(post),
        
        // Media content
        GestureDetector(
          onDoubleTap: () async {
            final currentUserId = _auth.currentUser?.uid;
            if (currentUserId == null) return;
            
            final postRef = _firestore.collection('posts').doc(post['id']);
            final likeRef = postRef.collection('likes').doc(currentUserId);
            
            try {
              // If already liked, remove the like
              if (post['isLiked'] == true) {
                await likeRef.delete();
                await postRef.update({
                  'likes': FieldValue.increment(-1),
                });
                
                setState(() {
                  post['isLiked'] = null;
                  post['likes'] = (int.tryParse(post['likes']) ?? 1) - 1;
                });
              } 
              // If disliked, remove the dislike and add a like
              else if (post['isDisliked'] == true) {
                await likeRef.set({
                  'isLiked': true,
                  'timestamp': FieldValue.serverTimestamp(),
                });
                
                await postRef.update({
                  'dislikes': FieldValue.increment(-1),
                  'likes': FieldValue.increment(1),
                });
                
                setState(() {
                  post['isLiked'] = true;
                  post['isDisliked'] = false;
                  post['likes'] = (int.tryParse(post['likes']) ?? 0) + 1;
                  post['dislikes'] = ((int.tryParse(post['dislikes']?.toString() ?? '1') ?? 1) - 1).toString();
                  post['showLikeAnimation'] = true;
                  
                  Future.delayed(const Duration(milliseconds: 800), () {
                    if (mounted) {
                      setState(() {
                        post['showLikeAnimation'] = false;
                      });
                    }
                  });
                });
              }
              // If neither liked nor disliked, add a like
              else {
                await likeRef.set({
                  'isLiked': true,
                  'timestamp': FieldValue.serverTimestamp(),
                });
                
                await postRef.update({
                  'likes': FieldValue.increment(1),
                });
                
                setState(() {
                  post['isLiked'] = true;
                  post['likes'] = (int.tryParse(post['likes']) ?? 0) + 1;
                  post['showLikeAnimation'] = true;
                  
                  Future.delayed(const Duration(milliseconds: 800), () {
                    if (mounted) {
                      setState(() {
                        post['showLikeAnimation'] = false;
                      });
                    }
                  });
                });
              }
            } catch (e) {
              debugPrint('Error handling double tap: $e');
            }
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Media content (image or video)
              Container(
                height: 400,
                color: Colors.black,
                // ignore: unnecessary_null_comparison
                child: mediaFile != null
                    ? isVideo
                        ? _VideoPreview(file: mediaFile)
                        : Image.file(
                            mediaFile,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          )
                    : Center(
                        child: Icon(
                          isVideo ? Icons.videocam_off : Icons.image,
                          size: 100,
                          color: Colors.grey[600],
                        ),
                      ),
              ),
              
              // Like animation
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
              onPressed: () async {
                final currentUserId = _auth.currentUser?.uid;
                if (currentUserId == null) return;
                
                final postRef = _firestore.collection('posts').doc(post['id']);
                final likeRef = postRef.collection('likes').doc(currentUserId);
                
                try {
                  if (post['isLiked'] == true) {
                    // If already liked, remove the like
                    await likeRef.delete();
                    await postRef.update({
                      'likes': FieldValue.increment(-1),
                    });
                    
                    setState(() {
                      post['isLiked'] = null;
                      post['likes'] = (int.tryParse(post['likes']) ?? 1) - 1;
                    });
                  } else {
                    // Add or update like
                    await likeRef.set({
                      'isLiked': true,
                      'timestamp': FieldValue.serverTimestamp(),
                    });
                    
                    // If was previously disliked, remove the dislike
                    if (post['isLiked'] == false) {
                      await postRef.update({
                        'dislikes': FieldValue.increment(-1),
                        'likes': FieldValue.increment(1),
                      });
                      post['likes'] = (int.tryParse(post['likes']) ?? 0) + 1;
                      final currentDislikes = int.tryParse(post['dislikes']?.toString() ?? '1') ?? 1;
                      post['dislikes'] = (currentDislikes - 1).toString();
                    } else {
                      await postRef.update({
                        'likes': FieldValue.increment(1),
                      });
                      post['likes'] = (int.tryParse(post['likes']) ?? 0) + 1;
                    }
                    
                    setState(() {
                      post['isLiked'] = true;
                      post['isDisliked'] = false;
                      post['showLikeAnimation'] = true;
                      Future.delayed(const Duration(milliseconds: 800), () {
                        if (mounted) {
                          setState(() {
                            post['showLikeAnimation'] = false;
                          });
                        }
                      });
                    });
                  }
                } catch (e) {
                  debugPrint('Error toggling like: $e');
                }
              },
            ),
            const SizedBox(width: 20),
            IconButton(
              icon: Icon(
                post['isDisliked'] == true ? Icons.thumb_down : Icons.thumb_down_outlined,
                color: post['isDisliked'] == true ? Colors.orange : Colors.white,
              ),
              onPressed: () async {
                final currentUserId = _auth.currentUser?.uid;
                if (currentUserId == null) return;
                
                final postRef = _firestore.collection('posts').doc(post['id']);
                final likeRef = postRef.collection('likes').doc(currentUserId);
                
                try {
                  if (post['isDisliked'] == true) {
                    // If already disliked, remove the dislike
                    await likeRef.delete();
                    await postRef.update({
                      'dislikes': FieldValue.increment(-1),
                    });
                    
                    setState(() {
                      post['isDisliked'] = false;
                      post['dislikes'] = ((int.tryParse(post['dislikes']?.toString() ?? '1') ?? 1) - 1).toString();
                    });
                  } else {
                    // Add or update dislike
                    await likeRef.set({
                      'isLiked': false,
                      'timestamp': FieldValue.serverTimestamp(),
                    });
                    
                    // If was previously liked, remove the like
                    if (post['isLiked'] == true) {
                      await postRef.update({
                        'likes': FieldValue.increment(-1),
                        'dislikes': FieldValue.increment(1),
                      });
                      post['likes'] = (int.tryParse(post['likes']) ?? 1) - 1;
                      post['dislikes'] = ((int.tryParse(post['dislikes']?.toString() ?? '0') ?? 0) + 1).toString();
                    } else {
                      await postRef.update({
                        'dislikes': FieldValue.increment(1),
                      });
                      post['dislikes'] = ((int.tryParse(post['dislikes']?.toString() ?? '0') ?? 0) + 1).toString();
                    }
                    
                    setState(() {
                      post['isLiked'] = false;
                      post['isDisliked'] = true;
                    });
                  }
                } catch (e) {
                  debugPrint('Error toggling dislike: $e');
                }
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
