import 'package:flutter/material.dart';
import 'package:grocery_shopping_app/features/orders/data/order_model.dart';
import 'package:grocery_shopping_app/features/orders/data/order_service.dart';
import 'package:intl/intl.dart';

class AddEditOrderScreen extends StatefulWidget {
  final OrderModel? order;

  const AddEditOrderScreen({super.key, this.order});

  @override
  State<AddEditOrderScreen> createState() => _AddEditOrderScreenState();
}

class _AddEditOrderScreenState extends State<AddEditOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _orderService = OrderService();
  bool _isReadOnly = false;

  final _addressController = TextEditingController();
  final _customerController = TextEditingController();
  final _storeController = TextEditingController();
  final _shipperController = TextEditingController();
  
  Map<String, dynamic>? _selectedCustomer;
  Map<String, dynamic>? _selectedShipper;
  Map<String, dynamic>? _selectedStore;
  List<OrderItemModel> _items = [];
  String _status = 'PENDING';

  bool _isLoading = false;
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _shippers = [];
  List<Map<String, dynamic>> _stores = [];
  List<Map<String, dynamic>> _storeProducts = [];

  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  
  final _customerFocusNode = FocusNode();
  final _storeFocusNode = FocusNode();
  final _shipperFocusNode = FocusNode();

  @override
  void dispose() {
    _addressController.dispose();
    _customerController.dispose();
    _storeController.dispose();
    _shipperController.dispose();
    _customerFocusNode.dispose();
    _storeFocusNode.dispose();
    _shipperFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.order != null) {
      _addressController.text = widget.order!.address ?? '';
      _customerController.text = widget.order!.customerName ?? '';
      _storeController.text = widget.order!.storeName ?? '';
      _shipperController.text = widget.order!.shipperName ?? '';
      _status = widget.order!.status ?? 'PENDING';
      _items = List.from(widget.order!.items ?? []);
      _isReadOnly = true;
    }
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _orderService.fetchCustomersSuggestion(),
        _orderService.fetchShippersSuggestion(),
        _orderService.fetchStoresSuggestion(),
      ]);

      setState(() {
        _customers = results[0];
        _shippers = results[1];
        _stores = results[2];
        
        if (widget.order != null) {
          try {
            _selectedCustomer = _customers.firstWhere((u) => u['id'].toString() == widget.order!.customerId.toString());
          } catch (_) {}
          try {
            _selectedShipper = _shippers.firstWhere((u) => u['id'].toString() == widget.order!.shipperId.toString());
          } catch (_) {}
          try {
            _selectedStore = _stores.firstWhere((s) => s['id'].toString() == widget.order!.storeId.toString());
            _fetchStoreProducts(_selectedStore!['id'].toString());
          } catch (_) {}
        }
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchStoreProducts(String storeId) async {
    final products = await _orderService.fetchProductsByStore(storeId);
    setState(() {
      _storeProducts = products;
      // Clear items if changing store
      if (widget.order == null) _items = [];
    });
  }

  double get _totalAmount {
    return _items.fold(0.0, (sum, item) => sum + (item.subtotal ?? 0.0));
  }

  void _addItem() {
    if (_selectedStore == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn cửa hàng trước')));
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _ProductPicker(
        products: _storeProducts,
        onSelected: (product, quantity) {
          setState(() {
            final units = product['units'] as List?;
            final firstUnit = units != null && units.isNotEmpty ? units[0] : null;
            
            _items.add(OrderItemModel(
              productId: int.tryParse(product['id'].toString()),
              productName: product['name'],
              quantity: quantity,
              unitPrice: firstUnit != null ? (firstUnit['price'] as num).toDouble() : 0.0,
              subtotal: (firstUnit != null ? (firstUnit['price'] as num).toDouble() : 0.0) * quantity,
            ));
          });
        },
      ),
    );
  }

  Future<void> _saveOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn khách hàng')));
      return;
    }
    if (_selectedStore == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn cửa hàng')));
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng thêm ít nhất một sản phẩm')));
      return;
    }

    setState(() => _isLoading = true);
    
    final orderData = OrderModel(
      id: widget.order?.id,
      customerId: int.tryParse(_selectedCustomer!['id'].toString()),
      customerName: _selectedCustomer!['fullName'],
      customerPhone: _selectedCustomer!['phoneNumber'],
      shipperId: _selectedShipper != null ? int.tryParse(_selectedShipper!['id'].toString()) : null,
      shipperName: _selectedShipper?['fullName'],
      storeId: int.tryParse(_selectedStore!['id'].toString()),
      storeName: _selectedStore!['storeName'] ?? _selectedStore!['name'],
      address: _addressController.text,
      status: _status,
      totalAmount: _totalAmount,
      items: _items,
    );

    bool success = await _orderService.createOrderSimulated(orderData);

    setState(() => _isLoading = false);
    
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu đơn hàng (Mô phỏng)')));
        Navigator.pop(context, true);
      }
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi khi lưu đơn hàng')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.order == null ? 'Thêm Đơn hàng' : 'Chi tiết Đơn hàng'),
        actions: [
          if (!_isLoading && !_isReadOnly)
            IconButton(onPressed: _saveOrder, icon: const Icon(Icons.check, color: Colors.green)),
        ],
      ),
      body: _isLoading && _customers.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSectionTitle('Thông tin đối tác'),
                  _buildCustomerAutocomplete(),
                  const SizedBox(height: 16),
                  _buildStoreAutocomplete(),
                  const SizedBox(height: 16),
                  _buildShipperAutocomplete(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Thông tin giao hàng'),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Địa chỉ nhận hàng',
                      prefixIcon: Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(),
                    ),
                    enabled: !_isReadOnly,
                    validator: (v) => v == null || v.isEmpty ? 'Không được để trống' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _status,
                    decoration: const InputDecoration(labelText: 'Trạng thái', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'PENDING', child: Text('Chờ xử lý')),
                      DropdownMenuItem(value: 'CONFIRMED', child: Text('Đã xác nhận')),
                      DropdownMenuItem(value: 'DELIVERING', child: Text('Đang giao')),
                      DropdownMenuItem(value: 'DELIVERED', child: Text('Hoàn thành')),
                      DropdownMenuItem(value: 'CANCELLED', child: Text('Đã hủy')),
                    ],
                    onChanged: _isReadOnly ? null : (v) => setState(() => _status = v!),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle('Danh sách món ăn'),
                      if (!_isReadOnly)
                        TextButton.icon(
                          onPressed: _addItem,
                          icon: const Icon(Icons.add),
                          label: const Text('Thêm món'),
                        ),
                    ],
                  ),
                  ..._items.asMap().entries.map((entry) => _buildItemTile(entry.key, entry.value)),
                  if (_items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: Text('Chưa có món ăn nào', style: TextStyle(color: Colors.grey))),
                    ),
                  const Divider(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TỔNG CỘNG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(_currencyFormat.format(_totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.indigo)),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }

  Widget _buildCustomerAutocomplete() {
    return Autocomplete<Map<String, dynamic>>(
      textEditingController: _customerController,
      focusNode: _customerFocusNode,
      displayStringForOption: (u) => '${u['fullName']} (${u['phoneNumber']})',
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) return const Iterable<Map<String, dynamic>>.empty();
        return _customers.where((u) => 
          u['fullName']!.toString().toLowerCase().contains(textEditingValue.text.toLowerCase()) || 
          u['phoneNumber']!.toString().contains(textEditingValue.text));
      },
      onSelected: (u) {
        setState(() {
          _selectedCustomer = u;
        });
      },
      optionsViewBuilder: (context, onSelected, options) {
        return _buildAutocompleteOptions<Map<String, dynamic>>(
          options: options,
          onSelected: onSelected,
          titleBuilder: (u) => u['fullName'],
          subtitleBuilder: (u) => 'SĐT: ${u['phoneNumber']} • Trạng thái: ${u['status']}',
          icon: Icons.person_outline,
        );
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: const InputDecoration(
            labelText: 'Khách hàng', 
            prefixIcon: Icon(Icons.person_outline), 
            border: OutlineInputBorder(), 
            hintText: 'Tìm khách hàng...',
            floatingLabelBehavior: FloatingLabelBehavior.always,
          ),
          enabled: !_isReadOnly,
          onChanged: (v) {
            if (v.isEmpty && _selectedCustomer != null) {
              setState(() => _selectedCustomer = null);
            }
          },
        );
      },
    );
  }

  Widget _buildShipperAutocomplete() {
    return Autocomplete<Map<String, dynamic>>(
      textEditingController: _shipperController,
      focusNode: _shipperFocusNode,
      displayStringForOption: (u) => '${u['fullName']} (${u['phoneNumber']})',
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) return const Iterable<Map<String, dynamic>>.empty();
        return _shippers.where((u) => 
          u['fullName']!.toString().toLowerCase().contains(textEditingValue.text.toLowerCase()) || 
          u['phoneNumber']!.toString().contains(textEditingValue.text));
      },
      onSelected: (u) {
        setState(() {
          _selectedShipper = u;
        });
      },
      optionsViewBuilder: (context, onSelected, options) {
        return _buildAutocompleteOptions<Map<String, dynamic>>(
          options: options,
          onSelected: onSelected,
          titleBuilder: (u) => u['fullName'],
          subtitleBuilder: (u) => 'SĐT: ${u['phoneNumber']} • Trạng thái: ${u['status']}',
          icon: Icons.delivery_dining_outlined,
        );
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: const InputDecoration(
            labelText: 'Shipper (Không bắt buộc)', 
            prefixIcon: Icon(Icons.delivery_dining_outlined), 
            border: OutlineInputBorder(), 
            hintText: 'Tìm shipper...',
            floatingLabelBehavior: FloatingLabelBehavior.always,
          ),
          enabled: !_isReadOnly,
          onChanged: (v) {
            if (v.isEmpty && _selectedShipper != null) {
              setState(() => _selectedShipper = null);
            }
          },
        );
      },
    );
  }

  Widget _buildStoreAutocomplete() {
    return Autocomplete<Map<String, dynamic>>(
      textEditingController: _storeController,
      focusNode: _storeFocusNode,
      displayStringForOption: (s) => s['storeName'] ?? s['name'] ?? '',
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) return const Iterable<Map<String, dynamic>>.empty();
        return _stores.where((s) => (s['storeName'] ?? s['name'])!.toString().toLowerCase().contains(textEditingValue.text.toLowerCase()));
      },
      onSelected: (s) {
        setState(() {
          _selectedStore = s;
        });
        _fetchStoreProducts(s['id'].toString());
      },
      optionsViewBuilder: (context, onSelected, options) {
        return _buildAutocompleteOptions<Map<String, dynamic>>(
          options: options,
          onSelected: onSelected,
          titleBuilder: (s) => s['storeName'] ?? s['name'],
          subtitleBuilder: (s) => 'Chủ: ${s['ownerName']} • ĐC: ${s['address']}',
          icon: Icons.storefront_outlined,
        );
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: const InputDecoration(
            labelText: 'Cửa hàng', 
            prefixIcon: Icon(Icons.storefront_outlined), 
            border: OutlineInputBorder(), 
            hintText: 'Tìm cửa hàng...',
            floatingLabelBehavior: FloatingLabelBehavior.always,
          ),
          enabled: !_isReadOnly,
          onChanged: (v) {
            if (v.isEmpty && _selectedStore != null) {
              setState(() {
                _selectedStore = null;
                _items = []; // Clear products if store is cleared
              });
            }
          },
        );
      },
    );
  }

  Widget _buildAutocompleteOptions<T extends Object>({
    required Iterable<T> options,
    required AutocompleteOnSelected<T> onSelected,
    required String Function(T) titleBuilder,
    required String Function(T) subtitleBuilder,
    required IconData icon,
  }) {
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: Container(
          width: MediaQuery.of(context).size.width - 32,
          constraints: const BoxConstraints(maxHeight: 300),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: options.length,
            separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
            itemBuilder: (context, index) {
              final option = options.elementAt(index);
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.indigo.withOpacity(0.1),
                  child: Icon(icon, color: Colors.indigo, size: 20),
                ),
                title: Text(
                  titleBuilder(option),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(
                  subtitleBuilder(option),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => onSelected(option),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                hoverColor: Colors.indigo.withOpacity(0.05),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildItemTile(int index, OrderItemModel item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(item.productName ?? 'Sản phẩm'),
        subtitle: Text('Số lượng: ${item.quantity} x ${_currencyFormat.format(item.unitPrice ?? 0)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_currencyFormat.format(item.subtotal ?? 0), style: const TextStyle(fontWeight: FontWeight.bold)),
            if (!_isReadOnly)
              IconButton(onPressed: () => setState(() => _items.removeAt(index)), icon: const Icon(Icons.delete_outline, color: Colors.red)),
          ],
        ),
      ),
    );
  }
}

