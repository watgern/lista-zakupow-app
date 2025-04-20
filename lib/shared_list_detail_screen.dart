import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SharedListDetailScreen extends StatefulWidget {
  const SharedListDetailScreen({Key? key}) : super(key: key);

  @override
  State<SharedListDetailScreen> createState() => _SharedListDetailScreenState();
}

class _SharedListDetailScreenState extends State<SharedListDetailScreen> {
  final TextEditingController _itemController = TextEditingController();
  late final String listId;
  late final CollectionReference itemsCollection;

  List<String> allowedUIDs = [];
  bool loadingUIDs = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    listId = ModalRoute.of(context)!.settings.arguments as String;
    itemsCollection = FirebaseFirestore.instance
        .collection('shoppingLists')
        .doc(listId)
        .collection('items');

    _loadPairedUIDs();
  }

  Future<void> _loadPairedUIDs() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final myUID = currentUser.uid;
    final pairedDoc = await FirebaseFirestore.instance
        .collection('pairedUsers')
        .doc(myUID)
        .get();

    if (pairedDoc.exists && pairedDoc.data()?['partner'] != null) {
      final partnerUID = pairedDoc.data()!['partner'];
      setState(() {
        allowedUIDs = [myUID, partnerUID];
        loadingUIDs = false;
      });
    } else {
      setState(() {
        allowedUIDs = [myUID];
        loadingUIDs = false;
      });
    }
  }

  void _addItem() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final name = _itemController.text.trim();
    if (name.isEmpty || currentUser == null) return;

    await itemsCollection.add({
      'name': name,
      'isChecked': false,
      'timestamp': FieldValue.serverTimestamp(),
      'owner': currentUser.uid,
    });

    _itemController.clear();
  }

  void _toggleItem(String docId, bool value) {
    itemsCollection.doc(docId).update({'isChecked': value});
  }

  void _deleteItem(String docId) {
    itemsCollection.doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sparowana Lista Zakupów"),
      ),
      body: loadingUIDs
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Panel dodawania przedmiotów
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _itemController,
                          decoration:
                              const InputDecoration(labelText: "Dodaj przedmiot"),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _addItem,
                        child: const Text("Dodaj"),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                // Lista przedmiotów
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: itemsCollection
                        .where('owner', whereIn: allowedUIDs)
                        .orderBy("timestamp")
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data!.docs;
                      final items = docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return {
                          'id': doc.id,
                          'name': data['name'],
                          'isChecked': data['isChecked'] ?? false,
                        };
                      }).toList();

                      items.sort((a, b) {
                        if (a['isChecked'] == b['isChecked']) return 0;
                        return (a['isChecked'] as bool) ? 1 : -1;
                      });

                      return ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return ListTile(
                            leading: Checkbox(
                              value: item['isChecked'] as bool,
                              onChanged: (val) => _toggleItem(item['id'] as String, val ?? false),
                            ),
                            title: Text(
                              item['name'] as String,
                              style: TextStyle(
                                color: (item['isChecked'] as bool) ? Colors.red : Colors.black,
                                decoration: (item['isChecked'] as bool)
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteItem(item['id'] as String),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
