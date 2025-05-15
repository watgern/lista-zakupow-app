// lib/models/category.dart

class Category {
  final String id;
  final String name;
  final String iconKey;
  final int? order;

  Category({
    required this.id,
    required this.name,
    required this.iconKey,
    this.order,
  });

  // Fabryka tworząca obiekt Category z dokumentu Firestore
  factory Category.fromDoc(String docId, Map<String, dynamic> data) {
    return Category(
      id: docId,
      name: data['name'] as String,
      iconKey: data['icon'] as String,
      order: data['order'] != null ? (data['order'] as int) : null,
    );
  }
}
