import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:testproject/model/category.dart';

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get userId => _auth.currentUser?.uid ?? '';

  // Get categories stream
  Stream<List<Category>> getCategories() {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('categories')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Category.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Add new category
  Future<void> addCategory(Category category) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('categories')
        .add(category.toMap());
  }

  // Update category
  Future<void> updateCategory(Category category) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('categories')
        .doc(category.id)
        .update(category.toMap());
  }

  // Delete category
  Future<void> deleteCategory(String categoryId) async {
    // First, update all notes with this category to have empty categoryId
    final notesQuery = await _firestore
        .collection('users')
        .doc(userId)
        .collection('notes')
        .where('categoryId', isEqualTo: categoryId)
        .get();

    final batch = _firestore.batch();
    
    for (var doc in notesQuery.docs) {
      batch.update(doc.reference, {'categoryId': ''});
    }

    // Then delete the category
    batch.delete(_firestore
        .collection('users')
        .doc(userId)
        .collection('categories')
        .doc(categoryId));

    await batch.commit();
  }

  // Get category by id
  Future<Category?> getCategoryById(String categoryId) async {
    if (categoryId.isEmpty) return null;
    
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('categories')
        .doc(categoryId)
        .get();

    if (doc.exists) {
      return Category.fromMap(doc.id, doc.data()!);
    }
    return null;
  }

  // Get notes count by category
  Future<int> getNotesCountByCategory(String categoryId) async {
    final query = await _firestore
        .collection('users')
        .doc(userId)
        .collection('notes')
        .where('categoryId', isEqualTo: categoryId)
        .get();

    return query.docs.length;
  }

  // Create default categories for new users
  Future<void> createDefaultCategories() async {
    final defaultCategories = [
      Category(
        id: '',
        name: 'Work',
        color: 'blue',
        icon: 'work',
        createdAt: DateTime.now(),
      ),
      Category(
        id: '',
        name: 'Personal',
        color: 'green',
        icon: 'personal',
        createdAt: DateTime.now(),
      ),
      Category(
        id: '',
        name: 'Study',
        color: 'orange',
        icon: 'study',
        createdAt: DateTime.now(),
      ),
    ];

    for (var category in defaultCategories) {
      await addCategory(category);
    }
  }
}
