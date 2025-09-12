class UserProfile {
  String uid;
  String email;
  String displayName;
  String photoUrl;
  String phoneNumber;
  String bio;
  String gender; // male or female
  DateTime createdAt;
  DateTime lastLogin;
  Map<String, dynamic> preferences;

  UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl = '',
    this.phoneNumber = '',
    this.bio = '',
    this.gender = 'male', // default to male
    required this.createdAt,
    required this.lastLogin,
    Map<String, dynamic>? preferences,
  }) : preferences = preferences ?? {
    'theme': 'light',
    'language': 'vi',
    'notifications': true,
    'autoSave': true,
  };

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'bio': bio,
      'gender': gender,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastLogin': lastLogin.millisecondsSinceEpoch,
      'preferences': preferences,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      bio: map['bio'] ?? '',
      gender: map['gender'] ?? 'male',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      lastLogin: DateTime.fromMillisecondsSinceEpoch(map['lastLogin'] ?? 0),
      preferences: Map<String, dynamic>.from(map['preferences'] ?? {
        'theme': 'light',
        'language': 'vi',
        'notifications': true,
        'autoSave': true,
      }),
    );
  }

  UserProfile copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    String? bio,
    String? gender,
    DateTime? createdAt,
    DateTime? lastLogin,
    Map<String, dynamic>? preferences,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      bio: bio ?? this.bio,
      gender: gender ?? this.gender,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      preferences: preferences ?? this.preferences,
    );
  }
}
