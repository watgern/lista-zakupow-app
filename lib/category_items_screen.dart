// lib/category_items_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:moj_pierszy_projekt/models/category.dart';
import 'package:moj_pierszy_projekt/models/shopping_item.dart';

const Map<String, IconData> categoryIcons = {
  "shopping_cart": Icons.shopping_cart,
  "home": Icons.home,
  "local_florist": Icons.local_florist,
  "flight": Icons.flight,
  "garden": Icons.grass,
  "travel": Icons.airplanemode_active,
};

class CategoryItemsScreen extends StatefulWidget {
  const CategoryItemsScreen({Key? key}) : super(key: key);

  @override
  State<CategoryItemsScreen> createState() => _CategoryItemsScreenState();
}

class _CategoryItemsScreenState extends State<CategoryItemsScreen> {
  final TextEditingController _itemNameController = TextEditingController();
  final CollectionReference itemsCollection =
      FirebaseFirestore.instance.collection('shoppingItems');

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
    final category = ModalRoute.of(context)!.settings.arguments as Category;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("Użytkownik nie zalogowany")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Przedmioty - \${category.name}"),
      ),
      body: FutureBuilder<List<String>>(
        future: getPairedUIDs(),
        builder: (context, uidSnapshot) {
          if (!uidSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final uidList = uidSnapshot.data!;

          final query = itemsCollection
              .where('owner', whereIn: uidList)
              .where('category.name', isEqualTo: category.name);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _itemNameController,
                        decoration: const InputDecoration(
                          labelText: 'Dodaj przedmiot',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    ElevatedButton(
                      onPressed: () => _addNewItem(category),
                      child: const Text("Dodaj"),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: query.snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text("Błąd: \${snapshot.error}"));
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data!.docs;
                    final items = docs.map((doc) {
                      return ShoppingItem.fromDoc(
                          doc.id, doc.data() as Map<String, dynamic>);
                    }).toList();
                    items.sort((a, b) {
                      if (a.isChecked == b.isChecked) return 0;
                      return a.isChecked ? 1 : -1;
                    });
                    if (items.isEmpty) {
                      return Center(child: Text("Brak przedmiotów w kategorii: \${category.name}"));
                    }
                    return ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return ListTile(
                          leading: Checkbox(
                            value: item.isChecked,
                            onChanged: (val) => _toggleItem(item, val ?? false),
                          ),
                          title: Text(
                            item.name,
                            style: TextStyle(
                              color: item.isChecked ? Colors.red : Colors.black,
                              decoration: item.isChecked
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteItem(item),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _addNewItem(Category category) {
    final itemName = _itemNameController.text.trim();
    if (itemName.isEmpty) return;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    itemsCollection.add({
      'name': itemName,
      'isChecked': false,
      'owner': currentUser.uid,
      'category': {
        'name': category.name,
        'icon': category.iconKey,
      },
      'timestamp': FieldValue.serverTimestamp(),
    });
    _itemNameController.clear();
  }

  void _toggleItem(ShoppingItem item, bool newValue) {
    itemsCollection.doc(item.id).update({'isChecked': newValue});
  }

  void _deleteItem(ShoppingItem item) {
    itemsCollection.doc(item.id).delete();
  }
}
