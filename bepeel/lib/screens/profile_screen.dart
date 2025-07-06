import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show SetOptions;

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

  const ProfileScreen({
    super.key,
    required this.userId,
    required this.isCurrentUser,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isEditing = false;
  bool _isLoading = true;
  Map<String, dynamic> _userDoc = {};

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

  @override
  void dispose() {
    _controllers.values.forEach((c) => c.dispose());
    _usernameController.dispose();
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

  // ---------- UI helpers for posts and calendar (unchanged) ----------
  Widget _buildPostPreview() {
    return Container(
      width: 120,
      height: 120,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(8)),
      child: Stack(fit: StackFit.expand, children: [
        Icon(Icons.fitness_center, color: Colors.grey[600], size: 40),
        const Positioned(bottom: 8, left: 8, child: Text('2d ago', style: TextStyle(color: Colors.grey, fontSize: 12))),
      ]),
    );
  }

  Widget _buildActivityCalendar() {
    final data = List.generate(6, (i) => List.generate(5, (j) => (i + j) % 5));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: Text('Last 30 Days Activity', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(8)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [const SizedBox(width: 24), ...['M', 'T', 'W', 'T', 'F'].map((d) => Expanded(child: Text(d, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 12))))]),
          const SizedBox(height: 8),
          Row(children: [
            Column(children: ['30d', '20d', '10d', 'now'].map((l) => Container(height: 35, width: 24, alignment: Alignment.centerLeft, child: Text(l, style: const TextStyle(color: Colors.grey, fontSize: 10)))).toList()),
            const SizedBox(width: 4),
            Expanded(
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, crossAxisSpacing: 4, mainAxisSpacing: 4),
                itemCount: 30,
                itemBuilder: (context, idx) {
                  final r = idx ~/ 5, c = idx % 5;
                  return Container(decoration: BoxDecoration(color: activityColors[data[r][c]], borderRadius: BorderRadius.circular(2)));
                },
              ),
            ),
          ]),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('Less', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(width: 8),
            ...activityColors.values.map((v) => Container(width: 16, height: 16, margin: const EdgeInsets.symmetric(horizontal: 2), decoration: BoxDecoration(color: v, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(width: 8),
            const Text('More', style: TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
        ]),
      ),
    ]);
  }

  // ------------------- BUILD -------------------
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
                SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: List.generate(5, (_) => _buildPostPreview()))),
              ]),
            ),
            const SizedBox(height: 32),
            // activity calendar
            Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Fitness Activity', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 16), _buildActivityCalendar()]),),
          ]),
        ),
      ),
    );
  }
}