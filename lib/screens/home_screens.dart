import 'package:flutter/material.dart';
import '/services/auth_service.dart';
import '/services/product_service.dart';
import 'ProductDetailScreen.dart';
import 'cart_screen.dart'; 
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProductService _productService = ProductService();
  final AuthService _authService = AuthService();
  
  List<Map<String, dynamic>> allProducts = [];
  List<Map<String, dynamic>> filteredProducts = [];
  List<Map<String, dynamic>> categories = [];
  
  String selectedCategory = 'Semua';
  String searchQuery = '';
  bool isLoading = true;
  String errorMessage = '';
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  // Load data dari API
  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    
    try {
      // Ambil data kategori
      final categoriesResult = await _productService.getCategories();
      
      // Ambil data produk
      final productsResult = await _productService.getProducts();
      
      setState(() {
        if (categoriesResult['success']) {
          // Format data kategori
          if (categoriesResult['data'] is List) {
            categories = List<Map<String, dynamic>>.from(
              categoriesResult['data'].map((item) => 
                item is Map<String, dynamic> ? item : {}
              ).toList()
            );
          }
        } else {
          errorMessage = categoriesResult['message'];
        }
        
        if (productsResult['success']) {
          // Format data produk
          if (productsResult['data'] is List) {
            allProducts = List<Map<String, dynamic>>.from(
              productsResult['data'].map((item) => 
                item is Map<String, dynamic> ? item : {}
              ).toList()
            );
            filteredProducts = List.from(allProducts);
          }
        } else {
          errorMessage = productsResult['message'];
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
  
  // Filter produk berdasarkan kategori dan pencarian
  void filterProducts() {
    setState(() {
      if (selectedCategory == 'Semua') {
        // Jika kategori Semua, filter hanya berdasarkan pencarian
        filteredProducts = allProducts.where((product) {
          final name = product['name'] ?? '';
          return name.toString().toLowerCase().contains(searchQuery.toLowerCase());
        }).toList();
      } else {
        // Filter berdasarkan kategori dan pencarian
        filteredProducts = allProducts.where((product) {
          final category = product['category'] ?? {};
          final categoryName = category['name'] ?? '';
          final name = product['name'] ?? '';
          
          bool categoryMatch = categoryName == selectedCategory;
          bool searchMatch = name.toString().toLowerCase().contains(searchQuery.toLowerCase());
          
          return categoryMatch && searchMatch;
        }).toList();
      }
    });
  }

  // Navigate to selected bottom nav item
void _onBottomNavTap(int index) {
  if (index == 0) {
    // Already on home screen, do nothing
  } else if (index == 1) {
    // Navigate to cart screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CartScreen()),
    );
  } else if (index == 2) {
    // Navigate to profile screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: isLoading
            ? _buildLoading()
            : errorMessage.isNotEmpty
                ? _buildError()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      _buildSearchBar(),
                      _buildCategories(),
                      _buildProductHeader(),
                      Expanded(
                        child: _buildProductGrid(context),
                      ),
                    ],
                  ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Memuat data...'),
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
          Text(
            'Gagal memuat data',
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
            onPressed: _loadData,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 15),
      child: Text(
        'Lamoora',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          onChanged: (value) {
            searchQuery = value;
            filterProducts();
          },
          decoration: InputDecoration(
            hintText: 'Cari Barang',
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
            hintStyle: TextStyle(color: Colors.grey[400]),
          ),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    // Pastikan 'Semua' ada di daftar kategori
    List<String> categoryNames = ['Semua'];
    categoryNames.addAll(categories.map<String>((category) => 
      (category['name'] ?? '').toString()
    ).toList());
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text(
              'Kategori',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: categoryNames.map((category) {
                return _buildCategoryItem(category);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(String title) {
    final isSelected = selectedCategory == title;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = title;
          filterProducts();
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Produk Terbaru',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '${filteredProducts.length} produk',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid(BuildContext context) {
    if (filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Produk tidak ditemukan',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coba ubah kriteria pencarian atau kategori',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 15,
        crossAxisSpacing: 15,
        childAspectRatio: 0.8,
      ),
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        return _buildProductCard(
          context,
          product,
        );
      },
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    Map<String, dynamic> product,
  ) {

    final int productId = product['id'] ?? 0;
    final String imageUrl = product['image'] ?? '';
    final String name = product['name'] ?? '';
    
    final String price;
    if (product['price'] != null) {
      double priceValue;
      if (product['price'] is String) {
        priceValue = double.tryParse(product['price']) ?? 0.0;
      } else {
        priceValue = (product['price'] as num).toDouble();
      }
      price = 'Rp ${priceValue.toStringAsFixed(0)}';
    } else {
      price = 'Rp 0';
    }
    
    String fullImageUrl = '';
    if (imageUrl.isNotEmpty) {
       fullImageUrl = 'http://54.151.193.220/storage/$imageUrl';
    }
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(
              productId: productId.toString(),
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
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
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                child: Container(
                  width: double.infinity,
                  color: Colors.grey[200],
                  child: fullImageUrl.isNotEmpty
                      ? Image.network(
                          fullImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            print('Error loading image: $error');
                            return Center(
                              child: Icon(
                                Icons.image_not_supported,
                                color: Colors.grey[400],
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey[400],
                          ),
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Text(
                price,
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: 0,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: false,
      showSelectedLabels: false,
      type: BottomNavigationBarType.fixed,
      onTap: _onBottomNavTap, // Add this line to handle navigation
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart),
          label: 'Cart',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}