import 'package:flutter/material.dart';
import 'dart:async';
import 'package:testproject/model/note.dart';
import 'package:testproject/model/category.dart';
import 'package:testproject/services/firestore.dart';
import 'package:testproject/services/category_service.dart';
import 'package:testproject/services/user_service.dart';

class AddEditNoteScreen extends StatefulWidget {
  final Note? note; // null if creating new, has value if editing

  const AddEditNoteScreen({super.key, this.note});

  @override
  State<AddEditNoteScreen> createState() => _AddEditNoteScreenState();
}

class _AddEditNoteScreenState extends State<AddEditNoteScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final CategoryService _categoryService = CategoryService();
  final UserService _userService = UserService();

  String? _selectedCategoryId;
  Timer? _autoSaveTimer;
  bool _hasChanges = false;
  bool _isAutoSaveEnabled = true;
  bool _isSaving = false;
  Note? _currentNote; // Keep track of current note (null for new, Note object for existing)
  String? _lastSavedName;
  String? _lastSavedContent;
  String? _lastSavedCategoryId;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _loadAutoSavePreference();
    
    // Listen to text changes
    _nameController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);
  }

  void _initializeData() {
    if (widget.note != null) {
      // Editing existing note
      _currentNote = widget.note;
      _nameController.text = widget.note!.name;
      _contentController.text = widget.note!.content;
      _selectedCategoryId = widget.note!.categoryId.isEmpty ? null : widget.note!.categoryId;
      
      // Save initial state
      _lastSavedName = widget.note!.name;
      _lastSavedContent = widget.note!.content;
      _lastSavedCategoryId = widget.note!.categoryId.isEmpty ? null : widget.note!.categoryId;
    } else {
      // Creating new note
      _currentNote = null;
    }
  }

  Future<void> _loadAutoSavePreference() async {
    try {
      final userProfile = await _userService.getUserProfile();
      if (userProfile != null) {
        setState(() {
          _isAutoSaveEnabled = userProfile.preferences['autoSave'] ?? true;
        });
      }
    } catch (e) {
      print('Error loading auto-save preference: $e');
    }
  }

  void _onTextChanged() {
    final currentName = _nameController.text;
    final currentContent = _contentController.text;
    final currentCategory = _selectedCategoryId;

    // Check if there are changes
    final hasChanges = currentName != (_lastSavedName ?? '') ||
                      currentContent != (_lastSavedContent ?? '') ||
                      currentCategory != _lastSavedCategoryId;

    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }

    // Always schedule auto-save if there are changes and auto-save is enabled
    if (_isAutoSaveEnabled && hasChanges) {
      _scheduleAutoSave();
    }
  }

  void _onCategoryChanged(String? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
    });
    _onTextChanged(); // Trigger change detection
  }

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    
    // Auto-save after 500ms for more responsive saving
    _autoSaveTimer = Timer(const Duration(milliseconds: 500), () {
      if (_hasChanges && !_isSaving) {
        _performAutoSave();
      }
    });
  }

  Future<void> _performAutoSave() async {
    if (_isSaving) return;

    final name = _nameController.text.trim();
    final content = _contentController.text.trim();

    print('AutoSave triggered: name="$name", content="${content.length} chars"');

    // Don't save if both name and content are empty
    if (name.isEmpty && content.isEmpty) {
      print('AutoSave skipped: both name and content are empty');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (_currentNote == null) {
        print('Creating new note...');
        // Creating new note
        final newNote = Note(
          id: '', // Firestore will generate ID
          name: name.isEmpty ? "Untitled" : name,
          content: content,
          categoryId: _selectedCategoryId ?? '',
          createdAt: DateTime.now(),
        );
        
        await _firestoreService.addNote(newNote);
        print('New note created successfully');
        
        // Create a Note object with the current data for tracking
        _currentNote = Note(
          id: 'temp-id', // Temporary ID since we don't get the actual ID back
          name: name.isEmpty ? "Untitled" : name,
          content: content,
          categoryId: _selectedCategoryId ?? '',
          createdAt: DateTime.now(),
        );
        
        // Update last saved state
        _lastSavedName = name.isEmpty ? "Untitled" : name;
        _lastSavedContent = content;
        _lastSavedCategoryId = _selectedCategoryId;
        
        setState(() {
          _hasChanges = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Note created and saved'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        print('Updating existing note...');
        // Updating existing note
        final updatedNote = Note(
          id: _currentNote!.id,
          name: name.isEmpty ? "Untitled" : name,
          content: content,
          categoryId: _selectedCategoryId ?? '',
          createdAt: _currentNote!.createdAt, // Keep original creation time
        );
        
        await _firestoreService.updateNote(updatedNote);
        print('Note updated successfully');
        
        // Update current note reference
        _currentNote = updatedNote;
        
        // Update last saved state
        _lastSavedName = name.isEmpty ? "Untitled" : name;
        _lastSavedContent = content;
        _lastSavedCategoryId = _selectedCategoryId;
        
        setState(() {
          _hasChanges = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Note updated'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      print('Auto-save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Save error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _handleBackButton() {
    if (_hasChanges && _isAutoSaveEnabled) {
      // Trigger final auto-save before leaving
      _performAutoSave().then((_) {
        Navigator.pop(context);
      });
    } else {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _nameController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Tap outside to close
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.note == null ? "Create New Note" : "Edit Note"),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _handleBackButton,
          ),
          actions: [
            // Auto-save status indicator
            if (_isAutoSaveEnabled)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isSaving)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      else if (_hasChanges)
                        const Icon(Icons.edit, size: 16, color: Colors.orange)
                      else
                        const Icon(Icons.check_circle, size: 16, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        _isSaving 
                            ? 'Saving...' 
                            : _hasChanges 
                                ? 'Unsaved' 
                                : 'Saved',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        body: WillPopScope(
          onWillPop: () async {
            _handleBackButton();
            return false;
          },
          child: GestureDetector(
            onTap: () {
              // Tap outside form to close (similar to cancel)
              if (!FocusScope.of(context).hasPrimaryFocus) {
                _handleBackButton();
              }
            },
            child: Container(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Name field
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: "Note title",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Category dropdown
                    StreamBuilder<List<Category>>(
                      stream: _categoryService.getCategories(),
                      builder: (context, snapshot) {
                        final categories = snapshot.data ?? [];
                        return DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: "Category (optional)",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.category),
                          ),
                          value: _selectedCategoryId,
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text("No category"),
                            ),
                            ...categories.map((category) => DropdownMenuItem<String>(
                              value: category.id,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: category.colorValue,
                                    radius: 12,
                                    child: Icon(
                                      category.iconData,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(category.name),
                                ],
                              ),
                            )),
                          ],
                          onChanged: _onCategoryChanged,
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Content field
                    Expanded(
                      child: TextField(
                        controller: _contentController,
                        decoration: const InputDecoration(
                          labelText: "Note content",
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                      ),
                    ),
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
