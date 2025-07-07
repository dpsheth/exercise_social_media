import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show SetOptions;
import 'package:cached_network_image/cached_network_image.dart';
import 'feed_screen.dart';

const Map<int, Color> activityColors = {
  0: Color(0xFF1F1F1F),
  1: Color(0xFF0E4429),
  2: Color(0xFF006D32),
  3: Color(0xFF26A641),
  4: Color(0xFF39D353),
};

class ProfileScreen extends StatefulWidget {
  final String userId;
  final bool isCurrentUser;
  final Function(String)? onPostSelected;

  const ProfileScreen({
    Key? key,
    required this.userId,
    this.isCurrentUser = false,
    this.onPostSelected,
  }) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isEditing = false;
  bool _isLoading = true;
  Map<String, dynamic> _userDoc = {};
  List<Map<String, dynamic>> _userPosts = [];
  StreamSubscription? _postsSubscription;
  List<Map<String, dynamic>> _allPosts = [];
  

  // controllers created later once data loads
  final Map<String, TextEditingController> _controllers = {
    'Name': TextEditingController(),
    'Height': TextEditingController(),
    'Weight': TextEditingController(),
    'Age': TextEditingController(),
    'Gym Experience': TextEditingController(),
    'Fitness Level': TextEditingController(),
  };
  final TextEditingController _usernameController = TextEditingController();

    @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadUserPosts();
    _loadAllPosts();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      // First try to get the user document
      final doc = await _firestore.collection('users').doc(user.uid).get();
      
      if (doc.exists) {
        debugPrint('Found existing user document: ${doc.data()}');
        final data = doc.data() ?? {};
        _updateControllers(data);
      } else {
        debugPrint('No user document found, initializing with defaults');
        await _initializeUserDocument(user.uid);
      }
      
