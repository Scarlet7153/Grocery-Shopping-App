import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:grocery_shopping_app/features/products/data/product_model.dart';
import 'package:grocery_shopping_app/features/products/data/product_service.dart';
import 'package:grocery_shopping_app/core/utils/export_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:grocery_shopping_app/core/api/upload_service.dart';
import 'package:grocery_shopping_app/core/api/api_routes.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final ProductService _productService = ProductService();
  final UploadService _uploadService = UploadService();
  final ImagePicker _picker = ImagePicker();
  
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  String _searchQuery = '';
  String? _selectedCategory;
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text('Quản lý Sản phẩm', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined, color: Colors.indigo),
            onPressed: _exportProducts,
            tooltip: 'Xuất Excel',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: FutureBuilder<List<ProductModel>>(
              future: _productService.getProducts(search: _searchQuery, category: _selectedCategory),
              builder: (context, snapshot) {
                if (_isUploading) {
                  return const Center(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.indigo),
                      SizedBox(height: 16),
                      Text('Đang tải ảnh lên...'),
                    ],
                  ));
                }
                
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.indigo));
                }

                final products = snapshot.data ?? [];
                if (products.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: products.length,
                    itemBuilder: (context, index) => _buildProductCard(products[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Tìm kiếm sản phẩm...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: const Color(0xFFF0F2F5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCategoryChip(null, 'Tất cả'),
                _buildCategoryChip('Rau củ', 'Rau củ'),
                _buildCategoryChip('Trái cây', 'Trái cây'),
                _buildCategoryChip('Thịt cá', 'Thịt cá'),
                _buildCategoryChip('Đồ khô', 'Đồ khô'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String? category, String label) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        onSelected: (val) => setState(() => _selectedCategory = val ? category : null),
        backgroundColor: Colors.white,
        selectedColor: Colors.indigo.withValues(alpha: 0.1),
        checkmarkColor: Colors.indigo,
        labelStyle: TextStyle(
          color: isSelected ? Colors.indigo : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), 
          side: BorderSide(color: isSelected ? Colors.indigo : (Colors.grey[300] ?? Colors.grey))
        ),
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[100],
              ),
              child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_outlined, color: Colors.grey),
                      ),
                    )
                  : const Icon(Icons.image_outlined, color: Colors.grey),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(product.category ?? 'Danh mục', style: const TextStyle(color: Colors.indigo, fontSize: 10, fontWeight: FontWeight.bold)),
                      _buildStatusBadge(product.isActive ?? true),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(product.name ?? 'Chưa có tên', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(_currencyFormat.format(product.price ?? 0), style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(' / ${product.unit ?? "sp"}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                  if (product.storeName != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.store_outlined, size: 10, color: Colors.blue),
                          const SizedBox(width: 4),
                          Text(
                            '${product.storeName} (ID: ${product.storeId ?? "N/A"})',
                            style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'detail') {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: Text(product.name ?? 'Sản phẩm', style: const TextStyle(fontWeight: FontWeight.bold)),
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (product.imageUrl != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  product.imageUrl!, 
                                  height: 150, 
                                  width: double.infinity, 
                                  fit: BoxFit.cover, 
                                  errorBuilder: (_, __, ___) => const Icon(Icons.image_outlined, color: Colors.grey),
                                ),
                              ),
                            const SizedBox(height: 12),
                            _buildDetailRow('Danh mục', product.category ?? 'N/A'),
                            _buildDetailRow('Giá', _currencyFormat.format(product.price ?? 0)),
                            _buildDetailRow('Đơn vị', product.unit ?? 'sp'),
                            _buildDetailRow('Cửa hàng', product.storeName ?? 'N/A'),
                            _buildDetailRow('Trạng thái', (product.isActive ?? true) ? 'Đang bán' : 'Ẩn'),
                          ],
                        ),
                      ),
                      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng'))],
                    ),
                  );
                } else if (value == 'image') {
                  _pickAndUploadImage(product);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'detail', 
                  child: Row(children: [Icon(Icons.info_outline, size: 18), SizedBox(width: 8), Text('Chi tiết')])
                ),
                const PopupMenuItem(
                  value: 'image', 
                  child: Row(children: [Icon(Icons.image_outlined, size: 18, color: Colors.blue), SizedBox(width: 8), Text('Đổi ảnh')])
                ),
              ],
              icon: const Icon(Icons.more_vert, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  void _pickAndUploadImage(ProductModel product) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (image == null) return;

      setState(() => _isUploading = true);
      
      final String endpoint = ApiRoutes.uploadProductWithId(product.id.toString());
      await _uploadService.uploadImage(endpoint, image);

      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật ảnh sản phẩm thành công!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi upload: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: (isActive ? Colors.green : Colors.red).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isActive ? 'Đang bán' : 'Ẩn',
        style: TextStyle(color: isActive ? Colors.green : Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
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
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _exportProducts() async {
    try {
      final List<ProductModel> products = await _productService.getProducts();
      
      final exportData = products.map((p) => {
        'ID': p.id,
        'Tên sản phẩm': p.name,
        'Danh mục': p.category,
        'Giá': _currencyFormat.format(p.price ?? 0),
        'Đơn vị': p.unit,
        'Cửa hàng': p.storeName,
        'Trạng thái': (p.isActive ?? true) ? 'Đang bán' : 'Ẩn',
      }).toList();

      if (mounted) {
        await ExportService.exportToCsv(
          context: context,
          data: exportData,
          fileName: 'danhsach_sanpham_${DateFormat('yyyyMMdd').format(DateTime.now())}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi xuất dữ liệu: $e')));
      }
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('Không tìm thấy sản phẩm nào', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
