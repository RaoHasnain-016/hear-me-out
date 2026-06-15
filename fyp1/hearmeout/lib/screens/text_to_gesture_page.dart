import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
// import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:video_player/video_player.dart';

class TextToGesturePage extends StatefulWidget {
  const TextToGesturePage({super.key});

  @override
  _TextToGesturePageState createState() => _TextToGesturePageState();
}

class _TextToGesturePageState extends State<TextToGesturePage> {
  final TextEditingController _textController = TextEditingController();
  bool _isConverting = false;
  List<String> _imagePaths = [];
  int _currentPage = 0;
  bool _isButtonEnabled = false;
  bool _isListening = false; // Track if speech recognition is active
  bool isImagesSelected = true; // Track if Images or Videos are selected
  late String ImageText;

  // Video Player
  VideoPlayerController? _videoPlayerController;

  // stt.SpeechToText _speechToText = stt.SpeechToText(); // Speech-to-text instance

  @override
  void dispose() {
    _textController.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged); // Listen for text changes
    // _initializeSpeechRecognition(); // Initialize speech-to-text
  }

  // Initialize Speech-to-Text
  // void _initializeSpeechRecognition() async {
  //   bool available = await _speechToText.initialize();
  //   if (available) {
  //     setState(() {
  //       _isListening = false;
  //     });
  //   }
  // }

  // Listen for text changes in the text field
  void _onTextChanged() {
    setState(() {
      _isButtonEnabled = _textController.text.trim().isNotEmpty;
    });
  }

  // Start/stop speech recognition
  // void _toggleListening() async {
  //   if (_isListening) {
  //     _speechToText.stop();
  //   } else {
  //     _speechToText.listen(onResult: (result) {
  //       setState(() {
  //         _textController.text = result.recognizedWords;
  //       });
  //     });
  //   }
  //   setState(() {
  //     _isListening = !_isListening;
  //   });
  // }

  // Convert the entered text to images or videos
  void _convertTextToImages() {
    setState(() {
      _imagePaths.clear();
      _isConverting = true;
      _currentPage = 0;
    });

    String text = _textController.text.toLowerCase().trim();
    ImageText = _textController.text.replaceAll(' ', '').toLowerCase(); // Remove all spaces for images
    debugPrint("Image Text is: $ImageText");

    // Map of video phrases and their corresponding files
    Map<String, String> videoMap = {
      'hello': 'assets/videos/1.mp4',
      'hi': 'assets/videos/1.mp4',
      'good morning': 'assets/videos/3.mp4',
      'good evening': 'assets/videos/5.mp4',
      'good night': 'assets/videos/6.mp4',
      'how are you': 'assets/videos/7.mp4',
      'i am fine, thank you': 'assets/videos/8.mp4',
      'nice to meet you': 'assets/videos/9.mp4',
      'see you later': 'assets/videos/10.mp4',
      'take care': 'assets/videos/11.mp4',
      'good bye': 'assets/videos/12.mp4',
      'welcome': 'assets/videos/13.mp4',
      'thank you': 'assets/videos/14.mp4',
      'sorry': 'assets/videos/15.mp4',
      'excuse me': 'assets/videos/16.mp4',
      'no problem': 'assets/videos/17.mp4',
      'what is your name': 'assets/videos/18.mp4',
      'where are you from': 'assets/videos/19.mp4',
      'how old are you': 'assets/videos/20.mp4',
      'what do you do': 'assets/videos/21.mp4',
      'can you help me': 'assets/videos/22.mp4',
      'what time is it': 'assets/videos/23.mp4',
      'where is the bathroom': 'assets/videos/24.mp4',
      'yes': 'assets/videos/25.mp4',
      'no': 'assets/videos/26.mp4',
      'maybe': 'assets/videos/27.mp4',
      'i dont know': 'assets/videos/28.mp4',
      'i think so': 'assets/videos/29.mp4',
    };

    // Check if the entered text has a mapped video
    if (videoMap.containsKey(text)) {
      String videoPath = videoMap[text]!;

      // Dispose any previous controller
      _videoPlayerController?.dispose();

      // Initialize and play video
      _videoPlayerController = VideoPlayerController.asset(videoPath)
        ..initialize().then((_) {
          setState(() {});
          _videoPlayerController?.play();
        });

      // Show Gesture Result
      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          _isConverting = false;
        });
        _showGestureResult(); // Show video in bottom sheet
      });
    } else if (isImagesSelected) {
      // Fallback to generating images if no video found and Images is selected
      for (int i = 0; i < text.length; i++) {
        String char = text[i];
        if (char != ' ') {
          _imagePaths.add('assets/Gibli_Character/${char.toUpperCase()}.png');
        }
      }

      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          _isConverting = false;
        });
        _showGestureResult(); // Show images in bottom sheet
      });
    } else {
      // Show video for each character if Videos is selected
      for (int i = 0; i < text.length; i++) {
        String char = text[i];
        if (char != ' ') {
          String videoPath = 'assets/character_video/${char.toLowerCase()}.mp4'; // Play video for each character
          _videoPlayerController?.dispose();

          _videoPlayerController = VideoPlayerController.asset(videoPath)
            ..initialize().then((_) {
              setState(() {});
              _videoPlayerController?.play();
            });

          Future.delayed(const Duration(seconds: 1), () {
            setState(() {
              _isConverting = false;
            });
            _showGestureResult(); // Show video for each character
          });
        }
      }
    }
  }

  // Show the gesture result in a bottom sheet (either video or images)
  void _showGestureResult() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8, // Set the height of the bottom sheet
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Gesture Result',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Column(
                children: [
                  // Check if a video is playing
                  if (_videoPlayerController != null && _videoPlayerController!.value.isInitialized) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.blue, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha:  0.1),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: SizedBox(
                          height: 520, // Set a fixed height for the video
                          child: VideoPlayer(_videoPlayerController!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        // Replay the video
                        _videoPlayerController?.seekTo(Duration.zero);
                        _videoPlayerController?.play();
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        backgroundColor: Colors.blue,
                      ),
                      child: const Text('Replay Video'),
                    ),
                    const SizedBox(height: 20),
                  ],
                  // Show images if there is no video
                  if (_imagePaths.isNotEmpty) ...[
                    Expanded(
                      flex: 2,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PageView.builder(
                            itemCount: _imagePaths.length,
                            onPageChanged: (index) {
                              setState(() {
                                _currentPage = index; // Update current page
                              });
                            },
                            itemBuilder: (context, index) {
                              return GestureImage(
                                imagePath: _imagePaths[index],
                                text: ImageText[index], // Update the corresponding character
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      // Dispose the video player when the bottom sheet is closed
      _videoPlayerController?.dispose();
      setState(() {
        _videoPlayerController = null; // Set it to null after disposal
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Text to Gesture',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Container(
          height: 700,
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
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const Icon(
                  Icons.text_fields,
                  size: 80,
                  color: Colors.white,
                ).animate()
                    .fadeIn(duration: 500.ms)
                    .scale(delay: 200.ms),
                const SizedBox(height: 20),
                const Text(
                  'Enter Text to Convert',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ).animate()
                    .fadeIn(duration: 500.ms)
                    .slideY(delay: 300.ms),
                const SizedBox(height: 30),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.2),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _textController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Type your text here...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(20),
                      // suffixIcon: IconButton(
                      //   icon: Icon(
                      //     _isListening ? Icons.mic : Icons.mic_none,
                      //     color: _isListening ? Colors.red : Colors.blue, // Change color
                      //   ),
                      //   // onPressed: _toggleListening, // Toggle listening
                      //   onPressed: (){}, // Toggle listening
                      // ),
                    ),
                  ),
                ).animate()
                    .fadeIn(duration: 500.ms)
                    .slideX(delay: 400.ms),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Images",style: TextStyle(color: Colors.white,fontSize: 16),),
                    Radio(
                      value: true,
                      groupValue: isImagesSelected,
                      onChanged: (value) {
                        setState(() {
                          isImagesSelected = value!;
                        });
                      },
                    ),
                    const Text("Videos",style: TextStyle(color: Colors.white,fontSize: 16),),
                    Radio(
                      value: false,
                      groupValue: isImagesSelected,
                      onChanged: (value) {
                        setState(() {
                          isImagesSelected = value!;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _isButtonEnabled && !_isConverting ? _convertTextToImages : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: _isConverting
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Text(
                    'Convert to Gesture',
                    style: TextStyle(fontSize: 18),
                  ),
                ).animate()
                    .fadeIn(duration: 500.ms)
                    .slideY(delay: 500.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GestureImage extends StatelessWidget {
  final String imagePath;
  final String text;

  const GestureImage({super.key, required this.imagePath, required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          imagePath,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 5),
        Text(
          text,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
