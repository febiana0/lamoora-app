import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class ProductService {
  // Gunakan URL yang sama dengan AuthService
  final String baseUrl = 'http://54.151.193.220/api';

  // Method untuk mendapatkan token dari SharedPreferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Method untuk mendapatkan semua kategori
  Future<Map<String, dynamic>> getCategories() async {
    try {
      final token = await _getToken();
      
      final response = await http.get(
        Uri.parse('$baseUrl/categories'),
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      print('Get categories response status: ${response.statusCode}');
      print('Get categories response body: ${response.body}');

      // Decode response body
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        // Periksa apakah responseData adalah array atau objek dengan properti 'data'
        final data = responseData is List ? responseData : (responseData['data'] ?? []);
        
        return {
          'success': true,
          'message': 'Kategori berhasil diambil',
          'data': data
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal mengambil kategori'
        };
      }
    } on SocketException {
      return {
        'success': false,
        'message': 'Tidak ada koneksi internet. Periksa koneksi Anda.'
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Koneksi timeout. Server tidak merespon.'
      };
    } catch (e) {
      print('Get categories error: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}'
      };
    }
  }

  // Method untuk mendapatkan semua produk
  Future<Map<String, dynamic>> getProducts() async {
    try {
      final token = await _getToken();
      
      final response = await http.get(
        Uri.parse('$baseUrl/products'),
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      print('Get products response status: ${response.statusCode}');
      print('Get products response body: ${response.body}');

      // Decode response body
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        // Periksa apakah responseData adalah array atau objek dengan properti 'data'
        final data = responseData is List ? responseData : (responseData['data'] ?? []);
        
        return {
          'success': true,
          'message': 'Produk berhasil diambil',
          'data': data
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal mengambil produk'
        };
      }
    } on SocketException {
      return {
        'success': false,
        'message': 'Tidak ada koneksi internet. Periksa koneksi Anda.'
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Koneksi timeout. Server tidak merespon.'
      };
    } catch (e) {
      print('Get products error: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}'
      };
    }
  }

  // Method untuk mendapatkan produk berdasarkan kategori
  Future<Map<String, dynamic>> getProductsByCategory(String categoryId) async {
    try {
      final token = await _getToken();
      
      final response = await http.get(
        Uri.parse('$baseUrl/categories/$categoryId/products'),
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        // Periksa apakah responseData adalah array atau objek dengan properti 'data'
        final data = responseData is List ? responseData : (responseData['data'] ?? []);
        
        return {
          'success': true,
          'message': 'Produk berhasil diambil',
          'data': data
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal mengambil produk'
        };
      }
    } catch (e) {
      print('Get products by category error: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}'
      };
    }
  }

  // Method untuk mendapatkan detail produk
  Future<Map<String, dynamic>> getProductDetail(String productId) async {
    try {
      final token = await _getToken();
      
      final response = await http.get(
        Uri.parse('$baseUrl/products/$productId'),
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        // Periksa apakah responseData adalah array atau objek dengan properti 'data'
        final data = responseData is Map ? responseData : (responseData['data'] ?? {});
        
        return {
          'success': true,
          'message': 'Detail produk berhasil diambil',
          'data': data
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal mengambil detail produk'
        };
      }
    } catch (e) {
      print('Get product detail error: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}'
      };
    }
  }

  // Method untuk mencari produk
  Future<Map<String, dynamic>> searchProducts(String query) async {
    try {
      final token = await _getToken();
      
      final response = await http.get(
        Uri.parse('$baseUrl/products/search?q=$query'),
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        // Periksa apakah responseData adalah array atau objek dengan properti 'data'
        final data = responseData is List ? responseData : (responseData['data'] ?? []);
        
        return {
          'success': true,
          'message': 'Pencarian produk berhasil',
          'data': data
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Pencarian produk gagal'
        };
      }
    } catch (e) {
      print('Search products error: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}'
      };
    }
  }
}