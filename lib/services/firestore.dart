import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:testproject/model/note.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get userId => _auth.currentUser?.uid ?? '';

  // Add note
  Future<void> addNote(Note note) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notes')
        .add(note.toMap());
  }

  // Add note and return the document ID
  Future<String> addNoteAndGetId(Note note) async {
    final docRef = await _firestore
        .collection('users')
        .doc(userId)
        .collection('notes')
        .add(note.toMap());
    return docRef.id;
  }

  // Cập nhật note
  Future<void> updateNote(Note note) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notes')
        .doc(note.id)
        .update(note.toMap());
  }

  // Delete note
  Future<void> deleteNote(String id) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notes')
        .doc(id)
        .delete();
  }

  // Lấy stream notes
  Stream<List<Note>> getNotes() {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Note.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // Lấy notes theo category
  Stream<List<Note>> getNotesByCategory(String categoryId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notes')
        .where('categoryId', isEqualTo: categoryId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Note.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // Get notes without category
  Stream<List<Note>> getUncategorizedNotes() {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notes')
        .where('categoryId', isEqualTo: '')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Note.fromMap(doc.id, doc.data());
      }).toList();
    });
  }
}
