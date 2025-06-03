import 'package:flutter/material.dart';
import '/services/order_service.dart'; 

class PesananSayaScreen extends StatefulWidget {
  const PesananSayaScreen({super.key});

  @override
  State<PesananSayaScreen> createState() => _PesananSayaScreenState();
}

class _PesananSayaScreenState extends State<PesananSayaScreen> {
  final OrderService _orderService = OrderService();
  
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final result = await _orderService.getUserOrders();
      
      if (result['success']) {
        setState(() {
          orders = List<Map<String, dynamic>>.from(result['data'] ?? []);
        });
      } else {
        setState(() {
          errorMessage = result['message'] ?? 'Gagal memuat pesanan';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pesanan saya',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? _buildLoading()
          : errorMessage.isNotEmpty
              ? _buildError()
              : orders.isEmpty
                  ? _buildEmptyState()
                  : _buildOrderList(),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Memuat pesanan...'),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          const Text(
            'Gagal memuat pesanan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadOrders,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            'Belum ada pesanan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pesanan Anda akan muncul di sini',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Mulai Belanja',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList() {
    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          final itemsRaw = order['items'];
          final List items;
          if (itemsRaw is List) {
            items = itemsRaw;
          } else if (itemsRaw is Map) {
            items = [itemsRaw];
          } else {
            items = [];
          }

          print('order id: ${order['id']}');
          print('items type: ${items.runtimeType}');
          print('items: $items');

          return _buildOrderCard(order);
        },
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
  final String status = order['status'] ?? '';
  final String date = order['created_at'] ?? '';
  final double total = (order['total_price'] is String)
      ? double.tryParse(order['total_price']) ?? 0.0
      : (order['total_price'] as num?)?.toDouble() ?? 0.0;
  final List itemsRaw = order['items'] is List
      ? order['items']
      : (order['items'] is Map ? [order['items']] : []);
  final String address = order['address'] ?? '-';
  final String phone = order['phone'] ?? '-';

  // Format tanggal
  String formatDate = date;
  try {
    if (date.isNotEmpty) {
      final dateTime = DateTime.parse(date);
      formatDate = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  } catch (e) {}

  // Status color
  Color statusColor = Colors.grey;
  String statusText = status;
  switch (status.toLowerCase()) {
    case 'paid':
      statusColor = Colors.green;
      statusText = 'PAID';
      break;
    case 'shipped':
      statusColor = Colors.purple;
      statusText = 'SHIPPED';
      break;
    case 'delivered':
      statusColor = Colors.green;
      statusText = 'Selesai';
      break;
    case 'cancelled':
      statusColor = Colors.red;
      statusText = 'Dibatalkan';
      break;
  }

  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Colors.grey.withOpacity(0.2),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header dengan ID dan Status
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pesanan #${order['id']}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Tanggal
        Text(
          formatDate,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        // Alamat & Telepon
        Row(
          children: [
            const Icon(Icons.location_on, size: 16, color: Colors.blue),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                address,
                style: const TextStyle(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.phone, size: 16, color: Colors.blue),
            const SizedBox(width: 4),
            Text(
              phone,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Jumlah produk
        Text(
          '${itemsRaw.length} produk',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        // Total harga
        Text(
          'Total: Rp ${total.toStringAsFixed(0)}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 8),
        // List produk (opsional, tampilkan nama produk)
        ...itemsRaw.map((item) => Text(
          '- ${item['product']?['name'] ?? ''} (Qty: ${item['quantity']})',
          style: const TextStyle(fontSize: 13),
        )),
      ],
    ),
  );
}

  void _showOrderDetail(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Detail Pesanan #${order['id']}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order info
                    _buildDetailRow('Status', order['status'] ?? ''),
                    _buildDetailRow('Tanggal', order['created_at'] ?? ''),
                    _buildDetailRow('Total', 'Rp ${((order['total_price'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(0)}'),
                    
                    const SizedBox(height: 20),
                    
                    // Items
                    const Text(
                      'Items:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Items list (ini contoh, sesuaikan dengan struktur data Anda)
                    ...(() {
                      final itemsRaw = order['items'];
                      final List items = (itemsRaw is List)
                          ? itemsRaw
                          : (itemsRaw is Map ? [itemsRaw] : []);
                      return items.map((item) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['product']?['name'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    'Qty: ${item['quantity']} x Rp ${item['price']}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )).toList();
                    })(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}




