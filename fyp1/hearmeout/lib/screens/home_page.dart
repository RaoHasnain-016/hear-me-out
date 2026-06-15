import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hearmeout/screens/homecontent.dart';
import '/screens/favourite_page.dart';
import '/screens/history_page.dart';
import 'settings_page.dart';
import 'login_page.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  User? _user;

  String? imageUrl; // PROFILE IMAGE URL

  final List<Widget> _pages = [
    const HomeContent(),
    FavoritesPage(),
    HistoryPage(),
  ];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    _getCurrentUser();
    fetchUserProfile();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _getCurrentUser() {
    _user = FirebaseAuth.instance.currentUser;
    setState(() {});
  }

  /// Fetch profile image from Firestore and ensure profileImage field exists
Future<void> fetchUserProfile() async {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final docRef = FirebaseFirestore.instance.collection("users").doc(uid);

  final doc = await docRef.get();

  // If document doesn't exist, create it
  if (!doc.exists) {
    await docRef.set({
      "email": _user?.email ?? "",
      "profileImage": null,
    });
    setState(() {
      imageUrl = null;
    });
    return;
  }

  // If document exists but missing profileImage field, add it
  if (!doc.data()!.containsKey("profileImage")) {
    await docRef.update({"profileImage": null});
  }

  // Finally, set the profile image
  setState(() {
    imageUrl = doc.data()?["profileImage"];
  });
}


  /// Pick image (camera or gallery)
  Future<void> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source);
    if (file == null) return;
    uploadImage(File(file.path));
  }

 Future<void> uploadImage(File file) async {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final ref = FirebaseStorage.instance.ref().child("profilePictures/$uid.jpg");
  print(uid);
  print(ref);
  await ref.putFile(file);
  print('going');
  final url = await ref.getDownloadURL();
  print(url);
  // Ensure user doc exists and has profileImage
  final docRef = FirebaseFirestore.instance.collection("users").doc(uid);
  final doc = await docRef.get();
  if (!doc.exists) {
    await docRef.set({
      "email": _user?.email ?? "",
      "profileImage": url,
    });
  } else {
    await docRef.update({"profileImage": url});
  }

  setState(() {
    imageUrl = url;
  });
}

  /// Remove DP
  Future<void> removeDP() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .update({"profileImage": null});

    final ref =
        FirebaseStorage.instance.ref().child("profilePictures/$uid.jpg");

    await ref.delete().catchError((e) {}); // ignore if file doesn't exist

    setState(() {
      imageUrl = null;
    });
  }

  /// Bottom Sheet Options
  void showDPOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo, color: Theme.of(context).primaryColor),
                title: Text("Choose from Gallery"),
                onTap: () {
                  Navigator.pop(context);
                  pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading:
                    Icon(Icons.camera_alt, color: Theme.of(context).primaryColor),
                title: Text("Take a Photo"),
                onTap: () {
                  Navigator.pop(context);
                  pickImage(ImageSource.camera);
                },
              ),
              if (imageUrl != null)
                ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text("Remove Profile Picture"),
                  onTap: () {
                    Navigator.pop(context);
                    removeDP();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Hear Me Out',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
      ),

      drawer: Drawer(
        child: Container(
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
          child: ListView(
            padding: EdgeInsets.zero,
            children: [

              // 🔵 CUSTOM DRAWER HEADER WITH EDITABLE PROFILE PIC
              DrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: showDPOptions,
                          child: CircleAvatar(
                            radius: 35,
                            backgroundColor: Colors.white,
                            backgroundImage:
                                imageUrl != null ? NetworkImage(imageUrl!) : null,
                            child: imageUrl == null
                                ? Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Theme.of(context).primaryColor,
                                  )
                                : null,
                          )
                              .animate()
                              .fadeIn(duration: 500.ms)
                              .scale(),
                        ),

                        // pencil icon
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.edit,
                                size: 17, color: Colors.white),
                          ),
                        )
                      ],
                    ),

                    const SizedBox(height: 15),

                    Text(
                      _user?.email ?? "user@email.com",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    )
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .slideX(),
                  ],
                ),
              ),

              ListTile(
                leading: const Icon(Icons.settings, color: Colors.blue),
                title: const Text('Settings', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SettingsPage()));
                },
              ).animate().fadeIn(duration: 500.ms).slideX(),

              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Logout', style: TextStyle(color: Colors.white)),
                onTap: () => logout(),
              ).animate().fadeIn(duration: 500.ms).slideX(),
            ],
          ),
        ),
      ),

      body: _pages[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Favorites"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
        ],
      ),
    );
  }

  Future<void> logout() async {
    bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Logout'),
          content: Text('Are you sure you want to log out?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Logout')),
          ],
        );
      },
    );

    if (confirmLogout == true) {
      FirebaseAuth.instance.signOut();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setBool('is_login', false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
  }
}
