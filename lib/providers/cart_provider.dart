import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

class CartItemModel {
  final int id;
  final int productId; 
  final String name;
  final double price;
  int quantity;
  final String imageUrl;

  CartItemModel({
    required this.id,
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.imageUrl,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final product = json['product'] ?? {};

    return CartItemModel(
      id: int.tryParse(json['id'].toString()) ?? 0, // ✅ Cart item ID
      productId: int.tryParse(product['id'].toString()) ?? 0, // Product ID
      name: product['name'] ?? '',
      price: double.tryParse(product['price'].toString()) ?? 0.0,
      quantity: int.tryParse(json['quantity'].toString()) ?? 1,
      imageUrl: product['image'] != null
          ? 'http://54.151.193.220/storage/${product['image']}'
          : '',
    );
  }
}

class CartProvider with ChangeNotifier {
  List<CartItemModel> _items = [];
  bool _isLoading = false;

  List<CartItemModel> get items => _items;
  bool get isLoading => _isLoading;

  double get totalAmount {
    return _items.fold(0, (sum, item) => sum + item.price * item.quantity);
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> fetchCartItems() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null) throw Exception("Token tidak ditemukan");

      final dio = Dio();
      final response = await dio.get(
        'http://54.151.193.220/api/cart',
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        }),
      );

      if (response.statusCode == 200) {
        final rawData = response.data;
        List data;

        if (rawData is List) {
          data = rawData;
        } else if (rawData is Map<String, dynamic> && rawData['data'] is List) {
          data = rawData['data'];
        } else {
          data = [];
        }

        _items = data.map<CartItemModel>((e) => CartItemModel.fromJson(e)).toList();
        
        // Debug: Print cart items dengan ID
        print('=== CART ITEMS LOADED ===');
        for (var item in _items) {
          print('Cart ID: ${item.id}, Product ID: ${item.productId}, Name: ${item.name}');
        }
      } else {
        print('Gagal fetch cart. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Gagal mengambil data keranjang: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addItem(int productId, int quantity) async {
    final token = await _getToken();
    if (token == null) return;

    try {
      final dio = Dio();
      final response = await dio.post(
        'http://54.151.193.220/api/cart',
        data: {
          'product_id': productId,
          'quantity': quantity,
        },
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchCartItems();
      } else {
        print('Gagal menambah item. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Gagal menambahkan item ke cart: $e');
    }
  }

  Future<void> updateQuantity(int id, int quantity) async {
    final token = await _getToken();
    if (token == null) return;

    try {
      final dio = Dio();
      
      // Debug logging
      print('=== UPDATE QUANTITY DEBUG ===');
      print('Cart Item ID: $id');
      print('New Quantity: $quantity');
      print('URL: http://54.151.193.220/api/cart/$id');
      
      final response = await dio.put(
        'http://54.151.193.220/api/cart/$id',
        data: {'quantity': quantity},
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        }),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Data: ${response.data}');

      if (response.statusCode == 200) {
        final index = _items.indexWhere((e) => e.id == id);
        if (index != -1) {
          _items[index].quantity = quantity;
          notifyListeners();
          print('Quantity updated successfully');
        } else {
          print('Item not found in local list');
        }
      } else {
        print('Gagal update quantity. Status code: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('=== DIO ERROR DEBUG ===');
      print('Request URL: ${e.requestOptions.uri}');
      print('Request Method: ${e.requestOptions.method}');
      print('Request Data: ${e.requestOptions.data}');
      print('Response Status: ${e.response?.statusCode}');
      print('Response Data: ${e.response?.data}');
      print('Error Type: ${e.type}');
      print('Error Message: ${e.message}');
      
      if (e.response?.statusCode == 404) {
        print('Cart item dengan ID $id tidak ditemukan di server');
        // Refresh cart untuk sinkronisasi
        await fetchCartItems();
      }
    } catch (e) {
      print('Gagal update quantity: $e');
    }
  }

  Future<void> deleteItem(int id) async {
    final token = await _getToken();
    if (token == null) return;

    try {
      final dio = Dio();
      
      // Debug logging
      print('=== DELETE ITEM DEBUG ===');
      print('Cart Item ID: $id');
      print('URL: http://54.151.193.220/api/cart/$id');
      
      final response = await dio.delete(
        'http://54.151.193.220/api/cart/$id',
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        }),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Data: ${response.data}');

      if (response.statusCode == 200) {
        _items.removeWhere((e) => e.id == id);
        notifyListeners();
        print('Item deleted successfully');
      } else {
        print('Gagal hapus item. Status code: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('=== DIO ERROR DEBUG ===');
      print('Request URL: ${e.requestOptions.uri}');
      print('Response Status: ${e.response?.statusCode}');
      print('Response Data: ${e.response?.data}');
      
      if (e.response?.statusCode == 404) {
        print('Cart item dengan ID $id tidak ditemukan di server');
        // Hapus dari local juga jika tidak ada di server
        _items.removeWhere((e) => e.id == id);
        notifyListeners();
      }
    } catch (e) {
      print('Gagal hapus item: $e');
    }
  }
}