import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _usernameController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightFeetController = TextEditingController();
  final _heightInchesController = TextEditingController();
  final _yearsJoinedController = TextEditingController();
  String _selectedFitnessLevel = 'Beginner';
  String _errorMessage = '';
  bool _isLoading = false;

  final List<String> _fitnessLevels = ['Beginner', 'Intermediate', 'Hardcore'];

  @override
  void dispose() {
    _usernameController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightFeetController.dispose();
    _heightInchesController.dispose();
    _yearsJoinedController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    final username = _usernameController.text.trim();
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final age = _ageController.text.trim();
    final weight = _weightController.text.trim();
    final heightFeet = _heightFeetController.text.trim();
    final heightInches = _heightInchesController.text.trim();
    final yearsJoined = _yearsJoinedController.text.trim();

    // Basic validation
    if (username.isEmpty || name.isEmpty || email.isEmpty || password.isEmpty ||
        age.isEmpty || weight.isEmpty || heightFeet.isEmpty || heightInches.isEmpty || yearsJoined.isEmpty) {
      setState(() {
        _errorMessage = 'All fields are required';
      });
      return;
    }

    // Numeric validation
    if (!RegExp(r'^\d+$').hasMatch(age) || !RegExp(r'^\d+$').hasMatch(weight) ||
        !RegExp(r'^\d+$').hasMatch(heightFeet) || !RegExp(r'^\d+$').hasMatch(heightInches) ||
        !RegExp(r'^\d+$').hasMatch(yearsJoined)) {
      setState(() {
        _errorMessage = 'Please enter valid numbers for age, weight, height, and years joined';
      });
      return;
    }

    // Range validation
    if (int.parse(age) < 13 || int.parse(age) > 120) {
      setState(() {
        _errorMessage = 'Please enter a valid age between 13 and 120';
      });
      return;
    }

    if (int.parse(heightFeet) > 8 || int.parse(heightInches) >= 12) {
      setState(() {
        _errorMessage = 'Please enter a valid height (feet < 9, inches < 12)';
      });
      return;
    }

    // Email validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      setState(() {
        _errorMessage = 'Please enter a valid email address';
      });
      return;
    }

    // Password validation
    if (password.length < 6) {
      setState(() {
        _errorMessage = 'Password must be at least 6 characters long';
      });
      return;
    }

    // Password match validation
    if (password != confirmPassword) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Create user account
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update user display name
      await userCredential.user?.updateDisplayName(name);

      // Here you would typically store the additional user data in Firestore
      // For now, we'll just print it
      print('Additional user data to be stored:');
      print('Age: $age');
      print('Weight: $weight lbs');
      print('Height: $heightFeet\'$heightInches"');
      print('Years Joined: $yearsJoined');
      print('Fitness Level: $_selectedFitnessLevel');

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // The StreamBuilder in main.dart will automatically navigate to MainScreen
      // because the auth state has changed

    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'An error occurred during signup';
      });
      // Show error in a snackbar as well
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'An error occurred during signup'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Create Account',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              _buildTextField(
                controller: _usernameController,
                hintText: 'Username',
                icon: Icons.person,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _nameController,
                hintText: 'Full Name',
                icon: Icons.badge,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emailController,
                hintText: 'Email',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _ageController,
                hintText: 'Age',
                icon: Icons.cake,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _weightController,
                hintText: 'Weight (lbs)',
                icon: Icons.monitor_weight,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _heightFeetController,
                      hintText: 'Height (ft)',
                      icon: Icons.height,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTextField(
                      controller: _heightInchesController,
                      hintText: 'Height (in)',
                      icon: Icons.height,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _yearsJoinedController,
                hintText: 'Years of Experience',
                icon: Icons.timeline,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedFitnessLevel,
                    isExpanded: true,
                    dropdownColor: Colors.grey[900],
                    style: const TextStyle(color: Colors.white),
                    icon: const Icon(Icons.fitness_center, color: Colors.white),
                    items: _fitnessLevels.map((String level) {
                      return DropdownMenuItem<String>(
                        value: level,
                        child: Text(level),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedFitnessLevel = newValue;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _passwordController,
                hintText: 'Password',
                icon: Icons.lock,
                isPassword: true,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _confirmPasswordController,
                hintText: 'Confirm Password',
                icon: Icons.lock_outline,
                isPassword: true,
              ),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _signup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Sign Up',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      obscureText: isPassword,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        prefixIcon: Icon(icon, color: Colors.grey),
      ),
    );
  }
}
