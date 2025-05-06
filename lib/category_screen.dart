// lib/category_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:moj_pierszy_projekt/models/category.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:moj_pierszy_projekt/widgets/app_drawer.dart';

const Map<String, IconData> categoryIcons = {
  "shopping_cart": Icons.shopping_cart,
  "home": Icons.home,
  "local_florist": Icons.local_florist,
  "garden": Icons.grass,
  "travel": Icons.airplanemode_active,
};

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({Key? key}) : super(key: key);

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final CollectionReference categoriesCollection =
      FirebaseFirestore.instance.collection('categories');
  final TextEditingController _nameController = TextEditingController();
  String? _selectedIconKey;
  List<Category> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (categoryIcons.isNotEmpty) {
      _selectedIconKey = categoryIcons.keys.first;
    }
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final List<String> uidList = await getPairedUIDs();

    final snapshot = await categoriesCollection
        .where('owner', whereIn: uidList)
        .get();

    final loadedCategories = snapshot.docs.map((doc) {
      return Category.fromDoc(doc.id, doc.data() as Map<String, dynamic>);
    }).toList();

    loadedCategories.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));

    setState(() {
      _categories = loadedCategories;
      _isLoading = false;
    });
  }

  Future<List<String>> getPairedUIDs() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return [];

    final uid = currentUser.uid;
    final doc = await FirebaseFirestore.instance.collection('pairedUsers').doc(uid).get();

    if (doc.exists && doc.data()?['partner'] != null) {
      final partnerUID = doc.data()!['partner'] as String;
      return [uid, partnerUID];
    }

    return [uid];
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("Użytkownik nie zalogowany")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Zarządzaj kategoriami"),
      ),
      drawer: const AppDrawer(),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ReorderableGridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1,
                      ),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) => _buildCategoryCard(index),
                      onReorder: _onReorder,
                      dragWidgetBuilder: (index, child) => Transform.scale(
                        scale: 1.1,
                        child: Material(
                          elevation: 12,
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.transparent,
                          child: child,
                        ),
                      ),
                    ),
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: "Nazwa kategorii",
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 60,
                        child: GridView.count(
                          crossAxisCount: 6,
                          physics: const NeverScrollableScrollPhysics(),
                          children: categoryIcons.keys.map((iconKey) {
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedIconKey = iconKey;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  border: _selectedIconKey == iconKey
                                      ? Border.all(
                                          color: Theme.of(context).primaryColor, width: 2)
                                      : null,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  categoryIcons[iconKey],
                                  size: 24,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _addCategory,
                        child: const Text("Dodaj kategorię"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCategoryCard(int index) {
    final cat = _categories[index];
    return Card(
      key: ValueKey(cat.id),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/categoryItems',
            arguments: cat,
          );
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                categoryIcons[cat.iconKey] ?? Icons.category,
                size: 48,
              ),
              const SizedBox(height: 8),
              Text(
                cat.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _confirmDeleteCategory(cat),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onReorder(int oldIndex, int newIndex) async {
    final Category item = _categories.removeAt(oldIndex);
    _categories.insert(newIndex, item);

    if (mounted) {
      setState(() {});
    }

    final batch = FirebaseFirestore.instance.batch();
    for (int i = 0; i < _categories.length; i++) {
      final cat = _categories[i];
      final docRef = categoriesCollection.doc(cat.id);
      batch.update(docRef, {'order': i});
    }
    await batch.commit();
  }

  void _addCategory() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _selectedIconKey == null) return;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    await categoriesCollection.add({
      'name': name,
      'icon': _selectedIconKey,
      'owner': currentUser.uid,
      'order': _categories.length,
    });
    _nameController.clear();
    _categories.clear();
    _isLoading = true;
    _loadCategories();
  }

  void _confirmDeleteCategory(Category category) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usuń kategorię'),
        content: Text('Czy na pewno chcesz usunąć kategorię "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Usuń', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await categoriesCollection.doc(category.id).delete();
      _categories.clear();
      _isLoading = true;
      _loadCategories();
    }
  }
}
