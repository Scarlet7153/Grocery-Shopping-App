import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:grocery_shopping_app/features/products/data/product_model.dart';
import 'package:grocery_shopping_app/core/utils/app_localizations.dart';
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
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l.byLocale(vi: 'Quản lý Sản phẩm', en: 'Product Management'), style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).cardColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.file_download_outlined, color: Theme.of(context).colorScheme.primary),
            onPressed: _exportProducts,
            tooltip: l.byLocale(vi: 'Xuất Excel', en: 'Export Excel'),
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
                  return Center(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
                      const SizedBox(height: 16),
                      Text(l.byLocale(vi: 'Đang tải ảnh lên...', en: 'Uploading image...')),
                    ],
                  ));
                }
                
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
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
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).cardColor,
      child: Column(
        children: [
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: l.byLocale(vi: 'Tìm kiếm sản phẩm...', en: 'Search products...'),
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).cardColor : const Color(0xFFF0F2F5),
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
                _buildCategoryChip(null, l.byLocale(vi: 'Tất cả', en: 'All')),
                _buildCategoryChip('Rau củ', l.byLocale(vi: 'Rau củ', en: 'Vegetables')),
                _buildCategoryChip('Trái cây', l.byLocale(vi: 'Trái cây', en: 'Fruits')),
                _buildCategoryChip('Thịt cá', l.byLocale(vi: 'Thịt cá', en: 'Meat & Fish')),
                _buildCategoryChip('Đồ khô', l.byLocale(vi: 'Đồ khô', en: 'Dry goods')),
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
        backgroundColor: Theme.of(context).cardColor,
        selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        checkmarkColor: Theme.of(context).colorScheme.primary,
        labelStyle: TextStyle(
          color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).textTheme.bodyMedium?.color,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), 
          side: BorderSide(color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor)
        ),
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    final l = AppLocalizations.of(context)!;
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(product.name ?? l.byLocale(vi: 'Sản phẩm', en: 'Product'), style: const TextStyle(fontWeight: FontWeight.bold)),
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
                        errorBuilder: (_, __, ___) => Icon(Icons.image_outlined, color: Theme.of(context).disabledColor),
                      ),
                    ),
                  const SizedBox(height: 12),
                  _buildDetailRow(l.byLocale(vi: 'Danh mục', en: 'Category'), product.category ?? 'N/A'),
                  _buildDetailRow(l.byLocale(vi: 'Giá', en: 'Price'), _currencyFormat.format(product.price ?? 0)),
                  _buildDetailRow(l.byLocale(vi: 'Đơn vị', en: 'Unit'), product.unit ?? 'sp'),
                  _buildDetailRow(l.byLocale(vi: 'Cửa hàng', en: 'Store'), product.storeName ?? 'N/A'),
                  _buildDetailRow(l.byLocale(vi: 'Trạng thái', en: 'Status'), (product.isActive ?? true) ? l.byLocale(vi: 'Đang bán', en: 'Active') : l.byLocale(vi: 'Ẩn', en: 'Hidden')),
                ],
              ),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l.byLocale(vi: 'Đóng', en: 'Close')))],
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 6))],
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
                  color: Theme.of(context).dividerColor,
                ),
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          product.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(Icons.image_outlined, color: Theme.of(context).disabledColor),
                        ),
                      )
                    : Icon(Icons.image_outlined, color: Theme.of(context).disabledColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(product.category ?? l.byLocale(vi: 'Danh mục', en: 'Category'), style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                        _buildStatusBadge(product.isActive ?? true),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(product.name ?? l.byLocale(vi: 'Chưa có tên', en: 'No name'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(_currencyFormat.format(product.price ?? 0), style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(' / ${product.unit ?? "sp"}', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 11)),
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
                  if (value == 'image') {
                    _pickAndUploadImage(product);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'image',
                    child: Row(children: [const Icon(Icons.image_outlined, size: 18, color: Colors.blue), const SizedBox(width: 8), Text(l.byLocale(vi: 'Đổi ảnh', en: 'Change image'))])
                  ),
                ],
                icon: Icon(Icons.more_vert, color: Theme.of(context).disabledColor),
              ),
            ],
          ),
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
          SnackBar(content: Text(AppLocalizations.of(context)!.byLocale(vi: 'Cập nhật ảnh sản phẩm thành công!', en: 'Product image updated successfully!')), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.byLocale(vi: 'Lỗi upload: $e', en: 'Upload error: $e')), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildStatusBadge(bool isActive) {
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: (isActive ? Colors.green : Colors.red).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isActive ? l.byLocale(vi: 'Đang bán', en: 'Active') : l.byLocale(vi: 'Ẩn', en: 'Hidden'),
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
              style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 13),
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
      
      final l = AppLocalizations.of(context)!;
      final exportData = products.map((p) => {
        l.byLocale(vi: 'ID', en: 'ID'): p.id,
        l.byLocale(vi: 'Tên sản phẩm', en: 'Product name'): p.name,
        l.byLocale(vi: 'Danh mục', en: 'Category'): p.category,
        l.byLocale(vi: 'Giá', en: 'Price'): _currencyFormat.format(p.price ?? 0),
        l.byLocale(vi: 'Đơn vị', en: 'Unit'): p.unit,
        l.byLocale(vi: 'Cửa hàng', en: 'Store'): p.storeName,
        l.byLocale(vi: 'Trạng thái', en: 'Status'): (p.isActive ?? true) ? l.byLocale(vi: 'Đang bán', en: 'Active') : l.byLocale(vi: 'Ẩn', en: 'Hidden'),
      }).toList();

      if (mounted) {
        await ExportService.exportToCsv(
          context: context,
          data: exportData,
          fileName: 'product_list_${DateFormat('yyyyMMdd').format(DateTime.now())}',
        );
      }
    } catch (e) {
      if (mounted) {
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.byLocale(vi: 'Lỗi xuất dữ liệu: $e', en: 'Export error: $e'))));
      }
    }
  }

  Widget _buildEmptyState() {
    final l = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Theme.of(context).dividerColor),
          const SizedBox(height: 16),
          Text(l.byLocale(vi: 'Không tìm thấy sản phẩm nào', en: 'No products found'), style: TextStyle(color: Theme.of(context).disabledColor)),
        ],
      ),
    );
  }
}
