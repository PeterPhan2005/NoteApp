# testproject

A new Flutter project.

## Getting Started

# Flutter Notes App

A comprehensive Flutter notes application with Firebase backend, featuring category management, user profiles, dark theme, auto-save functionality, and asset-based avatar system.

## Features

### 🗒️ Note Management
- Create, edit, and delete notes with real-time auto-save
- Rich text support with title and content
- Automatic timestamp tracking
- Fixed-size note display cards for consistent UI

### 📁 Category System
- Create and manage custom categories
- Color-coded categories with custom icons
- Filter notes by category
- Category statistics and management

### 👤 User Profile & Authentication
- Firebase Authentication (Email/Password)
- User profile management with display name, phone, and bio
- Account information display
- Account deletion functionality

### 🎨 Theme & UI
- Light and Dark theme support
- Theme persistence across app sessions
- Material Design 3 components
- Responsive and modern UI design

### 🖼️ Avatar System
- Asset-based avatar system (male/female)
- Simple gender swap functionality
- No complex upload requirements
- Clean and lightweight implementation

### ⚡ Auto-Save
- Automatic note saving with 1-second delay
- No manual save button required
- Duplicate prevention system
- Real-time data synchronization

### 🌐 Localization
- Complete English UI translation
- User-friendly interface
- Consistent terminology throughout the app

## Technical Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Firebase
  - Authentication
  - Cloud Firestore
- **State Management**: StatefulWidget with Service Pattern
- **Architecture**: Service-based architecture with clear separation of concerns

## Project Structure

```
lib/
├── model/
│   ├── note.dart           # Note data model
│   ├── category.dart       # Category data model
│   └── user_profile.dart   # User profile data model
├── screens/
│   ├── splash.dart         # Splash screen
│   ├── login.dart          # Login screen
│   ├── signup.dart         # Sign up screen
│   ├── home.dart           # Main notes listing
│   ├── add_edit_note.dart  # Note creation/editing
│   ├── categories.dart     # Category management
│   └── profile.dart        # User profile management
├── services/
│   ├── auth.dart           # Authentication service
│   ├── firestore.dart      # Firestore operations
│   ├── user_service.dart   # User profile operations
│   ├── category_service.dart # Category operations
│   └── theme_service.dart  # Theme management
└── main.dart              # App entry point
```

## Setup Instructions

### Prerequisites
- Flutter SDK (>=3.9.0)
- Firebase project setup
- Android Studio / VS Code

### Firebase Setup
1. Create a new Firebase project
2. Enable Authentication (Email/Password)
3. Create Cloud Firestore database
4. Add your `google-services.json` to `android/app/`
5. Configure Firebase for your platform

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/PeterPhan2005/NoteApp.git
   cd NoteApp
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

## Firebase Security Rules

### Firestore Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      match /notes/{noteId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      
      match /categories/{categoryId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

## Key Features Implementation

### Auto-Save System
- Implements Timer-based auto-save with 1-second delay
- Prevents duplicate saves using `_noteCreated` flag
- Real-time synchronization with Firestore

### Category Management
- Dynamic category creation with color and icon selection
- Real-time category filtering
- Category statistics tracking

### Theme Management
- Singleton ThemeService for global theme state
- Persistent theme preferences in Firestore
- Real-time theme switching

### Avatar System
- Asset-based male/female avatars
- Simple swap functionality without complex uploads
- Lightweight and performant implementation

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

**Peter Phan** - [PeterPhan2005](https://github.com/PeterPhan2005)

## Acknowledgments

- Flutter team for the excellent framework
- Firebase for the robust backend services
- Material Design for the beautiful UI components
