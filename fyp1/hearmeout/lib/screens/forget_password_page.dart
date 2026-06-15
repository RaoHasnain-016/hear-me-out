import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgetPasswordPage extends StatefulWidget {
  @override
  _ForgetPasswordPageState createState() => _ForgetPasswordPageState();
}

class _ForgetPasswordPageState extends State<ForgetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;

  // Firebase Authentication instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email first')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Use Firebase's password reset method
      await _auth.sendPasswordResetEmail(email: _emailController.text);
      print(_emailController.text);
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent successfully')),
      );

      // Navigate back to the login page after sending the email
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pop(context); // Go back to the login page
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.8),
              Theme.of(context).colorScheme.secondary.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // App Logo
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_reset,
                        size: 72,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Reset Password Form Card
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Reset Password',
                                style: Theme.of(context).textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Enter your email to reset password',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 32),
                              TextFormField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  hintText: 'Enter your registered email',
                                  prefixIcon: const Icon(Icons.email_outlined),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!value.contains('@')) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _isLoading ? null : _sendOtp,
                                child: _isLoading
                                    ? const CircularProgressIndicator()
                                    : const Text('Send Reset Email'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Back to Login Button
                    TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                      ),
                      label: Text(
                        'Back to Login',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
