import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '/screens/login_page.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isSelectionMode = false;
  Set<String> _selectedItems = {}; // Store selected items
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;
  bool _isLogin = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _fabController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  // Function to load login status from SharedPreferences
  void _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('is_login') ?? false;  // Default to false if not set
    setState(() {
      _isLogin = isLoggedIn;
    });

    // If user is not logged in, show the login dialog
    if (!_isLogin) {
      _showLoginDialog();
    }
  }

  // Function to fetch gesture text from Firestore
  Stream<List<Map<String, dynamic>>> _getGestureHistory() {
    return _firestore
        .collection('gesture_texts')
        .orderBy('timestamp', descending: true)
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

  // Toggle selection mode for multi-select
  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedItems.clear(); // Clear selection when exiting selection mode
      }
      if (_isSelectionMode) {
        _fabController.forward();
      } else {
        _fabController.reverse();
      }
    });
  }

  // Toggle item selection (add or remove from selected items)
  void _toggleItemSelection(String itemId) {
    setState(() {
      if (_selectedItems.contains(itemId)) {
        _selectedItems.remove(itemId);
      } else {
        _selectedItems.add(itemId);
      }
    });
  }

  // Show delete confirmation dialog
  Future<void> _showDeleteConfirmationDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Selected Items'),
          content: Text('Are you sure you want to delete ${_selectedItems.length} item${_selectedItems.length > 1 ? 's' : ''}?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteSelectedItems();
              },
            ),
          ],
        );
      },
    );
  }

  // Delete selected items from Firestore
  Future<void> _deleteSelectedItems() async {
    try {
      for (String itemId in _selectedItems) {
        await _firestore.collection('gesture_texts').doc(itemId).delete();
      }
      setState(() {
        _selectedItems.clear();
        _isSelectionMode = false;
        _fabController.reverse(); // Reverse the FAB animation
      });
      // Show a success dialog after deletion
      _showSuccessDialog();
    } catch (e) {
      // Show an error dialog if deletion fails
      _showErrorDialog('Error deleting items: ${e.toString()}');
    }
  }

  // Show login dialog if the user is not logged in
  void _showLoginDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Login Required'),
          content: const Text('You must log in to access Gesture History.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                      (Route<dynamic> route) => false,
                );
              },
              child: const Text('Login'),
            ),
          ],
        );
      },
    );
  }

  // Delete a single item
  Future<void> _deleteSingleItem(String itemId) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Item'),
          content: Text('Are you sure you want to delete this item?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onPressed: () async {
                // Close the confirmation dialog first
                Navigator.of(context).pop();

                // Check if the widget is still mounted before performing any async operation
                if (!mounted) return;

                try {
                  // Delete the item from Firestore
                  await _firestore.collection('gesture_texts').doc(itemId).delete();

                  // After deletion, show success dialog
                  _showSuccessDialog();
                } catch (e) {
                  _showErrorDialog('Error deleting item: ${e.toString()}');
                }
              },
            ),
          ],
        );
      },
    );
  }

// Show success dialog after deletion
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Success'),
          content: Text('Item deleted successfully'),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                // Refresh the list after successful deletion
                setState(() {
                  // Trigger the list rebuild (trigger state update)
                });
                Navigator.of(context).pop(); // Close the success dialog
              },
            ),
          ],
        );
      },
    );
  }

// Show error dialog if deletion fails
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the error dialog
              },
            ),
          ],
        );
      },
    );
  }
  // Toggle favorite status
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text('Gesture History'),
      // ),
      body: Container(
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
        child: _isLogin
            ? StreamBuilder<List<Map<String, dynamic>>>(
          stream: _getGestureHistory(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
        
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
        
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('No Chat History found.'));
            }
        
            List<Map<String, dynamic>> gestureHistory = snapshot.data!;
        
            // Ensure the index is within bounds
            return AnimatedList(
              initialItemCount: gestureHistory.length,
              itemBuilder: (context, index, animation) {
                if (index >= gestureHistory.length) {
                  // Return an empty widget if the index is out of bounds
                  return SizedBox.shrink();
                }
        
                Map<String, dynamic> gesture = gestureHistory[index];
        
                return SlideTransition(
                  position: animation.drive(
                    Tween(
                      begin: Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).chain(CurveTween(curve: Curves.easeOut)),
                  ),
                  child: FadeTransition(
                    opacity: animation,
                    child: GestureListItem(
                      gesture: gesture,
                      isSelected: _selectedItems.contains(gesture['id']),
                      showCheckbox: _isSelectionMode,
                      onSelect: () => _toggleItemSelection(gesture['id']),
                      onDelete: () => _deleteSingleItem(gesture['id']),
                      onFavorite: () => _toggleFavorite(
                        gesture['id'],
                        gesture['isFavorite'] ?? false,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        )
            : Center(child: Text('Please log in to view gesture history.')),
      ),
    );
  }
}

class GestureListItem extends StatefulWidget {
  final Map<String, dynamic> gesture;
  final bool isSelected;
  final bool showCheckbox;
  final VoidCallback onSelect;
  final VoidCallback onDelete;
  final VoidCallback onFavorite;

  GestureListItem({
    required this.gesture,
    required this.isSelected,
    required this.showCheckbox,
    required this.onSelect,
    required this.onDelete,
    required this.onFavorite,
  });

  @override
  _GestureListItemState createState() => _GestureListItemState();
}

class _GestureListItemState extends State<GestureListItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    DateTime date = timestamp is DateTime ? timestamp : DateTime.parse(timestamp);
    return DateFormat('MMM d, h:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: widget.showCheckbox ? widget.onSelect : null,
          onTapDown: (_) => _controller.forward(),
          onTapUp: (_) => _controller.reverse(),
          onTapCancel: () => _controller.reverse(),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: widget.isSelected
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  if (widget.showCheckbox)
                    AnimatedSwitcher(
                      duration: Duration(milliseconds: 200),
                      child: Checkbox(
                        key: ValueKey<bool>(widget.isSelected),
                        value: widget.isSelected,
                        onChanged: (_) => widget.onSelect(),
                      ),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.gesture['gesture_text'] ?? 'No Gesture',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        SizedBox(height: 8),
                        Text(
                          _formatTimestamp(widget.gesture['timestamp']),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!widget.showCheckbox) ...[ // Show icons only if not in selection mode
                    IconButton(
                      icon: Icon(
                        widget.gesture['isFavorite'] == true
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: widget.gesture['isFavorite'] == true
                            ? Colors.red
                            : null,
                      ),
                      onPressed: widget.onFavorite,
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline),
                      onPressed: widget.onDelete,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
