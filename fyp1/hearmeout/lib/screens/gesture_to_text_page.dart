import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '/screens/login_page.dart';
import '/screens/sign_up_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';

class GestureToTextPage extends StatefulWidget {
  const GestureToTextPage({super.key});

  @override
  State<GestureToTextPage> createState() => _GestureToTextPageState();
}

class _GestureToTextPageState extends State<GestureToTextPage> {
  late CameraController _controller;
  late String responseMessage = ''; // To show server response
  Timer? _timer;
  late List<CameraDescription> _cameras;
  bool _isCameraInitialized = false;
  bool isRecording = false;
  bool isRecordingInProgress = false;
  bool _isLoggedIn = false; // Track if the user is logged in
  bool _isSaving = false; // Track the loading state

  // TTS and STT Initialization
  FlutterTts flutterTts = FlutterTts();
  // stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isListening = false;
  String _spokenText = "";

  // Gesture recognition text variable
  String gestureText = ''; // To display recognized gesture text

  // Initialize the camera
  @override
  void initState() {
    super.initState();
    _loadLoginStatus();
    _requestCameraPermission(); // Request camera permission before initializing camera
    // _initializeSpeechRecognition();
  }

  // Request camera permission
  Future<void> _requestCameraPermission() async {
    PermissionStatus status = await Permission.camera.request();

    if (status.isGranted) {
      // If permission is granted, initialize the camera
      _initializeCamera();
    } else {
      // If permission is denied, show an alert
      _showCameraPermissionDialog();
    }
  }

