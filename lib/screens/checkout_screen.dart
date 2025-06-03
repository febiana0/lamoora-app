import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/providers/cart_provider.dart';
import '/screens/payment_webview.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItemModel> cartItems;
  final double totalAmount;

  const CheckoutScreen({
    super.key,
    required this.cartItems,
    required this.totalAmount,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _selectedShipping = 'JNE';
  bool _isLoading = false;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _checkout() async {
    if (_addressController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _selectedShipping.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua field wajib diisi!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final token = await _getToken();
      final dio = Dio();

      final checkoutResponse = await dio.post(
        'http://54.151.193.220/api/checkout',
        data: {
          'address': _addressController.text.trim(),
          'phone': _phoneController.text.trim(),
          'shipping': _selectedShipping,
          'items': widget.cartItems.map((item) => {
            'product_id': item.id,
            'quantity': item.quantity,
          }).toList(),
        },
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      print('Checkout response: ${checkoutResponse.data}');

      final transactionId = checkoutResponse.data['transaction']['id'];
      print('Transaction ID: $transactionId');


      final snapResponse = await dio.post(
        'http://54.151.193.220/api/midtrans/token',
        data: {
          'transaction_id': transactionId,
        },
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      print('Payload ke /midtrans/token: {transaction_id: $transactionId}');

      final snapToken = snapResponse.data['snap_token'];
      print('Snap Token: $snapToken');

      if (snapToken == null) throw Exception('Snap token tidak ditemukan dalam response');

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentWebView(snapToken: snapToken),
        ),
      );
    } catch (e) {
      if (e is DioException && e.response != null) {
        print('Error response data: ${e.response?.data}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: ${e.response?.data}')),
        );
      } else {
        print('Error during checkout: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memproses pembayaran: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Daftar Produk:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.cartItems.length,
              itemBuilder: (context, index) {
                final item = widget.cartItems[index];
                return ListTile(
                  title: Text(item.name),
                  subtitle: Text("Qty: ${item.quantity}"),
                  trailing: Text("Rp ${item.price.toStringAsFixed(0)}"),
                );
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Alamat Pengiriman',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'No. HP',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedShipping,
              decoration: const InputDecoration(
                labelText: 'Jasa Pengiriman',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'JNE', child: Text('JNE')),
                DropdownMenuItem(value: 'J&T', child: Text('J&T')),
                DropdownMenuItem(value: 'SiCepat', child: Text('SiCepat')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedShipping = value!;
                });
              },
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total:', style: TextStyle(fontSize: 16)),
                Text('Rp ${widget.totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _checkout,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Bayar Sekarang',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
