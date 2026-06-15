import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hearmeout/screens/gesture_to_text_page.dart';
import 'package:hearmeout/screens/text_to_gesture_page.dart';

class HomeContent extends StatelessWidget {
  const HomeContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Center(
        child: SingleChildScrollView(  // Making the column scrollable
          child: Padding(
            padding: const EdgeInsets.all(16.0),  // Adding padding to prevent UI from touching the edges
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.handshake,
                  size: 100,
                  color: Color.fromARGB(255, 255, 255, 255),
                ).animate()
                    .fadeIn(duration: 500.ms)
                    .scale(delay: 200.ms),
                const SizedBox(height: 20),
                const Text(
                  'Choose Conversion Type',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ).animate()
                    .fadeIn(duration: 500.ms)
                    .slideY(delay: 300.ms),
                const SizedBox(height: 40),
                _buildConversionButton(
                  context,
                  'Text to Gesture',
                  Icons.text_fields,
                  const TextToGesturePage(),
                ).animate()
                    .fadeIn(duration: 500.ms)
                    .slideX(delay: 400.ms),
                const SizedBox(height: 20),
                _buildConversionButton(
                  context,
                  'Gesture to Text',
                  Icons.gesture,
                  GestureToTextPage(),
                ).animate()
                    .fadeIn(duration: 500.ms)
                    .slideX(delay: 500.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConversionButton(
      BuildContext context,
      String title,
      IconData icon,
      Widget page,
      ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 40),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: Colors.white,
          elevation: 5,
          shadowColor: Colors.grey.withOpacity(0.3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
