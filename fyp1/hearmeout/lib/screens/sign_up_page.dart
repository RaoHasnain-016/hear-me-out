import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();

  String _name = '';
  String _email = '';
  String _password = '';
  String _confirmPassword = '';
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isOtpSent = false;
  bool _isOtpVerified = false;
  bool _isLoading = false;
  String _otp = '';

  static const String _brevoApiKey = String.fromEnvironment('BREVO_API_KEY');
  final String _brevoApiUrl = 'https://api.brevo.com/v3/smtp/email';

  bool _hasUpperCase = false;
  bool _hasLowerCase = false;
  bool _hasDigit = false;
  bool _hasSpecialChar = false;
  bool _hasMinLength = false;
  bool _passwordsMatch = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validatePassword);
    _confirmPasswordController.addListener(_checkPasswordsMatch);
  }

  void _validatePassword() {
    String password = _passwordController.text;
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
      _passwordsMatch = _passwordController.text == _confirmPasswordController.text &&
          _passwordController.text.isNotEmpty &&
          _confirmPasswordController.text.isNotEmpty;
    });
  }

  Widget _buildPasswordCondition(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isMet ? '✅' : '❌',
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isMet ? Colors.green : Colors.red,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordRequirements() {
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Colors.grey[300]!),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Password Requirements:',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            _buildPasswordCondition('At least 1 uppercase letter (A-Z)', _hasUpperCase),
            _buildPasswordCondition('At least 1 lowercase letter (a-z)', _hasLowerCase),
            _buildPasswordCondition('At least 1 digit (0-9)', _hasDigit),
            _buildPasswordCondition('At least 1 special character', _hasSpecialChar),
            _buildPasswordCondition('Minimum 8 characters', _hasMinLength),
            if (_confirmPasswordController.text.isNotEmpty)
              _buildPasswordCondition(
                _passwordsMatch ? 'Passwords match' : 'Passwords don\'t match',
                _passwordsMatch,
              ),
          ],
        ),
      ),
    );
  }

  // Future<void> _sendOtp() async {
  //   if (_emailController.text.isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Please enter your email first')),
  //     );
  //     return;
  //   }

  //   setState(() {
  //     _isLoading = true;
  //   });

  //   try {
  //     // Check if the email is already registered using Firebase
  //     List<String> signInMethods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(_emailController.text);
  //     // If the email is already registered, show an error message
  //     debugPrint('$signInMethods');
  //     if (signInMethods.isNotEmpty) {
  //       setState(() {
  //         _isLoading = false;
  //       });
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('This email is already registered. Please login.')),
  //       );
  //       return; // Do not proceed further if the email is already registered
  //     }

  //     // If the email is not registered, proceed to send OTP
  //     _otp = (100000 + DateTime.now().millisecondsSinceEpoch % 900000).toString();

  //     // Send OTP email via Brevo API
  //     final response = await http.post(
  //       Uri.parse(_brevoApiUrl),
  //       headers: {
  //         'accept': 'application/json',
  //         'api-key': _brevoApiKey,
  //         'content-type': 'application/json',
  //       },
  //       body: jsonEncode({
  //         'sender': {
  //           'name': 'hear me out',
  //           'email': 'hearmeout879@gmail.com',
  //         },
  //         'to': [
  //           {
  //             'email': _emailController.text,
  //             'name': _nameController.text,
  //           }
  //         ],
  //         'subject': 'Email Verification OTP',
  //         'htmlContent': '''
  //         <html>
  //           <body>
  //             <h1>Email Verification OTP</h1>
  //             <p>Your OTP is: <strong>$_otp</strong></p>
  //             <p>This OTP will expire in 5 minutes.</p>
  //           </body>
  //         </html>
  //       ''',
  //       }),
  //     );
  //     debugPrint('${response.statusCode}');
  //     if (response.statusCode == 201) {
  //       setState(() {
  //         _isOtpSent = true;
  //         _isLoading = false;
  //       });
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('OTP sent successfully')),
  //       );
  //     } else {
  //       throw Exception('Failed to send OTP');
  //     }
  //   } catch (e) {
  //     setState(() {
  //       _isLoading = false;
  //     });
  //     print(e);
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Error: ${e.toString()}')),
  //     );
  //   }
  // }


  Future<void> _verifyOtp() async {
    if (_otpController.text == _otp) {
      setState(() {
        _isOtpVerified = true;
        _isOtpSent = false;
        _otpController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email verified successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP')),
      );
    }
  }

 Future<void> _registerUser() async {
  try {
    final FirebaseAuth _auth = FirebaseAuth.instance;

    final UserCredential userCredential =
        await _auth.createUserWithEmailAndPassword(
      email: _emailController.text,
      password: _passwordController.text,
    );

    final String uid = userCredential.user!.uid;

    // ⭐ ADD USER TO FIRESTORE
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'uid': uid,
      'email': _emailController.text.trim(),
      'name': _nameController.text.trim(),   // optional
      'createdAt': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('User ${userCredential.user?.email} registered successfully!')),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  } on FirebaseAuthException catch (e) {
    String errorMessage;
    if (e.code == 'email-already-in-use') {
      errorMessage = 'This email is already registered. Please login or use another email.';
    } else if (e.code == 'invalid-email') {
      errorMessage = 'The email address is not valid.';
    } else if (e.code == 'weak-password') {
      errorMessage = 'The password is too weak.';
    } else {
      errorMessage = 'An error occurred. Please try again later.';
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(errorMessage)),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${e.toString()}')),
    );
  }
}



  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // if (!_isOtpVerified) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(content: Text('Please verify your email first')),
      //   );
      //   return;
      // }
      if (!_hasUpperCase || !_hasLowerCase || !_hasDigit || !_hasSpecialChar ||
          !_hasMinLength || !_passwordsMatch) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please meet all password requirements')),
        );
        return;
      }

      _formKey.currentState!.save();
      _registerUser();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
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
                        Icons.headphones,
                        size: 72,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Signup Form Card
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
                                'Create Account',
                                style: Theme.of(context).textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Sign up to get started',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 32),
                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Full Name',
                                  hintText: 'Enter your full name',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  hintText: 'Enter your email',
                                  prefixIcon: const Icon(Icons.email_outlined),
                                  // suffixIcon: _isOtpVerified
                                  //     ? const Icon(Icons.verified, color: Colors.green)
                                  //     : TextButton(
                                  //   onPressed: _isLoading ? null : _sendOtp,
                                  //   child: _isLoading
                                  //       ? const SizedBox(
                                  //     width: 20,
                                  //     height: 20,
                                  //     child: CircularProgressIndicator(
                                  //       strokeWidth: 2,
                                  //     ),
                                  //   )
                                  //       : const Text('Send OTP'),
                                  // ),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter an email';
                                  }
                                  if (!value.contains('@')) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              // if (_isOtpSent && !_isOtpVerified) ...[
                              //   const SizedBox(height: 16),
                              //   TextFormField(
                              //     controller: _otpController,
                              //     decoration: InputDecoration(
                              //       labelText: 'Enter OTP',
                              //       hintText: 'Enter the 6-digit code',
                              //       prefixIcon: const Icon(Icons.lock_outline),
                              //       suffixIcon: TextButton(
                              //         onPressed: _verifyOtp,
                              //         child: const Text('Verify'),
                              //       ),
                              //     ),
                              //     keyboardType: TextInputType.number,
                              //   ),
                              // ],
                              // if (_isOtpVerified) ...[
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _passwordController,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    hintText: 'Enter your password',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isPasswordVisible
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isPasswordVisible = !_isPasswordVisible;
                                        });
                                      },
                                    ),
                                  ),
                                  obscureText: !_isPasswordVisible,
                                  keyboardType: TextInputType.text,
                                  onChanged: (value) => _validatePassword(),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  decoration: InputDecoration(
                                    labelText: 'Confirm Password',
                                    hintText: 'Re-enter your password',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isConfirmPasswordVisible
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                        });
                                      },
                                    ),
                                  ),
                                  obscureText: !_isConfirmPasswordVisible,
                                  keyboardType: TextInputType.text,
                                  onChanged: (value) => _checkPasswordsMatch(),
                                ),
                                _buildPasswordRequirements(),
                              // ],
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _submitForm,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    child: _isLoading
                                        ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                        : const Text(
                                      'Sign Up',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account?',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => LoginPage()),
                            );
                          },
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
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
