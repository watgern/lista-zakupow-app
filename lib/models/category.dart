// lib/models/category.dart

class Category {
  final String id;
  final String name;
  final String iconKey;

  Category({
    required this.id,
    required this.name,
    required this.iconKey,
  });

  // Fabryka tworząca obiekt Category z dokumentu Firestore
  factory Category.fromDoc(String docId, Map<String, dynamic> data) {
    return Category(
      id: docId,
      name: data['name'] as String,
      iconKey: data['icon'] as String,
    );
  }
}
