import 'package:flutter/material.dart';
import 'package:testproject/model/user_profile.dart';
import 'package:testproject/services/user_service.dart';
import 'package:testproject/services/auth.dart';
import 'package:testproject/services/theme_service.dart';
import 'package:testproject/screens/login.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  final ThemeService _themeService = ThemeService();
  
  UserProfile? _userProfile;
  Map<String, int> _userStats = {'totalNotes': 0, 'totalCategories': 0};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final profile = await _userService.getUserProfile();
      final stats = await _userService.getUserStats();
      
      // If profile doesn't exist, create default profile
      if (profile == null) {
        final currentUser = _userService.currentUser;
        if (currentUser != null) {
          final defaultProfile = UserProfile(
            uid: currentUser.uid,
            email: currentUser.email ?? '',
            displayName: currentUser.displayName ?? '',
            createdAt: DateTime.now(),
            lastLogin: DateTime.now(),
          );
          
          await _userService.createUserProfile(defaultProfile);
          
          setState(() {
            _userProfile = defaultProfile;
            _userStats = stats;
            _loading = false;
          });
          return;
        }
      }
      
      setState(() {
        _userProfile = profile;
        _userStats = stats;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data loading error: $e')),
      );
    }
  }

  String? _validatePhoneNumber(String phone) {
    if (phone.trim().isEmpty) {
      return null; // Not required
    }
    
    // Check if contains only numbers
    if (!RegExp(r'^[0-9]+$').hasMatch(phone.trim())) {
      return "Phone can only contain digits";
    }
    
    // Check at least 10 digits
    if (phone.trim().length < 10) {
      return "Must have at least 10 digits";
    }
    
    // Check starts with 0
    if (!phone.trim().startsWith('0')) {
      return "Phone number must start with 0";
    }
    
    return null;
  }

  Future<void> _swapAvatar() async {
    if (_userProfile == null) return;
    
    try {
      final currentGender = _userProfile!.gender;
      final newGender = currentGender == 'male' ? 'female' : 'male';
      
      final updatedProfile = _userProfile!.copyWith(gender: newGender);
      
      await _userService.updateUserProfile(updatedProfile);
      
      setState(() {
        _userProfile = updatedProfile;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Avatar changed to ${newGender == 'male' ? 'male' : 'female'}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Avatar change error: $e')),
      );
    }
  }

  void _showEditProfileDialog() {
    if (_userProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile information not loaded yet')),
      );
      return;
    }

    final displayNameController = TextEditingController(text: _userProfile?.displayName ?? '');
    final phoneController = TextEditingController(text: _userProfile?.phoneNumber ?? '');
    final bioController = TextEditingController(text: _userProfile?.bio ?? '');
    
    String? phoneError;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Edit Profile"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: displayNameController,
                  decoration: const InputDecoration(
                    labelText: "Display name",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: "Phone number",
                    border: const OutlineInputBorder(),
                    errorText: phoneError,
                    errorBorder: phoneError != null 
                        ? const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.red, width: 2),
                          )
                        : null,
                    focusedErrorBorder: phoneError != null
                        ? const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.red, width: 2),
                          )
                        : null,
                  ),
                  keyboardType: TextInputType.phone,
                ),
              const SizedBox(height: 16),
              TextField(
                controller: bioController,
                decoration: const InputDecoration(
                  labelText: "About yourself",
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                textAlignVertical: TextAlignVertical.top,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              // Validate phone number
              setDialogState(() {
                phoneError = _validatePhoneNumber(phoneController.text);
              });
              
              if (phoneError != null) return;
              
              try {
                if (_userProfile == null) return;
                
                final updatedProfile = _userProfile!.copyWith(
                  displayName: displayNameController.text.trim(),
                  phoneNumber: phoneController.text.trim(),
                  bio: bioController.text.trim(),
                );

                await _userService.updateUserProfile(updatedProfile);
                await _userService.updateDisplayName(displayNameController.text.trim());
                
                setState(() => _userProfile = updatedProfile);
                
                // Đóng dialog trước
                Navigator.pop(context);
                
                // Sau đó hiển thị SnackBar với context của widget chính
                if (mounted) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('Profile updated successfully!')),
                  );
                }
              } catch (e) {
                // Hiển thị lỗi ngay lập tức, không cần đóng dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Update error: $e')),
                );
              }
            },
            child: const Text("Save"),
          ),
        ],
        ),
      ),
    );
  }

  Future<void> _toggleTheme() async {
    if (_userProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile information not loaded yet')),
      );
      return;
    }

    try {
      final currentTheme = _userProfile!.preferences['theme'] ?? 'light';
      final newTheme = currentTheme == 'light' ? 'dark' : 'light';
      
      // Update theme service
      await _themeService.setTheme(newTheme == 'dark');
      
      // Update local profile state
      final updatedPreferences = Map<String, dynamic>.from(_userProfile!.preferences);
      updatedPreferences['theme'] = newTheme;
      
      setState(() {
        _userProfile = _userProfile!.copyWith(preferences: updatedPreferences);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Switched to ${newTheme == 'dark' ? 'dark' : 'light'} theme')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Theme change error: $e')),
      );
    }
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account", style: TextStyle(color: Colors.red)),
        content: const Text(
          "Are you sure you want to delete your account?\n\n"
          "All your data will be permanently deleted and cannot be recovered.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _userService.deleteAccount();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Account deletion error: $e')),
                );
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                child: ClipOval(
                  child: Image.asset(
                    'assets/${_userProfile?.gender ?? 'male'}.jpg',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.person, size: 50, color: Colors.blue);
                    },
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _swapAvatar,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.swap_horiz,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _userProfile?.displayName.isNotEmpty == true 
                ? _userProfile!.displayName 
                : 'User',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _userProfile?.email ?? '',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          if (_userProfile?.bio.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              _userProfile!.bio,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem("Notes", _userStats['totalNotes']!, Icons.note),
          _buildStatItem("Categories", _userStats['totalCategories']!, Icons.category),
          _buildStatItem("Days Joined", _getDaysJoined(), Icons.calendar_today),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 30, color: Colors.blue),
        const SizedBox(height: 8),
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  int _getDaysJoined() {
    if (_userProfile?.createdAt == null) return 0;
    return DateTime.now().difference(_userProfile!.createdAt).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = _userProfile?.preferences['theme'] ?? 'light';
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        actions: [
          IconButton(
            icon: Icon(currentTheme == 'dark' ? Icons.light_mode : Icons.dark_mode),
            onPressed: _toggleTheme,
            tooltip: currentTheme == 'dark' ? 'Switch to light theme' : 'Switch to dark theme',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildProfileHeader(),
                  _buildStatsRow(),
                  const Divider(),
                  
                  // Menu items
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text("Edit Profile"),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: _userProfile != null ? _showEditProfileDialog : null,
                  ),
                  ListTile(
                    leading: Icon(currentTheme == 'dark' ? Icons.light_mode : Icons.dark_mode),
                    title: Text("${currentTheme == 'dark' ? 'Dark' : 'Light'} Mode"),
                    subtitle: const Text("Tap to toggle"),
                    trailing: Switch(
                      value: currentTheme == 'dark',
                      onChanged: (_) => _toggleTheme(),
                    ),
                    onTap: _userProfile != null ? _toggleTheme : null,
                  ),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text("Account Information"),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Account Information"),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Email: ${_userProfile?.email ?? ''}"),
                              const SizedBox(height: 8),
                              Text("UID: ${_userProfile?.uid ?? ''}"),
                              const SizedBox(height: 8),
                              Text("Created date: ${_userProfile?.createdAt.toString().split(' ')[0] ?? ''}"),
                              const SizedBox(height: 8),
                              Text("Last login: ${_userProfile?.lastLogin.toString().split(' ')[0] ?? ''}"),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Close"),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.orange),
                    title: const Text("Sign Out"),
                    onTap: () async {
                      await _authService.signOut();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_forever, color: Colors.red),
                    title: const Text("Delete Account", style: TextStyle(color: Colors.red)),
                    onTap: _showDeleteAccountDialog,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