      // Set up real-time listener
      _firestore
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((snapshot) {
            if (snapshot.exists) {
              _updateControllers(snapshot.data() ?? {});
            }
          });
          
    } catch (e) {
      debugPrint('Error loading user data: $e');
      // Set default values on error
      _updateControllers({});
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  void _updateControllers(Map<String, dynamic> data) {
    if (!mounted) return;
    
    debugPrint('Updating controllers with data: $data');
    
    setState(() {
      try {
        _usernameController.text = data['username']?.toString() ?? '';
        _controllers['Name']!.text = data['name']?.toString() ?? '';
        _controllers['Weight']!.text = (data['weight'] ?? '').toString();
        final feet = (data['heightFeet'] ?? '').toString();
        final inches = (data['heightInches'] ?? '').toString();
        _controllers['Height']!.text = 
            (feet.isNotEmpty && inches.isNotEmpty) 
                ? '$feet feet $inches inches' 
                : '';
        _controllers['Age']!.text = (data['age'] ?? '').toString();
        _controllers['Gym Experience']!.text = (data['yearsJoined'] ?? '').toString();
        _controllers['Fitness Level']!.text = data['fitnessLevel']?.toString() ?? '';
        
        debugPrint('Updated controllers:');
        debugPrint('- Username: ${_usernameController.text}');
        debugPrint('- Name: ${_controllers['Name']!.text}');
        debugPrint('- Weight: ${_controllers['Weight']!.text}');
        debugPrint('- Height: ${_controllers['Height']!.text}');
        debugPrint('- Age: ${_controllers['Age']!.text}');
        debugPrint('- Gym Experience: ${_controllers['Gym Experience']!.text}');
        debugPrint('- Fitness Level: ${_controllers['Fitness Level']!.text}');
      } catch (e, stackTrace) {
        debugPrint('Error updating controllers: $e');
        debugPrint('Stack trace: $stackTrace');
      }
    });
  }
  
  Future<void> _initializeUserDocument(String uid) async {
    try {
      debugPrint('Initializing new user document');
      await _firestore.collection('users').doc(uid).set({
        'username': _auth.currentUser?.email?.split('@').first ?? 'user${uid.substring(0, 6)}',
        'name': _auth.currentUser?.displayName ?? 'New User',
        'weight': 0,
        'heightFeet': 0,
        'heightInches': 0,
        'age': 0,
        'yearsJoined': 0,
        'fitnessLevel': 'Beginner',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('User document initialized with default values');
    } catch (e, stackTrace) {
      debugPrint('Error initializing user document: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  Future<void> _saveChanges() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // parse height back into feet/inches
    final heightParts = _controllers['Height']!.text.split(' ');
    int feet = 0, inches = 0;
    if (heightParts.length >= 3) {
      feet = int.tryParse(heightParts[0]) ?? 0;
      inches = int.tryParse(heightParts[2]) ?? 0;
    }

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'username': _usernameController.text,
        'name': _controllers['Name']!.text,
        'weight': int.tryParse(_controllers['Weight']!.text) ?? 0,
        'age': int.tryParse(_controllers['Age']!.text) ?? 0,
        'yearsJoined': int.tryParse(_controllers['Gym Experience']!.text) ?? 0,
        'heightFeet': feet,
        'heightInches': inches,
        'fitnessLevel': _controllers['Fitness Level']!.text,
      });
      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error updating profile')));
      }
    }
  }

  Future<void> _logout() async {
    try {
      await _auth.signOut();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error signing out')));
      }
    }
  }

  // Load all posts to find the correct position in the main feed
  void _loadAllPosts() {
    _firestore
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _allPosts = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'id': doc.id,
              ...data,
            };
          }).toList();
        });
      }
    });
  }
  
  // Find the index of a post in the main feed
  int _findPostIndexInFeed(String postId) {
    return _allPosts.indexWhere((post) => post['id'] == postId);
  }

  @override
  void dispose() {
    _controllers.values.forEach((c) => c.dispose());
    _usernameController.dispose();
    _postsSubscription?.cancel();
    super.dispose();
  }

  Widget _buildAttributeRow(String label) {
    final controller = _controllers[label]!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          _isEditing
              ? TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                )
              : Text(
                  controller.text.isEmpty ? '-' : controller.text,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
        ],
      ),
    );
  }

  // Load user's posts from Firestore
  void _loadUserPosts() {
    final user = _auth.currentUser;
    if (user == null) return;

    _postsSubscription = _firestore
        .collection('posts')
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) async {
      if (mounted) {
        try {
          final posts = <Map<String, dynamic>>[];
          
          // Process each post document
          for (var doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            
            // Get the latest user data for profile image
            String? profileImageUrl = data['profileImageUrl'];
            if (profileImageUrl == null || profileImageUrl.isEmpty) {
              try {
                final userDoc = await _firestore.collection('users').doc(user.uid).get();
                if (userDoc.exists) {
                  profileImageUrl = userDoc.data()?['profileImageUrl'] ?? '';
                }
              } catch (e) {
                debugPrint('Error fetching user data: $e');
              }
            }
            
            // Get the first media URL if it's a list, or use the single URL
            dynamic mediaUrl = data['mediaUrl'];
            if (mediaUrl is List && mediaUrl.isNotEmpty) {
              mediaUrl = mediaUrl.first;
            }
            
            final post = {
              'id': doc.id,
              'mediaUrl': mediaUrl?.toString() ?? '',
              'isVideo': data['isVideo'] ?? false,
              'caption': data['caption'] ?? '',
              'likes': data['likes'] ?? 0,
              'comments': data['comments'] ?? 0,
              'timestamp': data['timestamp'] ?? Timestamp.now(),
              'username': data['username'] ?? 'user',
              'profileImageUrl': profileImageUrl ?? '',
              'timeAgo': _formatTimeAgo((data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now()),
            };
            
            posts.add(post);
          }
          
          if (mounted) {
            setState(() {
              _userPosts = posts;
            });
          }
        } catch (e) {
          debugPrint('Error processing posts: $e');
        }
      }
    }, onError: (error) {
      debugPrint('Error loading user posts: $error');
    });
  }

  // Format timestamp to relative time (e.g., "2d ago")
  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // Build a post preview that shows the user's actual posts
  Widget _buildPostPreview(int index) {
    if (index >= _userPosts.length) {
      return Container();
    }

    final post = _userPosts[index];
    final isVideo = post['isVideo'] == true;
    
    return GestureDetector(
      onTap: () {
        // Navigate back to the main screen and pass the post ID to scroll to
        Navigator.popUntil(context, (route) {
          if (route.settings.name == '/') {
            // Use a callback to communicate with the parent widget
            if (widget.onPostSelected != null) {
              widget.onPostSelected!(post['id']);
            }
            return true;
          }
          return false;
        });
      },
      child: Container(
        width: 120,
        height: 120,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[800]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Show post image or video thumbnail
              if (post['mediaUrl'] != null && post['mediaUrl'].toString().isNotEmpty)
                CachedNetworkImage(
                  imageUrl: post['mediaUrl'].toString(),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[800],
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[800],
                    child: const Icon(Icons.broken_image, color: Colors.white24, size: 32),
                  ),
                )
              else
                Container(
                  color: Colors.grey[800],
                  child: const Icon(Icons.broken_image, color: Colors.white24, size: 32),
                ),
              if (isVideo)
                const Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: EdgeInsets.all(6.0),
                    child: Icon(Icons.videocam, color: Colors.white, size: 20),
                  ),
                ),
              // Time ago overlay
              Positioned(
                left: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatTimeAgoCompact((post['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now()),
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Format time in a compact way for thumbnails
  String _formatTimeAgoCompact(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) return 'now';
    if (difference.inHours < 1) return '${difference.inMinutes}m';
    if (difference.inDays < 1) return '${difference.inHours}h';
    if (difference.inDays < 30) return '${difference.inDays}d';
    
    final months = (difference.inDays / 30).floor();
    if (months < 12) return '${months}mo';
    
    final years = (months / 12).floor();
    return '${years}y';
  }


  // ------------------- BUILD -------------------
  // Calculate post frequency for the last 28 days
  Map<DateTime, int> _calculatePostFrequency() {
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 27)); // Last 28 days including today
    final postFrequency = <DateTime, int>{};
    
    // Initialize all dates with 0 posts
    for (var i = 0; i < 28; i++) {
      final date = startDate.add(Duration(days: i));
      // Store only the date part (without time)
      final dateOnly = DateTime(date.year, date.month, date.day);
      postFrequency[dateOnly] = 0;
    }
    
    // Count posts for each date
    for (var post in _userPosts) {
      final timestamp = post['timestamp'] as Timestamp?;
      if (timestamp != null) {
        final postDate = timestamp.toDate();
        final dateOnly = DateTime(postDate.year, postDate.month, postDate.day);
        
        // Only count posts from the last 28 days
        if (dateOnly.isAfter(startDate.subtract(const Duration(days: 1)))) {
          postFrequency[dateOnly] = (postFrequency[dateOnly] ?? 0) + 1;
        }
      }
    }
    
    return postFrequency;
  }
  
  // Get color based on post count for a day
  Color _getColorForPostCount(int count) {
    if (count == 0) return Colors.grey[900]!; // No posts - darkest
    if (count == 1) return Colors.green[900]!; // 1 post - dark green
    if (count == 2) return Colors.green[700]!; // 2 posts - medium dark green
    if (count == 3) return Colors.green[500]!; // 3 posts - medium green
    return Colors.green[300]!; // 4+ posts - light green
  }
  
  // Get day abbreviation (S, M, T, W, T, F, S)
  String _getDayAbbreviation(int dayIndex) {
    const days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return days[dayIndex];
  }
  
  // Format date for tooltip
  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }

  Widget _buildActivityCalendar() {
    final postFrequency = _calculatePostFrequency();
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 27)); // Last 28 days
    
    // Get the weekday of the start date (0 = Sunday, 1 = Monday, etc.)
    final startWeekday = startDate.weekday % 7;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Exercise Activity',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          
          // Day of week headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              return SizedBox(
                width: 24,
                child: Text(
                  _getDayAbbreviation(index),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              );
            }),
          ),
          
          const SizedBox(height: 8),
          
          // Calendar grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
              childAspectRatio: 1,
            ),
            itemCount: 7 * 5, // 5 rows x 7 days
            itemBuilder: (context, index) {
              // Calculate the day this cell represents
              final dayOffset = index - startWeekday;
              if (dayOffset < 0 || dayOffset > 27) {
                // Empty cell for alignment
                return const SizedBox.shrink();
              }
              
              final cellDate = startDate.add(Duration(days: dayOffset));
              final dateKey = DateTime(cellDate.year, cellDate.month, cellDate.day);
              final postCount = postFrequency[dateKey] ?? 0;
              
              return Tooltip(
                message: postCount > 0 
                    ? '$postCount ${postCount == 1 ? 'post' : 'posts'} on ${_formatDate(cellDate)}'
                    : 'No posts on ${_formatDate(cellDate)}',
                child: Container(
                  decoration: BoxDecoration(
                    color: _getColorForPostCount(postCount),
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(
                      color: Colors.grey[800]!,
                      width: 0.5,
                    ),
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Less',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              _buildActivityLevel(Colors.green[900]!),
              const SizedBox(width: 2),
              _buildActivityLevel(Colors.green[700]!),
              const SizedBox(width: 2),
              _buildActivityLevel(Colors.green[500]!),
              const SizedBox(width: 2),
              _buildActivityLevel(Colors.green[300]!),
              const SizedBox(width: 8),
              const Text(
                'More',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityLevel(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = _auth.currentUser;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: _logout),
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit, color: Colors.white),
            onPressed: () {
              if (_isEditing) {
                _saveChanges();
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // user section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                CircleAvatar(radius: 30, backgroundColor: Colors.grey[800], child: const Icon(Icons.person, color: Colors.white)),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _isEditing 
                      ? TextField(
                          controller: _usernameController,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
                          decoration: const InputDecoration(
                            hintText: 'Enter username',
                            hintStyle: TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        )
                      : Text(
                          _usernameController.text.isNotEmpty 
                              ? '@${_usernameController.text}' 
                              : '@user',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)
                        ),
                  const SizedBox(height: 4),
                  Text(user?.email ?? '', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                ])),
              ]),
            ),
            const SizedBox(height: 32),
            // attributes
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Personal Information', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  if (_isEditing) const Text('Editing...', style: TextStyle(color: Colors.blueAccent)),
                ]),
                const SizedBox(height: 24),
                ..._controllers.keys.map(_buildAttributeRow),
              ]),
            ),
            const SizedBox(height: 32),
            // recent posts
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Recent Posts', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _userPosts.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          'No posts yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : SizedBox(
                        height: 140,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _userPosts.length,
                          itemBuilder: (context, index) => _buildPostPreview(index),
                        ),
                      ),
              ]),
            ),
            const SizedBox(height: 32),
            // Activity calendar
            _buildActivityCalendar(),
          ]),
        ),
      ),
    );
  }
}