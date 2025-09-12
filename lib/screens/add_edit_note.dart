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
  bool _hasEverSaved = false; // Track if we've saved at least once
  String? _currentNoteId; // Track the actual note ID from Firestore
  DateTime? _originalCreatedAt; // Keep track of original creation time
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
      _hasEverSaved = true;
      _currentNoteId = widget.note!.id;
      _originalCreatedAt = widget.note!.createdAt;
      _nameController.text = widget.note!.name;
      _contentController.text = widget.note!.content;
      _selectedCategoryId = widget.note!.categoryId.isEmpty ? null : widget.note!.categoryId;
      
      print('Initialize existing note: ID=${widget.note!.id}, name="${widget.note!.name}", content=${widget.note!.content.length} chars');
      print('Note category ID from DB: "${widget.note!.categoryId}" -> selectedCategoryId: "$_selectedCategoryId"');
      
      // Save initial state
      _lastSavedName = widget.note!.name;
      _lastSavedContent = widget.note!.content;
      _lastSavedCategoryId = widget.note!.categoryId.isEmpty ? null : widget.note!.categoryId;
      
      print('Initialized last saved category ID: "$_lastSavedCategoryId"');
    } else {
      // Creating new note
      _hasEverSaved = false;
      _currentNoteId = null;
      _originalCreatedAt = null;
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
    
    // Auto-save after 3 seconds to prevent excessive saves
    _autoSaveTimer = Timer(const Duration(seconds: 1), () {
      if (_hasChanges && !_isSaving) {
        _performAutoSave();
      }
    });
  }

  Future<void> _performAutoSave() async {
    if (_isSaving) return;

    final name = _nameController.text.trim();
    final content = _contentController.text.trim();

    print('AutoSave: name="$name", content="${content.length} chars", category="$_selectedCategoryId"');
    print('Last saved: name="$_lastSavedName", content="${(_lastSavedContent ?? '').length} chars", category="$_lastSavedCategoryId"');

    // Don't save if both name and content are empty
    if (name.isEmpty && content.isEmpty) {
      return;
    }

    // Don't save if content is too short (less than 5 characters) and no title
    if (name.isEmpty && content.length < 5) {
      return;
    }

    // Don't save duplicate - check if content actually changed
    if (_hasEverSaved && 
        name == (_lastSavedName ?? '') && 
        content == (_lastSavedContent ?? '') && 
        _selectedCategoryId == _lastSavedCategoryId) {
      print('AutoSave skipped: no changes detected');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (!_hasEverSaved || _currentNoteId == null) {
        // Creating new note for the first time
        final newNote = Note(
          id: '', // Firestore will generate ID
          name: name.isEmpty ? "Untitled" : name,
          content: content,
          categoryId: _selectedCategoryId ?? '',
          createdAt: DateTime.now(),
        );
        
        final noteId = await _firestoreService.addNoteAndGetId(newNote);
        print('New note created with ID: $noteId, category: ${_selectedCategoryId}');
        
        // Save the note ID and creation time for future updates
        _currentNoteId = noteId;
        _originalCreatedAt = DateTime.now();
        _hasEverSaved = true;
        
      } else {
        // Updating existing note
        final updatedNote = Note(
          id: _currentNoteId!,
          name: name.isEmpty ? "Untitled" : name,
          content: content,
          categoryId: _selectedCategoryId ?? '',
          createdAt: _originalCreatedAt ?? DateTime.now(), // Keep original creation time
        );
        
        await _firestoreService.updateNote(updatedNote);
        print('Note updated with ID: ${_currentNoteId}, category: ${_selectedCategoryId}');
      }
      
      // Update last saved state
      _lastSavedName = name.isEmpty ? "Untitled" : name;
      _lastSavedContent = content;
      _lastSavedCategoryId = _selectedCategoryId;
      
      setState(() {
        _hasChanges = false;
      });
      
    } catch (e) {
      // Silent error handling - just print to console for debugging
      print('Firestore auto-save error: $e');
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
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        
                        final categories = snapshot.data ?? [];
                        
                        // Validate selected category still exists
                        final validCategoryIds = categories.map((c) => c.id).toSet();
                        
                        // If selected category doesn't exist, reset it immediately
                        String? displayValue = _selectedCategoryId;
                        if (displayValue != null && !validCategoryIds.contains(displayValue)) {
                          displayValue = null;
                          // Schedule reset after frame
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              setState(() {
                                _selectedCategoryId = null;
                                _lastSavedCategoryId = null;
                              });
                            }
                          });
                        }
                        
                        return DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: "Category (optional)",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.category),
                          ),
                          initialValue: displayValue,
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
