// lib/category_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:moj_pierszy_projekt/models/category.dart';

const Map<String, IconData> categoryIcons = {
  "shopping_cart": Icons.shopping_cart,
  "home": Icons.home,
  "local_florist": Icons.local_florist,
  "flight": Icons.flight,
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

  @override
  void initState() {
    super.initState();
    if (categoryIcons.isNotEmpty) {
      _selectedIconKey = categoryIcons.keys.first;
    }
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
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<String>>(
              future: getPairedUIDs(),
              builder: (context, uidSnapshot) {
                if (!uidSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final List<String> uidList = uidSnapshot.data!;

                return StreamBuilder<QuerySnapshot>(
                  stream: categoriesCollection
                      .where('owner', whereIn: uidList)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text("Błąd: \${snapshot.error}"));
                    }
                    final docs = snapshot.data!.docs;
                    final categories = docs.map((doc) {
                      return Category.fromDoc(doc.id, doc.data() as Map<String, dynamic>);
                    }).toList();

                    return GridView.count(
                      crossAxisCount: 2,
                      childAspectRatio: 0.9,
                      children: categories.map((cat) {
                        return Card(
                          margin: const EdgeInsets.all(8),
                          elevation: 2,
                          child: InkWell(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/categoryItems',
                                arguments: cat,
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
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
                                        fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.delete, size: 16),
                                    label: const Text("Usuń"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 4),
                                      textStyle: const TextStyle(fontSize: 14),
                                    ),
                                    onPressed: () => _confirmDeleteCategory(cat),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                );
              },
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

  void _addCategory() {
    final name = _nameController.text.trim();
    if (name.isEmpty || _selectedIconKey == null) return;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    categoriesCollection.add({
      'name': name,
      'icon': _selectedIconKey,
      'owner': currentUser.uid,
    });
    _nameController.clear();
  }

  void _confirmDeleteCategory(Category category) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usuń kategorię'),
        content: Text('Czy na pewno chcesz usunąć kategorię "\${category.name}"?'),
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

      final batch = FirebaseFirestore.instance.batch();
      final query = await FirebaseFirestore.instance
          .collection('shoppingItems')
          .where('category.name', isEqualTo: category.name)
          .get();

      for (var doc in query.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kategoria "\${category.name}" została usunięta')),
      );
    }
  }
} 
