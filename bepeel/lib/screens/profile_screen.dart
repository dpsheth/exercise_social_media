import 'package:flutter/material.dart';

const Map<int, Color> activityColors = {
  0: Color(0xFF1F1F1F), // Empty/no activity
  1: Color(0xFF0E4429), // Light activity
  2: Color(0xFF006D32), // Medium activity
  3: Color(0xFF26A641), // High activity
  4: Color(0xFF39D353), // Very high activity
};

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  final Map<String, TextEditingController> _controllers = {
    'Name': TextEditingController(text: 'John Doe'),
    'Height': TextEditingController(text: '5 feet 10 inches'),
    'Weight': TextEditingController(text: '160 lbs'),
    'Age': TextEditingController(text: '28 years'),
    'Years Joined': TextEditingController(text: '3'),
    'Fitness Level': TextEditingController(text: 'Hardcore'),
  };

  @override
  void dispose() {
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  Widget _buildAttributeRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          _isEditing
              ? TextField(
                  controller: _controllers[label],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                )
              : Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildPostPreview() {
    return Container(
      width: 120,
      height: 120,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Icon(
            Icons.fitness_center,
            color: Colors.grey[600],
            size: 40,
          ),
          Positioned(
            bottom: 8,
            left: 8,
            child: Text(
              '2d ago',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCalendar() {
    // Generate sample data for the last 30 days (6 rows x 5 columns)
    final List<List<int>> calendarData = List.generate(6, (i) => 
      List.generate(5, (j) {
        // Generate activity levels (0-4)
        return (i + j) % 5; // Pattern for demo, replace with actual data
      })
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 16.0),
          child: Text(
            'Last 30 Days Activity',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Days of week labels
              Row(
                children: [
                  const SizedBox(width: 24),
                  ...['M', 'T', 'W', 'T', 'F'].map((day) => Expanded(
                    child: Text(
                      day,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )),
                ],
              ),
              const SizedBox(height: 8),
              // Calendar grid
              Row(
                children: [
                  // Time labels on the left
                  Column(
                    children: [
                      ...['30d', '20d', '10d', 'now'].map((label) => Container(
                        height: 35,
                        width: 24,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          label,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 10,
                          ),
                        ),
                      )),
                    ],
                  ),
                  const SizedBox(width: 4),
                  // Activity squares
                  Expanded(
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                        childAspectRatio: 1, // Make squares
                      ),
                      itemCount: 30, // 6 rows × 5 columns
                      itemBuilder: (context, index) {
                        final row = index ~/ 5;
                        final col = index % 5;
                        return Container(
                          decoration: BoxDecoration(
                            color: activityColors[calendarData[row][col]],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Less',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ...activityColors.entries.map((entry) => Container(
                    width: 16,
                    height: 16,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: entry.value,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  )),
                  const SizedBox(width: 8),
                  const Text(
                    'More',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User info section
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey[800],
                        child: const Icon(
                          Icons.person,
                          size: 30,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'user@example.com',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _isEditing ? Icons.check : Icons.edit,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            _isEditing = !_isEditing;
                          });
                          if (!_isEditing) {
                            // Save the changes
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Profile updated successfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Attributes section
                Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Personal Information',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_isEditing)
                            Text(
                              'Editing...',
                              style: TextStyle(
                                color: Colors.blue[300],
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ..._controllers.entries.map(
                        (entry) => _buildAttributeRow(
                          entry.key,
                          entry.value.text,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Recent Posts section
                Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recent Posts',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(
                            5,
                            (index) => _buildPostPreview(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Activity Calendar section
                Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Fitness Activity',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildActivityCalendar(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 