import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'chatPage.dart';
import 'home_page.dart';
import 'login.dart';
import 'services/config_service.dart';
import 'services/favorite_service.dart';
import 'services/user_service.dart';

// Temporary main() for standalone testing - remove when integrating with main.dart
void main() {
  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      initialRoute: '/profile',
      routes: {
        '/home': (context) => HomePageUI(),
        '/chat': (context) => ChatOngoing(),
        '/profile': (context) => Profile(),
        '/login': (context) => LoginScreen(),
      },
    );
  }
}

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final _userService = UserService();
  final _favoriteService = FavoriteService();
  final _configService = ConfigService();
  StreamSubscription<User?>? _authSub;
  StreamSubscription<List<FavoriteRestaurant>>? _favoritesSub;
  List<FavoriteRestaurant> _favorites = [];
  int _favoriteCount = 0;
  bool _favoritesLoading = true;
  Map<String, dynamic>? _userProfile;

  void _startAuthListener() {
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      _favoritesSub?.cancel();

      if (user == null) {
        if (!mounted) return;
        setState(() {
          _userProfile = null;
          _favorites = [];
          _favoriteCount = 0;
          _favoritesLoading = false;
        });
        return;
      }

      _loadUserProfile();
      setState(() {
        _favoritesLoading = true;
      });

      _favoritesSub = _favoriteService.streamFavorites(user.uid).listen((items) {
        if (!mounted) return;
        setState(() {
          _favorites = items;
          _favoriteCount = items.length;
          _favoritesLoading = false;
        });
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _startAuthListener();
  }

  @override
  void dispose() {
    _favoritesSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final profile = await _userService.getUserProfile(user.uid);
      if (mounted) {
        setState(() {
          _userProfile = profile;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    
    // Show bottom sheet with camera and gallery options
    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_camera, color: Colors.white),
                title: const Text(
                  'Take a photo',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'SF Compact Rounded',
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final pickedFile = await picker.pickImage(
                    source: ImageSource.camera,
                    maxWidth: 512,
                    maxHeight: 512,
                    imageQuality: 85,
                    preferredCameraDevice: CameraDevice.front,
                  );
                  if (pickedFile != null && mounted) {
                    _updateProfilePicture(File(pickedFile.path));
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white),
                title: const Text(
                  'Choose from gallery',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'SF Compact Rounded',
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final pickedFile = await picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 512,
                    maxHeight: 512,
                    imageQuality: 85,
                  );
                  if (pickedFile != null && mounted) {
                    _updateProfilePicture(File(pickedFile.path));
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateProfilePicture(File imageFile) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Upload image and update profile
      await _userService.updateProfilePicture(
        userId: user.uid,
        profileImage: imageFile,
      );

      // Reload profile data and refresh the UI
      await _loadUserProfile();
    } catch (e) {
      debugPrint('Error updating profile picture: $e');
    }
  }

  Future<void> _updateDisplayName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final controller = TextEditingController(text: user.displayName ?? '');
    
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            'Update Display Name',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'SF Compact Rounded',
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'SF Compact Rounded',
            ),
            decoration: InputDecoration(
              labelText: 'Display Name',
              labelStyle: const TextStyle(
                color: Color(0xFFA0A0A0),
                fontFamily: 'SF Compact Rounded',
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Color(0xFF4C0041)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Color(0xFF74004A), width: 2),
              ),
              filled: true,
              fillColor: const Color(0xFF4C0041).withOpacity(0.3),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFFA0A0A0),
                  fontFamily: 'SF Compact Rounded',
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isNotEmpty) {
                  Navigator.pop(context);
                  try {
                    await _userService.updateDisplayName(
                      userId: user.uid,
                      displayName: newName,
                    );
                    await _loadUserProfile();
                  } catch (e) {
                    debugPrint('Error updating display name: $e');
                  }
                }
              },
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Color(0xFF74004A),
                  fontFamily: 'SF Compact Rounded',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    ).then((_) {
      // Dispose controller after dialog is fully dismissed
      controller.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'lib/assets/gradient/Gradients.png',
                fit: BoxFit.cover,
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'You are not signed in. Please log in to view your profile.',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF74004A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                    ),
                    child: Text(
                      'Log In',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Material(
      color: const Color(0xFF121212),
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: const Color(0xFF121212)),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'lib/assets/gradient/Gradients.png',
                fit: BoxFit.cover,
              ),
            ),
            // Main Content Area
            Positioned.fill(
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 50, bottom: 110),
                    child: Column(
                      children: [
                  // Profile Header - Centered
                  Column(
                                children: [
                                  // Profile picture
                                  GestureDetector(
                                    onTap: _pickImage,
                                    child: Container(
                                      width: 100,
                                      height: 100,
                                      padding: const EdgeInsets.all(3),
                                      decoration: ShapeDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment(0.50, 0.00),
                                          end: Alignment(0.50, 1.00),
                                          colors: [const Color(0xFF74004A), const Color(0xFF197400)],
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(50),
                                        ),
                                      ),
                                      child: Container(
                                      decoration: ShapeDecoration(
                                        color: const Color(0xFF121212),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(50),
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(50),
                                        child: (_userProfile?['profileImageUrl'] as String?) != null || user.photoURL != null
                                            ? Image.network(
                                                (_userProfile?['profileImageUrl'] as String?) ?? user.photoURL!,
                                                fit: BoxFit.cover,
                                                width: 94,
                                                height: 94,
                                                errorBuilder: (context, error, stackTrace) {
                                                  debugPrint('Error loading profile image: $error');
                                                  return Center(
                                                    child: Icon(Icons.person, color: Colors.white54, size: 40),
                                                  );
                                                },
                                                loadingBuilder: (context, child, loadingProgress) {
                                                  if (loadingProgress == null) return child;
                                                  return Center(
                                                    child: CircularProgressIndicator(
                                                      value: loadingProgress.expectedTotalBytes != null
                                                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                          : null,
                                                      color: Colors.white54,
                                                      strokeWidth: 2,
                                                    ),
                                                  );
                                                },
                                              )
                                            : Center(
                                                child: Icon(Icons.person, color: Colors.white54, size: 40),
                                              ),
                                      ),
                                    ),
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  // Name
                                  GestureDetector(
                                    onTap: _updateDisplayName,
                                    child: Text(
                                      user.displayName ?? 'User',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontFamily: 'SF Compact Rounded',
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  // Email
                                  Text(
                                    user.email ?? 'No email',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: const Color(0xFFA0A0A0),
                                      fontSize: 14,
                                      fontFamily: 'SF Compact Rounded',
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  // Email verification warning
                                  if (!user.emailVerified) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 16),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Email not verified',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.amber,
                                            fontSize: 12,
                                            fontFamily: 'SF Compact Rounded',
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                  const SizedBox(height: 30),
                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatCard('47', 'Orders'),
                      _buildStatCard('$_favoriteCount', 'Favorites'),
                      _buildStatCard('8', 'Reviews'),
                    ],
                  ),
                  const SizedBox(height: 30),
                  _buildFavoritesSection(),
                  const SizedBox(height: 20),
                  // Menu Items
                  _buildMenuItem('Saved Addresses'),
                  const SizedBox(height: 10),
                  _buildMenuItem('Settings'),
                  const SizedBox(height: 30),
                  // Delete Account Button (Temporary)
                  InkWell(
                    onTap: () async {
                      final shouldDelete = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            backgroundColor: const Color(0xFF1E1E1E),
                            title: const Text(
                              'Delete Account',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'SF Compact Rounded',
                              ),
                            ),
                            content: const Text(
                              'Are you sure you want to permanently delete your account? This action cannot be undone.',
                              style: TextStyle(
                                color: Color(0xFFA0A0A0),
                                fontFamily: 'SF Compact Rounded',
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: Color(0xFFA0A0A0),
                                    fontFamily: 'SF Compact Rounded',
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontFamily: 'SF Compact Rounded',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                      
                      if (shouldDelete == true && context.mounted) {
                        debugPrint('Delete account confirmed');
                        try {
                          final currentUser = FirebaseAuth.instance.currentUser;
                          debugPrint('Current user: ${currentUser?.uid}');
                          
                          if (currentUser != null) {
                            // Delete Firestore document and Storage files first
                            debugPrint('Deleting user data...');
                            await _userService.deleteUserAccount(currentUser.uid);
                            debugPrint('User data deleted');
                            
                            // Then delete the Firebase Auth account
                            debugPrint('Deleting auth account...');
                            await currentUser.delete();
                            debugPrint('Auth account deleted');
                            
                            if (mounted) {
                              setState(() {});
                            }
                          }
                        } on FirebaseAuthException catch (e) {
                          debugPrint('FirebaseAuthException: ${e.code} - ${e.message}');
                        } catch (e, stackTrace) {
                          debugPrint('Error deleting account: $e');
                          debugPrint('Stack trace: $stackTrace');
                        }
                      } else {
                        debugPrint('Delete cancelled or context not mounted');
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      height: 49.99,
                      decoration: ShapeDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(0.00, 0.50),
                          end: Alignment(1.00, 0.50),
                          colors: [Colors.red.withOpacity(0.3), Colors.red.withOpacity(0.3)],
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete_forever, color: Colors.red, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            'Delete Account',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                              fontFamily: 'SF Compact Rounded',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  // Log Out Button
                  InkWell(
                    onTap: () async {
                      final shouldLogout = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            backgroundColor: const Color(0xFF1E1E1E),
                            title: const Text(
                              'Log Out',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'SF Compact Rounded',
                              ),
                            ),
                            content: const Text(
                              'Are you sure you want to log out?',
                              style: TextStyle(
                                color: Color(0xFFA0A0A0),
                                fontFamily: 'SF Compact Rounded',
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: Color(0xFFA0A0A0),
                                    fontFamily: 'SF Compact Rounded',
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text(
                                  'Log Out',
                                  style: TextStyle(
                                    color: Color(0xFF74004A),
                                    fontFamily: 'SF Compact Rounded',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                      
                      if (shouldLogout == true && context.mounted) {
                        await FirebaseAuth.instance.signOut();
                        // Force rebuild to show logged out state
                        if (mounted) {
                          setState(() {});
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      height: 49.99,
                      decoration: ShapeDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(0.00, 0.50),
                          end: Alignment(1.00, 0.50),
                          colors: [const Color(0x4C4C0041), const Color(0x4C4C0041)],
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout, color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            'Log Out',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontFamily: 'SF Compact Rounded',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeFavorite(String lookupKey) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _favoriteService.removeFavorite(user.uid, lookupKey);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from favorites')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not remove favorite: $e')),
      );
    }
  }

  String? _favoriteImageUrl(FavoriteRestaurant favorite) {
    return favorite.imageUrlForDisplay(_configService.googleApiKey);
  }

  Widget _buildFavoritesSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A1426), Color(0xFF121212)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Favorite Places',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontFamily: 'Arvo',
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (_favoritesLoading)
                const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(
                    '$_favoriteCount saved',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'SF Compact Rounded',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_favoritesLoading)
            const SizedBox.shrink()
          else if (_favorites.isEmpty)
            const Text(
              'Save a spot from Discover or Chat to see it here.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontFamily: 'SF Compact Rounded',
              ),
            )
          else
            Column(
              children: _favorites.map((fav) => _favoriteTile(fav)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _favoriteTile(FavoriteRestaurant favorite) {
    final imageUrl = _favoriteImageUrl(favorite);
    final meta = [
      if (favorite.priceLabel != null) favorite.priceLabel!,
      if (favorite.cuisine != null) favorite.cuisine!,
    ].join(' - ');

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0x331E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageUrl != null
                ? Image.network(
                    imageUrl,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 72,
                      height: 72,
                      color: const Color(0xFF2C2C2C),
                      child: const Icon(Icons.restaurant, color: Colors.white38),
                    ),
                  )
                : Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2C),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.restaurant, color: Colors.white38),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  favorite.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'SF Compact Rounded',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (meta.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      meta,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontFamily: 'SF Compact Rounded',
                      ),
                    ),
                  ),
                if (favorite.address != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      favorite.address!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontFamily: 'SF Compact Rounded',
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _removeFavorite(favorite.lookupKey),
            icon: const Icon(Icons.favorite, color: Colors.redAccent),
            tooltip: 'Remove from favorites',
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Container(
      width: 111.22,
      height: 72.43,
      decoration: ShapeDecoration(
        gradient: LinearGradient(
          begin: Alignment(0.00, 0.50),
          end: Alignment(1.00, 0.50),
          colors: [const Color(0x7F4C0041), const Color(0x7F4C0041)],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontFamily: 'SF Compact Rounded',
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFFD4D4D4),
              fontSize: 12,
              fontFamily: 'SF Compact Rounded',
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(String title) {
    return Container(
      width: double.infinity,
      height: 49.99,
      decoration: ShapeDecoration(
        gradient: LinearGradient(
          begin: Alignment(0.00, 0.50),
          end: Alignment(1.00, 0.50),
          colors: [const Color(0xFF4C0041), const Color(0xFF4C0041)],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              child: Icon(Icons.star, color: Colors.white54, size: 18),
            ),
            const SizedBox(width: 15),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'SF Compact Rounded',
                fontWeight: FontWeight.w400,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: Colors.white54, size: 20),
          ],
        ),
      ),
    );
  }
}
