import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'profile_settings_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  @override
  void initState() {
    super.initState();
    _checkNotificationStatus();
  }

  // Check the current notification status by requesting permission status
  Future<void> _checkNotificationStatus() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission();
    setState(() {
      _notificationsEnabled = settings.authorizationStatus == AuthorizationStatus.authorized;
    });
  }

  // Function to enable notifications
  Future<void> _enableNotifications() async {
    try {
      NotificationSettings settings = await _firebaseMessaging.requestPermission();

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        setState(() {
          _notificationsEnabled = true;
        });
      }
    } catch (e) {
      print('Error enabling notifications: $e');
    }
  }

  // Function to disable notifications
  Future<void> _disableNotifications() async {
    try {
      // When notifications are turned off, we can unsubscribe from topics or stop listening to Firebase messaging
      // This won't revoke permissions but will stop Firebase from sending notifications
      await _firebaseMessaging.unsubscribeFromTopic('general');
      setState(() {
        _notificationsEnabled = false;
      });
    } catch (e) {
      print('Error disabling notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
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
        child: ListView(
          children: [
            // Profile Section
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.white,
                foregroundColor:  Color(0xFF6200EE),
                radius: 25,
                child: Icon(Icons.person, size: 30),
              ),
              title: const Text('Profile',style: TextStyle(color: Colors.white),),
              subtitle: const Text('View and edit your profile information',style: TextStyle(color: Colors.white)),
              trailing: const Icon(Icons.arrow_forward_ios,color: Colors.white,),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileSettingsPage()),
                );
              },
            ),
            const Divider(),
        
            // Notifications Section
            SwitchListTile(
              title: const Text('Notifications',style: TextStyle(color: Colors.white),),
              subtitle: const Text('Enable/disable app notifications',style: TextStyle(color: Colors.white),),
              value: _notificationsEnabled,
              onChanged: (bool value) {
                setState(() {
                  _notificationsEnabled = value;
                });
        
                // Turn on/off notifications based on the toggle state
                if (value) {
                  _enableNotifications();
                } else {
                  _disableNotifications();
                }
              },
            ),
            const Divider(),
        
            // About Section
            ListTile(
              title: const Text('About',style: TextStyle(color: Colors.white),),
              subtitle: const Text('App version and information',style: TextStyle(color: Colors.white),),
              trailing: const Icon(Icons.arrow_forward_ios,color: Colors.white,),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('About'),
                    content: const Text('Hear Me Out v1.0.0\n\nA communication app for text and gesture conversion.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
