import 'package:firebase_auth/firebase_auth.dart';
import 'package:testproject/model/user_profile.dart';
import 'package:testproject/services/user_service.dart';
import 'package:testproject/services/category_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();
  final CategoryService _categoryService = CategoryService();

  // Stream to check login status
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up
  Future<User?> signUp(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final user = userCredential.user;
      if (user != null) {
        // Create profile for new user
        final userProfile = UserProfile(
          uid: user.uid,
          email: email,
          displayName: '',
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
        );
        
        await _userService.createUserProfile(userProfile);
        
        // Create default categories for new user
        await _categoryService.createDefaultCategories();
      }
      
      return user;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in
  Future<User?> signIn(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final user = userCredential.user;
      if (user != null) {
        // Cập nhật last login
        await _userService.updateLastLogin();
      }
      
      return user;
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
