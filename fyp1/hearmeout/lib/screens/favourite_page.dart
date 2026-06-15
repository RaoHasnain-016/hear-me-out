import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';  // Import the login page

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoggedIn = false;  // Track if the user is logged in

  // Function to fetch favorite gestures from Firestore
  Stream<List<Map<String, dynamic>>> _getFavoriteGestures() {
    return _firestore
        .collection('gesture_texts')
        .where('isFavorite', isEqualTo: true) // Only fetch favorites
        .orderBy('timestamp', descending: true)  // Ensure latest favorites appear first
        .snapshots()
        .map((querySnapshot) {
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Add document ID to the data
        if (data['timestamp'] is String) {
          data['timestamp'] = DateTime.parse(data['timestamp']);
        }
        return data;
      }).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();  // Check login status when the page is initialized
  }

  // Check login status from SharedPreferences
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
          content: const Text('You must log in to access your favorite gestures.'),
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

  @override
  Widget build(BuildContext context) {
    // If the user is not logged in, show the login dialog or block access to the content
    if (!_isLoggedIn) {
      return Scaffold(
        body: Center(child: Text('Please log in to view favorite gestures.')),
      );
    }

    // If the user is logged in, fetch and show favorite gestures
    return Scaffold(
      // appBar: AppBar(
      //   title: Text('Favorite Gestures'),
      //   leading: null,
      //   backgroundColor: Theme.of(context).primaryColor,
      //   elevation: 0,
      // ),
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
        child: RefreshIndicator(
          onRefresh: () async {
            // Trigger a manual refresh by calling setState to rebuild the widget
            setState(() {});
          },
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _getFavoriteGestures(), // Stream of favorite gestures
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
        
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
        
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('No favorite gestures found.'));
              }
        
              List<Map<String, dynamic>> favoriteGestures = snapshot.data!;
              return ListView.builder(
                itemCount: favoriteGestures.length,
                itemBuilder: (context, index) {
                  Map<String, dynamic> gesture = favoriteGestures[index];
                  return GestureListItem(
                    gesture: gesture,
                    isFavorite: gesture['isFavorite'] ?? false,
                    onFavorite: () => _toggleFavorite(gesture['id'], gesture['isFavorite'] ?? false),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  // Toggle favorite status of a gesture
  Future<void> _toggleFavorite(String itemId, bool isFavorite) async {
    try {
      await _firestore.collection('gesture_texts').doc(itemId).update({
        'isFavorite': !isFavorite,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(!isFavorite ? 'Added to favorites' : 'Removed from favorites'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating favorite status: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }
}

class GestureListItem extends StatelessWidget {
  final Map<String, dynamic> gesture;
  final bool isFavorite;
  final VoidCallback onFavorite;

  GestureListItem({
    required this.gesture,
    required this.isFavorite,
    required this.onFavorite,
  });

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    DateTime date = timestamp is DateTime ? timestamp : DateTime.parse(timestamp);
    return DateFormat('MMM d, h:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onFavorite,  // You can customize this to open the detail of the item
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : null,
                ),
                onPressed: onFavorite,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gesture['gesture_text'] ?? 'No Gesture',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    SizedBox(height: 8),
                    Text(
                      _formatTimestamp(gesture['timestamp']),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
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
}
