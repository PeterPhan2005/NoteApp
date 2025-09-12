import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:testproject/model/user_profile.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get userId => _auth.currentUser?.uid ?? '';
  User? get currentUser => _auth.currentUser;

  // Get user profile
  Future<UserProfile?> getUserProfile() async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('profile')
          .doc('info')
          .get();

      if (doc.exists) {
        return UserProfile.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Get user profile stream
  Stream<UserProfile?> getUserProfileStream() {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('profile')
        .doc('info')
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return UserProfile.fromMap(doc.data()!);
      }
      return null;
    });
  }

  // Create user profile (called after registration)
  Future<void> createUserProfile(UserProfile profile) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('profile')
          .doc('info')
          .set(profile.toMap());
    } catch (e) {
      print('Error creating user profile: $e');
      throw e;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('profile')
          .doc('info')
          .update(profile.toMap());
    } catch (e) {
      print('Error updating user profile: $e');
      throw e;
    }
  }

  // Update last login
  Future<void> updateLastLogin() async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('profile')
          .doc('info')
          .update({'lastLogin': DateTime.now().millisecondsSinceEpoch});
    } catch (e) {
      print('Error updating last login: $e');
    }
  }

  // Update preferences
  Future<void> updatePreferences(Map<String, dynamic> preferences) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('profile')
          .doc('info')
          .update({'preferences': preferences});
    } catch (e) {
      print('Error updating preferences: $e');
      throw e;
    }
  }

  // Update display name in Firebase Auth
  Future<void> updateDisplayName(String displayName) async {
    try {
      await currentUser?.updateDisplayName(displayName);
    } catch (e) {
      print('Error updating display name in auth: $e');
    }
  }

  // Update email in Firebase Auth
  Future<void> updateEmail(String newEmail) async {
    try {
      await currentUser?.updateEmail(newEmail);
    } catch (e) {
      print('Error updating email: $e');
      throw e;
    }
  }

  // Update password
  Future<void> updatePassword(String newPassword) async {
    try {
      await currentUser?.updatePassword(newPassword);
    } catch (e) {
      print('Error updating password: $e');
      throw e;
    }
  }

  // Delete user account
  Future<void> deleteAccount() async {
    try {
      // Delete user data from Firestore
      await _deleteUserData();
      
      // Delete Firebase Auth account
      await currentUser?.delete();
    } catch (e) {
      print('Error deleting account: $e');
      throw e;
    }
  }

  // Private method to delete all user data
  Future<void> _deleteUserData() async {
    final batch = _firestore.batch();
    
    // Delete all notes
    final notesQuery = await _firestore
        .collection('users')
        .doc(userId)
        .collection('notes')
        .get();
    
    for (var doc in notesQuery.docs) {
      batch.delete(doc.reference);
    }

    // Delete all categories
    final categoriesQuery = await _firestore
        .collection('users')
        .doc(userId)
        .collection('categories')
        .get();
    
    for (var doc in categoriesQuery.docs) {
      batch.delete(doc.reference);
    }

    // Delete profile
    batch.delete(_firestore
        .collection('users')
        .doc(userId)
        .collection('profile')
        .doc('info'));

    // Delete user document
    batch.delete(_firestore.collection('users').doc(userId));

    await batch.commit();
  }

  // Get user statistics
  Future<Map<String, int>> getUserStats() async {
    try {
      final notesQuery = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .get();

      final categoriesQuery = await _firestore
          .collection('users')
          .doc(userId)
          .collection('categories')
          .get();

      return {
        'totalNotes': notesQuery.docs.length,
        'totalCategories': categoriesQuery.docs.length,
      };
    } catch (e) {
      print('Error getting user stats: $e');
      return {'totalNotes': 0, 'totalCategories': 0};
    }
  }
}
