import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> createUserProfile({
    required String userId,
    required String displayName,
    File? profileImage,
  }) async {
    String? profileImageUrl;

    // Upload profile image if provided
    if (profileImage != null) {
      try {
        final storageRef =
            _storage.ref().child('user_profiles/$userId/profile.jpg');
        await storageRef.putFile(profileImage);
        profileImageUrl = await storageRef.getDownloadURL();
      } catch (e) {
        print('Error uploading profile image: $e');
        // Continue without profile image if upload fails
        profileImageUrl = null;
      }
    }

    // Create user profile document
    await _firestore.collection('users').doc(userId).set({
      'displayName': displayName,
      'profileImageUrl': profileImageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Update Firebase Auth user profile
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await currentUser.updateProfile(
        displayName: displayName,
        photoURL: profileImageUrl,
      );
      // Reload the user to ensure we have the latest data
      await currentUser.reload();
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data();
  }

  Stream<Map<String, dynamic>?> streamUserProfile(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.data());
  }

  Future<void> updateProfilePicture({
    required String userId,
    required File profileImage,
  }) async {
    try {
      // Upload new profile image
      final storageRef =
          _storage.ref().child('user_profiles/$userId/profile.jpg');
      await storageRef.putFile(profileImage);
      final profileImageUrl = await storageRef.getDownloadURL();

      // Update Firestore document
      await _firestore.collection('users').doc(userId).update({
        'profileImageUrl': profileImageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update Firebase Auth user profile
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await currentUser.updateProfile(photoURL: profileImageUrl);
        // Reload the user to ensure we have the latest data
        await currentUser.reload();
      }
    } catch (e) {
      print('Error updating profile picture: $e');
      rethrow;
    }
  }

  Future<void> updateDisplayName({
    required String userId,
    required String displayName,
  }) async {
    try {
      // Update Firestore document
      await _firestore.collection('users').doc(userId).update({
        'displayName': displayName,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update Firebase Auth user profile
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await currentUser.updateProfile(displayName: displayName);
        // Reload the user to ensure we have the latest data
        await currentUser.reload();
      }
    } catch (e) {
      print('Error updating display name: $e');
      rethrow;
    }
  }

  Future<void> deleteUserAccount(String userId) async {
    try {
      // Delete profile image from Storage if it exists
      try {
        final storageRef = _storage.ref().child('user_profiles/$userId/profile.jpg');
        await storageRef.delete();
      } catch (e) {
        print('Profile image not found or already deleted: $e');
        // Continue even if image doesn't exist
      }

      // Delete user document from Firestore
      await _firestore.collection('users').doc(userId).delete();
      
      print('User data deleted successfully');
    } catch (e) {
      print('Error deleting user data: $e');
      rethrow;
    }
  }
}
