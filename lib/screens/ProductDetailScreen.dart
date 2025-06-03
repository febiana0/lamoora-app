import 'package:flutter/material.dart';
import '/services/product_service.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import 'cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  static const routeName = '/product-detail';
  final String productId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ProductService _productService = ProductService();

  bool isLoading = true;
  String errorMessage = '';
  Map<String, dynamic> productDetail = {};

  @override
  void initState() {
    super.initState();
    _loadProductDetail();
  }

  Future<void> _loadProductDetail() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final result = await _productService.getProductDetail(widget.productId);

      setState(() {
        if (result['success']) {
          productDetail = result['data'];
        } else {
          errorMessage = result['message'];
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Terjadi kesalahan: ${e.toString()}';
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
        title: const Text(
          'Detail Produk',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartScreen()),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? _buildLoading()
          : errorMessage.isNotEmpty
              ? _buildError()
              : _buildProductDetail(),
      bottomNavigationBar: _buildBottomButton(),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Memuat detail produk...'),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Gagal memuat detail produk',
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
            onPressed: _loadProductDetail,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductDetail() {
    final String name = productDetail['name'] ?? '';
    final String imageUrl = productDetail['image'] ?? '';
    final String fullImageUrl = imageUrl.isNotEmpty ? 'http://54.151.193.220/storage/$imageUrl' : '';

    double price = 0;
    if (productDetail['price'] != null) {
      if (productDetail['price'] is String) {
        price = double.tryParse(productDetail['price']) ?? 0.0;
      } else {
        price = (productDetail['price'] as num).toDouble();
      }
    }

    final String categoryName = productDetail['category'] != null ? productDetail['category']['name'] ?? '' : '';
    final String description = productDetail['description'] ?? 'Tidak ada deskripsi';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 300,
            color: Colors.grey[200],
            child: fullImageUrl.isNotEmpty
                ? Image.network(
                    fullImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 64,
                          color: Colors.grey,
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                  )
                : const Center(
                    child: Icon(
                      Icons.image_not_supported,
                      size: 64,
                      color: Colors.grey,
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Rp. ${price.toStringAsFixed(0)}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.blue[700]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Text(
                  'Kategori: ',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                Text(
                  categoryName,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Divider(color: Colors.grey[300], thickness: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Deskripsi:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.5),
                ),
              ],
            ),
          ),
          if (productDetail['specifications'] != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Spesifikasi:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ...buildSpecifications(productDetail['specifications']),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> buildSpecifications(dynamic specifications) {
    if (specifications is List) {
      return specifications.map<Widget>((spec) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              const Icon(Icons.check_circle, size: 16, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(child: Text(spec.toString(), style: TextStyle(fontSize: 14, color: Colors.grey[800]))),
            ],
          ),
        );
      }).toList();
    } else if (specifications is Map) {
      return specifications.entries.map<Widget>((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Text('${entry.key}: ', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
              Expanded(child: Text(entry.value.toString(), style: TextStyle(fontSize: 14, color: Colors.grey[800]))),
            ],
          ),
        );
      }).toList();
    }
    return [
      Text(specifications.toString(), style: TextStyle(fontSize: 14, color: Colors.grey[800])),
    ];
  }
Widget _buildBottomButton() {
  return SafeArea(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -1),
            blurRadius: 8,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          final cartProvider = Provider.of<CartProvider>(context, listen: false);
          cartProvider.addItem(int.parse(widget.productId), 1);

          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Produk ditambahkan ke keranjang'),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'LIHAT',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CartScreen()),
                  );
                },
                textColor: Colors.white,
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text(
          'Tambah Ke Keranjang',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    ),
  );
}

}
