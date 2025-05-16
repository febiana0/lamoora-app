import 'dart:convert';
import 'dart:async'; // Tambahkan import untuk TimeoutException
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io'; // Untuk SocketException

class AuthService {
  // Ganti dengan URL base API Anda
  final String baseUrl = 'http://127.0.0.1:8000/api';  // 10.0.2.2 untuk Android Emulator ke localhost
  // Jika menggunakan perangkat fisik, gunakan IP komputer Anda, misalnya:
  // final String baseUrl = 'http://192.168.1.5:8000/api';

  // Method untuk register
  Future<Map<String, dynamic>> register(String name, String email, String password, String passwordConfirmation) async {
    try {
      // Debug log untuk URL yang digunakan
      print('Mengirim request ke: $baseUrl/auth/register');
      print('Data: name=$name, email=$email');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json', // Tambahkan header Accept
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      ).timeout(const Duration(seconds: 15)); // Tambahkan timeout

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Simpan token ke SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        
        // Cek apakah token ada dalam response
        if (responseData['token'] != null) {
          await prefs.setString('token', responseData['token']);
        } else {
          print('Warning: Token tidak ditemukan dalam response');
        }
        
        // Cek apakah user data ada dalam response
        if (responseData['user'] != null) {
          await prefs.setString('user', jsonEncode(responseData['user']));
        } else {
          print('Warning: User data tidak ditemukan dalam response');
        }
        
        // Return format yang sesuai dengan yang diharapkan di SignUpPage
        return {
          'success': true,
          'message': 'Registrasi berhasil',
          'data': responseData
        };
      } else {
        // Return format yang sesuai dengan yang diharapkan di SignUpPage
        return {
          'success': false,
          'message': responseData['message'] ?? 'Registrasi gagal'
        };
      }
    } on SocketException {
      print('Socket Exception: Tidak ada koneksi internet');
      return {
        'success': false,
        'message': 'Tidak ada koneksi internet. Periksa koneksi Anda.'
      };
    } on TimeoutException {
      print('Timeout Exception: Request timeout');
      return {
        'success': false,
        'message': 'Koneksi timeout. Server tidak merespon.'
      };
    } on FormatException {
      print('Format Exception: Response tidak valid JSON');
      return {
        'success': false,
        'message': 'Format response tidak valid'
      };
    } catch (e) {
      print('General Exception: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}'
      };
    }
  }

  // Method untuk login
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 15));

      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        // Simpan token ke SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        
        if (responseData['token'] != null) {
          await prefs.setString('token', responseData['token']);
        }
        
        if (responseData['user'] != null) {
          await prefs.setString('user', jsonEncode(responseData['user']));
        }
        
        return {
          'success': true,
          'message': 'Login berhasil',
          'data': responseData
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Login gagal'
        };
      }
    } catch (e) {
      print('Login error: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}'
      };
    }
  }

  // Method untuk logout
  Future<Map<String, dynamic>> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token != null) {
        final response = await http.post(
          Uri.parse('$baseUrl/auth/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(const Duration(seconds: 10));
        
        if (response.statusCode == 200) {
          // Hapus token dari SharedPreferences
          await prefs.remove('token');
          await prefs.remove('user');
          return {
            'success': true,
            'message': 'Logout berhasil'
          };
        } else {
          return {
            'success': false,
            'message': 'Logout gagal'
          };
        }
      } else {
        // Token tidak ditemukan, anggap user sudah logout
        await prefs.remove('token');
        await prefs.remove('user');
        return {
          'success': true,
          'message': 'Logout berhasil'
        };
      }
    } catch (e) {
      print('Logout error: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}'
      };
    }
  }

  // Method untuk cek apakah user sudah login
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') != null;
  }

  // Method untuk get user data
  Future<Map<String, dynamic>> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user');
      
      if (userData != null) {
        return jsonDecode(userData);
      } else {
        return {
          'success': false,
          'message': 'User data not found'
        };
      }
    } catch (e) {
      print('Get user data error: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}'
      };
    }
  }
}