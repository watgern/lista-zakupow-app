// lib/models/shopping_item.dart

class ShoppingItem {
  final String id;
  final String name;
  final Map<String, dynamic> category;
  final bool isChecked;
  final String owner; // UID użytkownika

  ShoppingItem({
    required this.id,
    required this.name,
    required this.category,
    required this.isChecked,
    required this.owner,
  });

  // Fabryka tworząca obiekt ShoppingItem z dokumentu Firestore
  factory ShoppingItem.fromDoc(String docId, Map<String, dynamic> data) {
    return ShoppingItem(
      id: docId,
      name: data['name'] as String,
      category: data['category'] as Map<String, dynamic>,
      isChecked: data['isChecked'] as bool,
      owner: data['owner'] as String,
    );
  }
}
