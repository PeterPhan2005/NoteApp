import 'package:flutter/material.dart';
import 'package:testproject/model/note.dart';
import 'package:testproject/model/category.dart';
import 'package:testproject/screens/login.dart';
import 'package:testproject/screens/categories.dart';
import 'package:testproject/screens/profile.dart';
import 'package:testproject/screens/add_edit_note.dart';
import 'package:testproject/services/auth.dart';
import 'package:testproject/services/firestore.dart';
import 'package:testproject/services/category_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  void _showNoteDetail(BuildContext context, Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          note.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Text(
            note.content,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AuthService _auth = AuthService();
    final FirestoreService _firestore = FirestoreService();
    final CategoryService _categoryService = CategoryService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notes"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CategoriesScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          )
        ],
      ),
      body: StreamBuilder<List<Note>>(
        stream: _firestore.getNotes(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading notes"));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final notes = snapshot.data!;
          return ListView.builder(
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: note.categoryId.isNotEmpty
                      ? FutureBuilder<Category?>(
                          future: _categoryService.getCategoryById(note.categoryId),
                          builder: (context, snapshot) {
                            final category = snapshot.data;
                            if (category != null) {
                              return CircleAvatar(
                                backgroundColor: category.colorValue,
                                radius: 16,
                                child: Icon(
                                  category.iconData,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              );
                            }
                            return const CircleAvatar(
                              backgroundColor: Colors.grey,
                              radius: 16,
                              child: Icon(Icons.note, color: Colors.white, size: 16),
                            );
                          },
                        )
                      : const CircleAvatar(
                          backgroundColor: Colors.grey,
                          radius: 16,
                          child: Icon(Icons.note, color: Colors.white, size: 16),
                        ),
                  title: Text(
                    note.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    note.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _firestore.deleteNote(note.id),
                  ),
                  onTap: () {
                    // Tap to edit note
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddEditNoteScreen(note: note),
                      ),
                    );
                  },
                  onLongPress: () {
                    // Long press to view detail
                    _showNoteDetail(context, note);
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditNoteScreen(),
            ),
          );
        },
      ),
    );
  }
}
