import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';  // Import the login page

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({Key? key}) : super(key: key);

  @override
  _ProfileSettingsPageState createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoggedIn = false;

  // Password validation flags
  bool _hasUpperCase = false;
  bool _hasLowerCase = false;
  bool _hasDigit = false;
  bool _hasSpecialChar = false;
  bool _hasMinLength = false;
  bool _passwordsMatch = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _newPasswordController.addListener(_validatePassword);
    _confirmPasswordController.addListener(_checkPasswordsMatch);
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Check login status from SharedPreferences
  void _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('is_login') ?? false;  // Default to false if not set
    setState(() {
      _isLoggedIn = isLoggedIn;  // Update the state to reflect the login status
    });

    // If user is not logged in, show the login dialog
    if (!_isLoggedIn) {
      _showLoginDialog();
    }
  }

  // Show dialog to prompt user to login
  void _showLoginDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,  // Prevent dismissal by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Login Required'),
          content: const Text('You must log in to access your Profile.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),  // Navigate to Login Page
                      (Route<dynamic> route) => false,  // Remove all previous routes
                );
              },
              child: const Text('Login'),
            ),
          ],
        );
      },
    );
  }

  void _validatePassword() {
    String password = _newPasswordController.text;
    setState(() {
      _hasUpperCase = password.contains(RegExp(r'[A-Z]'));
      _hasLowerCase = password.contains(RegExp(r'[a-z]'));
      _hasDigit = password.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
      _hasMinLength = password.length >= 8;
      _checkPasswordsMatch();
    });
  }

  void _checkPasswordsMatch() {
    setState(() {
      _passwordsMatch = _newPasswordController.text == _confirmPasswordController.text &&
          _newPasswordController.text.isNotEmpty &&
          _confirmPasswordController.text.isNotEmpty;
    });
  }

  Future<void> _changePassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          if (_newPasswordController.text == _currentPasswordController.text) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('New password cannot be the same as current password'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          final credential = EmailAuthProvider.credential(
            email: user.email!,
            password: _currentPasswordController.text,
          );

          // Reauthenticate the user with the current password
          await user.reauthenticateWithCredential(credential);

          // If re-authentication is successful, update the password
          await user.updatePassword(_newPasswordController.text);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password updated successfully'),
              backgroundColor: Colors.green,
            ),
          );

          // Clear all the fields
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        }
      } on FirebaseAuthException catch (e) {
        // Check if the error code is incorrect password
        print(e.code);
        if (e.code == 'invalid-credential') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Current password is incorrect password'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          // If the error is not related to wrong password, show the default error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        // If any other exception occurs, show a generic error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    // If the user is not logged in, show the login dialog or block access to the content
    if (!_isLoggedIn) {
      return Scaffold(
        body: Center(child: Text('Please log in to view profile settings.')),
      );
    }

    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).primaryColor,
            Colors.white,
          ],
        ),
      ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Profile Section
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person,color: Theme.of(context).primaryColor,size: 60,)
                      ).animate()
                          .fadeIn(duration: 500.ms)
                          .scale(delay: 200.ms),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.email ?? 'user@email.com',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ).animate()
                                .fadeIn(duration: 500.ms)
                                .slideY(delay: 400.ms),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Text(
                                'Member since: ${user?.metadata.creationTime?.toLocal().toString().split(' ')[0] ?? 'N/A'}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ).animate()
                                .fadeIn(duration: 500.ms)
                                .slideY(delay: 500.ms),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Password Reset Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Change Password',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Password Form
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildPasswordField(
                            controller: _currentPasswordController,
                            isVisible: _isPasswordVisible,
                            onVisibilityChanged: (value) => setState(() => _isPasswordVisible = value),
                            label: 'Current Password',
                            icon: Icons.lock,
                          ),
                          const SizedBox(height: 20),
                          _buildPasswordField(
                            controller: _newPasswordController,
                            isVisible: _isNewPasswordVisible,
                            onVisibilityChanged: (value) => setState(() => _isNewPasswordVisible = value),
                            label: 'New Password',
                            icon: Icons.lock_outline,
                          ),
                          const SizedBox(height: 20),
                          _buildPasswordField(
                            controller: _confirmPasswordController,
                            isVisible: _isConfirmPasswordVisible,
                            onVisibilityChanged: (value) => setState(() => _isConfirmPasswordVisible = value),
                            label: 'Confirm New Password',
                            icon: Icons.lock_outline,
                          ),

                          // Password Requirements Card - Moved below the fields
                          if (_newPasswordController.text.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 20, bottom: 20),
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _passwordsMatch
                                        ? 'Passwords match ✅'
                                        : 'Passwords don\'t match ❌',
                                    style: TextStyle(
                                      color: _passwordsMatch ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  _buildPasswordCondition('Uppercase letter (A-Z)', _hasUpperCase),
                                  _buildPasswordCondition('Lowercase letter (a-z)', _hasLowerCase),
                                  _buildPasswordCondition('Number (0-9)', _hasDigit),
                                  _buildPasswordCondition('Special character (!@#\$...)', _hasSpecialChar),
                                  _buildPasswordCondition('Minimum 8 characters', _hasMinLength),
                                ],
                              ),
                            ).animate()
                                .fadeIn(duration: 300.ms)
                                .scale(delay: 100.ms),

                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _changePassword,
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 2,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                                  : const Text(
                                'Update Password',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required bool isVisible,
    required Function(bool) onVisibilityChanged,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
        prefixIcon: Icon(icon),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey[600],
          ),
          onPressed: () => onVisibilityChanged(!isVisible),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'This field is required';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordCondition(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: isMet ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: isMet ? Colors.green : Colors.red,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