  // Dialog to show if camera permission is denied
  void _showCameraPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Camera Permission Required'),
          content: const Text(
            'This app needs camera access to capture images. Please grant camera permission.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _loadLoginStatus() async {
    try {
      print('checking login status');
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _isLoggedIn = prefs.getBool('is_login') ?? false;
          print("login status is :$_isLoggedIn");
        });
      }
    } catch (e) {
      print("Error fetching SharedPreferences: $e");
    }
  }

  // Function to toggle camera between front and back
  Future<void> _toggleCamera() async {
    if (!_controller.value.isInitialized) return;

    final direction =
        _controller.description.lensDirection == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;

    setState(() {
      _isCameraInitialized = false; // stop UI from using old controller
    });

    await _controller.dispose();

    await _initializeCamera(cameraDirection: direction);
  }

  // Modify _initializeCamera to accept camera direction as an argument
  Future<void> _initializeCamera({
    CameraLensDirection cameraDirection = CameraLensDirection.front,
  }) async {
    _cameras = await availableCameras();

    final camera = _cameras.firstWhere(
      (camera) => camera.lensDirection == cameraDirection,
      orElse: () => _cameras.first,
    );

    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _controller.initialize();

    if (!mounted) return;

    setState(() {
      _isCameraInitialized = true;
    });
  }

  // Add the button for switching camera
  IconButton _buildCameraToggleButton() {
    return IconButton(
      icon: Icon(Icons.switch_camera, color: Colors.white),
      onPressed: _toggleCamera, // Call toggle function on press
    );
  }

  @override
  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // Function to capture an image from the camera and send it to Flask server
  Future<void> _captureImage() async {
    if (isRecordingInProgress) {
      return; // Prevent making a new API request if one is already in progress
    }

    try {
      setState(() {
        isRecordingInProgress = true; // Mark the API request as in progress
      });

      // Capture the image from the camera
      final image = await _controller.takePicture();

      // Send the captured image to Flask server
      await _sendImageToServer(image);
    } catch (e) {
      setState(() {
        responseMessage = 'Error capturing image: $e';
      });
    } finally {
      setState(() {
        isRecordingInProgress = false; // Reset flag once the request is done
      });
    }
  }

  // Function to send the captured image to Flask server
  // Function to send the captured image to Flask server
  Future<void> _sendImageToServer(XFile image) async {
    try {
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);
      print("sending data");
      final response = await http.post(
        Uri.parse(
          'http://192.168.100.227:5000/upload',
        ), // Replace with your Flask server URL
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode({'image': base64Image}),
      );
      print("response from server is ${response.statusCode}");
      if (response.statusCode == 200) {
        setState(() {
          // Only update gestureText if the response body is not empty
          final responseData = jsonDecode(response.body);
          print("response data is $responseData");
          gestureText = responseData['message'] ?? 'No gesture detected';
          responseMessage = '$responseMessage' + '$gestureText';
          gestureText = responseMessage;
          print("gesture text is $gestureText");
        });
      } else {
        setState(() {
          responseMessage = '';
          print("failed to upload image");
        });
      }
    } catch (e) {
      setState(() {
        responseMessage = 'Error sending image to server: $e';
      });
    }
  }

  // Start capturing images at 3-second intervals
  void _startRecording() async {
    if (!_controller.value.isInitialized) {
      return;
    }

    setState(() {
      isRecording = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _captureImage();
    });
  }

  // Stop capturing images
  void _stopRecording() {
    if (_timer!.isActive) {
      _timer!.cancel(); // Stop the timer
    }

    // Optionally, handle cancelling any ongoing API request here
    setState(() {
      isRecordingInProgress = false; // Ensure the request is stopped
    });

    setState(() {
      isRecording = false; // Stop recording
    });
  }

  // Function to pick image from gallery or take a new one using camera
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    ); // Open gallery
    if (pickedFile == null) return;

    // Send the selected image to server
    await _sendImageToServer(XFile(pickedFile.path));
  }

  // Function to take a picture using the camera
  Future<void> _takePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
    ); // Open camera
    if (pickedFile == null) return;

    // Send the captured image to server
    await _sendImageToServer(XFile(pickedFile.path));
  }

  // Initialize Speech-to-Text
  // void _initializeSpeechRecognition() async {
  //   bool available = await _speechToText.initialize();
  //   if (available) {
  //     setState(() {
  //       _isListening = true;
  //     });
  //   }
  // }

  // Google Text-to-Speech (TTS) to speak the recognized text
  Future<void> _speakText(String text) async {
    await flutterTts.speak(text);
  }

  Future<void> _saveGestureTextToFirebase() async {
    if (!_isLoggedIn) {
      // If not logged in, show a dialog to prompt login
      _showLoginPromptDialog();
      return;
    }

    setState(() {
      _isSaving = true; // Start showing the loader
    });

    try {
      // Save gestureText to Firebase if logged in
      String timestamp = DateTime.now().toIso8601String();
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      await firestore.collection('gesture_texts').doc(timestamp).set({
        'gesture_text': gestureText,
        'timestamp': timestamp,
      });

      setState(() {
        responseMessage = 'Gesture text saved to Firebase';
      });

      // Show Snackbar for successful save
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gesture text successfully saved!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        responseMessage = 'Error saving gesture text: $e';
      });
      // Show error message in Snackbar if save fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving gesture text: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false; // Stop showing the loader
      });
    }
  }

  // Show dialog if not logged in and user tries to save the chat
  void _showLoginPromptDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Login Required'),
          content: const Text('You must log in to save the gesture text.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginPage(),
                  ), // Navigate to login page
                );
              },
              child: const Text('Login'),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SignupPage(),
                  ), // Navigate to sign up page
                );
              },
              child: const Text('Sign Up'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return Center(
        child: CircularProgressIndicator(),
      ); // Show loading while camera is initializing
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gesture To Text',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.8),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Camera Preview Container (Fullscreen)
              Expanded(
                flex: 3,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      children: [
                        if (isRecording && _controller.value.isInitialized)
                          CameraPreview(_controller),
                        if (!isRecording) // Display Camera Icon when not recording
                          Center(
                            child: Icon(
                              Icons.camera_alt,
                              size: 48,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        // Camera toggle button on top of the camera frame
                        Positioned(
                          bottom: 10,
                          right: 10,
                          child: _buildCameraToggleButton(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Controls Section (Buttons)
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        isRecording ? 'Stop Recording' : 'Start Recording',
                        isRecording ? Icons.stop : Icons.fiber_manual_record,
                        isRecording ? Colors.grey[800]! : Colors.red,
                        () {
                          if (isRecording) {
                            setState(() => isRecording = false);
                            _stopRecording();
                          } else {
                            setState(() => isRecording = true);
                            _startRecording();
                          }
                        },
                      ),
                      _buildActionButton(
                        'Choose from Gallery',
                        Icons.photo_library,
                        Colors.blue,
                        _pickImage,
                      ),
                      _buildActionButton(
                        'Take Picture with Camera',
                        Icons.camera,
                        Colors.green,
                        _takePicture,
                      ),
                      _buildActionButton(
                        'Save Chat',
                        Icons.chat,
                        Colors.yellow,
                        _saveGestureTextToFirebase,
                        enabled: gestureText
                            .isNotEmpty, // Only enable if gestureText is not empty
                      ),
                    ],
                  ),
                ),
              ),

              // Display Gesture Text without brackets or extra info
              if (gestureText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white, // Background color for the container
                      borderRadius: BorderRadius.circular(
                        15,
                      ), // Rounded corners
                      border: Border.all(
                        color: Colors.blueAccent, // Border color
                        width: 2, // Border width
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3), // Light shadow
                          blurRadius: 5, // Shadow blur radius
                          offset: Offset(0, 2), // Shadow position
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 12.0,
                    ), // Padding inside the container
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // Text displaying the gesture text
                        Expanded(
                          child: Text(
                            'Text: $gestureText',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            overflow: TextOverflow
                                .ellipsis, // Ensures the text doesn't overflow
                          ),
                        ),
                        // Speaker Icon to trigger _speakText
                        IconButton(
                          icon: Icon(
                            Icons.volume_up, // Speaker icon
                            color: Colors
                                .blueAccent, // Color of the icon (can be customized)
                            size: 30, // Icon size
                          ),
                          onPressed: () {
                            // Call the _speakText method to read out the gesture text
                            _speakText(gestureText);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed, {
    bool enabled = true, // Default to enabled
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enabled
            ? onPressed
            : null, // Only enable if 'enabled' is true
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 3,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms).scale(delay: 100.ms),
    );
  }
}