class _ProductPicker extends StatefulWidget {
  final List<Map<String, dynamic>> products;
  final Function(Map<String, dynamic>, int) onSelected;

  const _ProductPicker({required this.products, required this.onSelected});

  @override
  State<_ProductPicker> createState() => _ProductPickerState();
}

class _ProductPickerState extends State<_ProductPicker> {
  Map<String, dynamic>? _selected;
  int _quantity = 1;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.products.where((p) => p['name']!.toString().toLowerCase().contains(_search.toLowerCase())).toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Thêm sản phẩm từ cửa hàng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(hintText: 'Tìm sản phẩm...', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
            onChanged: (v) => setState(() => _search = v),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 250,
            child: filtered.isEmpty 
              ? const Center(child: Text('Không tìm thấy sản phẩm nào'))
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final p = filtered[index];
                    final units = p['units'] as List?;
                    final firstUnit = units != null && units.isNotEmpty ? units[0] : null;
                    final price = firstUnit != null ? (firstUnit['price'] as num).toDouble() : 0.0;
                    
                    return ListTile(
                      title: Text(p['name'] ?? ''),
                      subtitle: Text(NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(price)),
                      selected: _selected?['id'] == p['id'],
                      onTap: () => setState(() => _selected = p),
                    );
                  },
                ),
          ),
          if (_selected != null) ...[
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Số lượng:'),
                Row(
                  children: [
                    IconButton(onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null, icon: const Icon(Icons.remove)),
                    Text('$_quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(onPressed: () => setState(() => _quantity++), icon: const Icon(Icons.add)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onSelected(_selected!, _quantity);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                child: const Text('Thêm vào đơn hàng'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
