import 'package:flutter/material.dart';
import 'package:testproject/model/category.dart';
import 'package:testproject/services/category_service.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final CategoryService _categoryService = CategoryService();

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    String selectedColor = 'blue';
    String selectedIcon = 'folder';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Add Category"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Category name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              // Color selection
              const Text("Choose color:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['blue', 'green', 'red', 'orange', 'purple', 'teal', 'pink', 'indigo']
                    .map((color) => GestureDetector(
                          onTap: () => setDialogState(() => selectedColor = color),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: _getColor(color),
                              shape: BoxShape.circle,
                              border: selectedColor == color
                                  ? Border.all(color: Colors.black, width: 3)
                                  : null,
                            ),
                          ),
                        ))
                    .toList(),
              ),
              
              const SizedBox(height: 16),
              
              // Icon selection
              const Text("Chọn icon:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['folder', 'work', 'personal', 'study', 'health', 'travel', 'shopping', 'home', 'money']
                    .map((icon) => GestureDetector(
                          onTap: () => setDialogState(() => selectedIcon = icon),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: selectedIcon == icon ? Colors.blue.withOpacity(0.2) : null,
                              borderRadius: BorderRadius.circular(8),
                              border: selectedIcon == icon
                                  ? Border.all(color: Colors.blue, width: 2)
                                  : Border.all(color: Colors.grey.shade300),
                            ),
                            child: Icon(_getIcon(icon)),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  await _categoryService.addCategory(Category(
                    id: '',
                    name: nameController.text,
                    color: selectedColor,
                    icon: selectedIcon,
                    createdAt: DateTime.now(),
                  ));
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text("Add"),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColor(String colorName) {
    switch (colorName) {
      case 'red': return Colors.red;
      case 'green': return Colors.green;
      case 'blue': return Colors.blue;
      case 'orange': return Colors.orange;
      case 'purple': return Colors.purple;
      case 'teal': return Colors.teal;
      case 'pink': return Colors.pink;
      case 'indigo': return Colors.indigo;
      default: return Colors.blue;
    }
  }

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'work': return Icons.work;
      case 'personal': return Icons.person;
      case 'study': return Icons.school;
      case 'health': return Icons.health_and_safety;
      case 'travel': return Icons.flight;
      case 'shopping': return Icons.shopping_cart;
      case 'home': return Icons.home;
      case 'money': return Icons.attach_money;
      default: return Icons.folder;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Categories"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddCategoryDialog,
          ),
        ],
      ),
      body: StreamBuilder<List<Category>>(
        stream: _categoryService.getCategories(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading categories"));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final categories = snapshot.data!;
          
          if (categories.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("No categories yet"),
                  Text("Tap + to add a new category"),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: category.colorValue,
                    child: Icon(category.iconData, color: Colors.white),
                  ),
                  title: Text(
                    category.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: FutureBuilder<int>(
                    future: _categoryService.getNotesCountByCategory(category.id),
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      return Text("$count notes");
                    },
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text("Delete"),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) async {
                      if (value == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Xác nhận"),
                            content: Text(
                                "Are you sure you want to delete category '${category.name}'?\nAll notes in this category will become uncategorized."),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text("Cancel"),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text("Delete", style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await _categoryService.deleteCategory(category.id);
                        }
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
