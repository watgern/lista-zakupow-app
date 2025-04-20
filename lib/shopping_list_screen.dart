import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'update_screen.dart';

const Map<String, IconData> categoryIcons = {
  "shopping_cart": Icons.shopping_cart,
  "home": Icons.home,
  "local_florist": Icons.local_florist,
  "flight": Icons.flight,
  "garden": Icons.grass,
  "travel": Icons.airplanemode_active,
};

class ShoppingItem {
  final String id;
  final String name;
  final Map<String, dynamic> category;
  final bool isChecked;

  ShoppingItem({
    required this.id,
    required this.name,
    required this.category,
    required this.isChecked,
  });

  factory ShoppingItem.fromDoc(String docId, Map<String, dynamic> data) {
    return ShoppingItem(
      id: docId,
      name: data['name'] as String,
      category: data['category'] as Map<String, dynamic>,
      isChecked: data['isChecked'] as bool,
    );
  }
}

class Category {
  final String id;
  final String name;
  final String iconKey;

  Category({
    required this.id,
    required this.name,
    required this.iconKey,
  });

  factory Category.fromDoc(String docId, Map<String, dynamic> data) {
    return Category(
      id: docId,
      name: data['name'] as String,
      iconKey: data['icon'] as String,
    );
  }
}

class NotificationItem {
  final String title;
  final String body;
  final Timestamp timestamp;

  NotificationItem({
    required this.title,
    required this.body,
    required this.timestamp,
  });

  factory NotificationItem.fromDoc(Map<String, dynamic> data) {
    return NotificationItem(
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }
}

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({Key? key}) : super(key: key);

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final TextEditingController _nameController = TextEditingController();
  final CollectionReference itemsCollection =
      FirebaseFirestore.instance.collection('shoppingItems');
  final CollectionReference categoriesCollection =
      FirebaseFirestore.instance.collection('categories');
  final CollectionReference notificationsCollection =
      FirebaseFirestore.instance.collection('notifications');

  Category? _selectedCategory;
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadNotificationCount();
  }

  Future<void> _loadUnreadNotificationCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final unread = await notificationsCollection
        .where('user', isEqualTo: user.uid)
        .where('read', isEqualTo: false)
        .get();

    setState(() {
      _unreadNotifications = unread.docs.length;
    });
  }

  Future<List<String>> getPairedUIDs() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return [];

    final doc = await FirebaseFirestore.instance
        .collection('pairedUsers')
        .doc(currentUser.uid)
        .get();

    if (doc.exists && doc.data()?['partner'] != null) {
      return [currentUser.uid, doc.data()!['partner']];
    }

    return [currentUser.uid];
  }

  void _openNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final query = await notificationsCollection
        .where('user', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .get();

    final notifications = query.docs
        .map((doc) => NotificationItem.fromDoc(doc.data() as Map<String, dynamic>))
        .toList();

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in query.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();

    setState(() {
      _unreadNotifications = 0;
    });

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        if (notifications.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(
              child: Text("Brak powiadomień"),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(12),
          children: notifications.map((n) {
            return ListTile(
              leading: const Icon(Icons.notifications),
              title: Text(n.title),
              subtitle: Text(n.body),
              trailing: Text(
                n.timestamp.toDate().toString().substring(0, 16),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _addNewItem() {
    final name = _nameController.text.trim();
    if (name.isEmpty || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Proszę wybrać kategorię (nie 'Wszystkie kategorie')"),
      ));
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    itemsCollection.add({
      'name': name,
      'isChecked': false,
      'owner': user.uid,
      'category': {
        'name': _selectedCategory!.name,
        'icon': _selectedCategory!.iconKey,
      },
    });

    _nameController.clear();
  }

  void _toggleItem(ShoppingItem item, bool newValue) {
    itemsCollection.doc(item.id).update({'isChecked': newValue});
  }

  void _deleteItem(ShoppingItem item) {
    itemsCollection.doc(item.id).delete();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Użytkownik nie zalogowany")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista Zakupów'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: _openNotifications,
              ),
              if (_unreadNotifications > 0)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_unreadNotifications',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
            ],
          )
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              child: const Text(
                "Menu",
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text("Kategorie"),
              onTap: () {
                Navigator.pushNamed(context, '/category');
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_circle),
              title: const Text("Konto"),
              onTap: () {
                Navigator.pushNamed(context, '/account');
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text("Parowanie kont"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/pairing');
              },
            ),
            ListTile(
              leading: const Icon(Icons.system_update),
              title: const Text("Sprawdź wersję"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const UpdateScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Wyloguj"),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<String>>(
        future: getPairedUIDs(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final uidList = snapshot.data!;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: StreamBuilder<QuerySnapshot>(
                  stream: categoriesCollection
                      .where('owner', whereIn: uidList)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                          child: Text("Błąd: ${snapshot.error.toString()}"));
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final categories = snapshot.data!.docs
                        .map((doc) => Category.fromDoc(
                            doc.id, doc.data() as Map<String, dynamic>))
                        .toList();

                    return Row(
                      children: [
                        const Text("Filtruj: "),
                        Expanded(
                          child: DropdownButton<Category?>(
                            isExpanded: true,
                            value: _selectedCategory,
                            items: [
                              const DropdownMenuItem<Category?>(
                                value: null,
                                child: Text("Wszystkie kategorie"),
                              ),
                              ...categories.map((cat) {
                                return DropdownMenuItem<Category?>(
                                  value: cat,
                                  child: Row(
                                    children: [
                                      Icon(categoryIcons[cat.iconKey] ??
                                          Icons.category),
                                      const SizedBox(width: 8),
                                      Text(cat.name),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                            onChanged: (newCat) {
                              setState(() {
                                _selectedCategory = newCat;
                              });
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: TextField(
                  controller: _nameController,
                  decoration:
                      const InputDecoration(labelText: 'Nazwa przedmiotu'),
                ),
              ),
              ElevatedButton(
                onPressed: _addNewItem,
                child: const Text('Dodaj przedmiot'),
              ),
              const Divider(),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: itemsCollection
                      .where('owner', whereIn: uidList)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final items = snapshot.data!.docs
                        .map((doc) => ShoppingItem.fromDoc(
                            doc.id, doc.data() as Map<String, dynamic>))
                        .toList();

                    final filteredItems = _selectedCategory == null
                        ? items
                        : items.where((item) {
                            return item.category['name'] ==
                                _selectedCategory!.name;
                          }).toList();

                    filteredItems.sort((a, b) {
                      if (a.isChecked == b.isChecked) return 0;
                      return a.isChecked ? 1 : -1;
                    });

                    if (filteredItems.isEmpty) {
                      return const Center(child: Text("Brak przedmiotów"));
                    }

                    return ListView.builder(
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        return ListTile(
                          leading: Checkbox(
                            value: item.isChecked,
                            onChanged: (val) =>
                                _toggleItem(item, val ?? false),
                          ),
                          title: Text(
                            item.name,
                            style: TextStyle(
                              color:
                                  item.isChecked ? Colors.red : Colors.black,
                              decoration: item.isChecked
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          ),
                          subtitle: Row(
                            children: [
                              Icon(
                                categoryIcons[item.category['icon']] ??
                                    Icons.category,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(item.category['name']),
                            ],
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
              )
            ],
          );
        },
      ),
    );
  }
}
