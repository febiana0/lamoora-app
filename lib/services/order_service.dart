import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OrderService {
  final String baseUrl = 'http://54.151.193.220/api'; // ganti sesuai backend kamu

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, dynamic>> getUserOrders() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/transactions'),
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData['data'] ?? [],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal memuat pesanan',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }
}