import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/user_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  final _userService = UserService();
  File? _profileImage;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    
    // Show bottom sheet with camera and gallery options
    await showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take a photo'),
                onTap: () async {
                  Navigator.pop(context);
                  final pickedFile = await picker.pickImage(
                    source: ImageSource.camera,
                    maxWidth: 512,
                    maxHeight: 512,
                    imageQuality: 85,
                    preferredCameraDevice: CameraDevice.front,
                  );
                  if (pickedFile != null) {
                    setState(() {
                      _profileImage = File(pickedFile.path);
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final pickedFile = await picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 512,
                    maxHeight: 512,
                    imageQuality: 85,
                  );
                  if (pickedFile != null) {
                    setState(() {
                      _profileImage = File(pickedFile.path);
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _completeSetup() async {
    if (_nameController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your name';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'No user logged in. Please try again.';
        });
        return;
      }

      debugPrint('Creating user profile for: ${user.uid}');
      await _userService.createUserProfile(
        userId: user.uid,
        displayName: _nameController.text.trim(),
        profileImage: _profileImage,
      );
      
      debugPrint('Profile created successfully');
      
      if (mounted) {
        // Navigate back to profile page
        Navigator.of(context).pop();
      }
    } catch (e, stackTrace) {
      debugPrint('Error creating profile: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _errorMessage = 'Failed to complete profile setup: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/assets/gradient/Gradients.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Back button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Food Icon
                    const Center(
                      child: Icon(
                        Icons.person_add,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    const Text(
                      "Set Up Your Profile",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontFamily: 'SF Compact Rounded',
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 10),
                    
                    const Text(
                      "Add your details to personalize your experience.",
                      style: TextStyle(
                        color: Color(0xFFA0A0A0),
                        fontSize: 16,
                        fontFamily: 'SF Compact Rounded',
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Profile Image Picker
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment(0.50, 0.00),
                              end: Alignment(0.50, 1.00),
                              colors: [Color(0xFF74004A), Color(0xFF197400)],
                            ),
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF121212),
                              shape: BoxShape.circle,
                              image: _profileImage != null
                                  ? DecorationImage(
                                      image: FileImage(_profileImage!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _profileImage == null
                                ? const Icon(
                                    Icons.add_a_photo,
                                    size: 40,
                                    color: Colors.white54,
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    const Text(
                      "Add Profile Picture (Optional)",
                      style: TextStyle(
                        color: Color(0xFFA0A0A0),
                        fontSize: 14,
                        fontFamily: 'SF Compact Rounded',
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 40),

                    // Error message if any
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.red.withOpacity(0.5)),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                            fontFamily: 'SF Compact Rounded',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    if (_errorMessage != null) const SizedBox(height: 20),
                    
                    // Name field
                    TextField(
                      controller: _nameController,
                      enabled: !_isLoading,
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
                    
                    const SizedBox(height: 30),
                    
                    // Complete button
                    Container(
                      height: 50,
                      decoration: ShapeDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment(0.00, 0.50),
                          end: Alignment(1.00, 0.50),
                          colors: [Color(0xFF74004A), Color(0xFF197400)],
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isLoading ? null : _completeSetup,
                          borderRadius: BorderRadius.circular(20),
                          child: Center(
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Complete Setup',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontFamily: 'SF Compact Rounded',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
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