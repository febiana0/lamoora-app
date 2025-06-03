import 'category.dart';

class Product {
  final int id;
  final int userId;
  final int categoryId;
  final String name;
  final String description;
  final double price;
  final String image;
  final int stock;
  final String createdAt;
  final String updatedAt;
  final Category category;

  Product({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.price,
    required this.image,
    required this.stock,
    required this.createdAt,
    required this.updatedAt,
    required this.category,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      userId: json['user_id'],
      categoryId: json['category_id'],
      name: json['name'],
      description: json['description'],
      price: double.parse(json['price']), // Konversi string ke double
      image: json['image'],
      stock: json['stock'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      category: Category.fromJson(json['category']),
    );
  }
}