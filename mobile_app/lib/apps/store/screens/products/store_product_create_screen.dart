import 'package:flutter/material.dart';
import 'dart:typed_data';

import '../../../../core/api/api_error.dart';
import '../../../../core/utils/image_picker_helper.dart';
import '../../../../core/theme/store_theme.dart';
import '../../../../features/products/data/category_model.dart';
import '../../../../features/products/data/product_model.dart';
import '../../../../features/products/data/product_service.dart';
import '../../../../features/products/data/unit_model.dart';
import '../../../../features/products/data/unit_service.dart';

class StoreProductCreateScreen extends StatefulWidget {
  final List<CategoryModel> categories;

  const StoreProductCreateScreen({
    super.key,
    required this.categories,
  });

  @override
  State<StoreProductCreateScreen> createState() => _StoreProductCreateScreenState();
}

class _StoreProductCreateScreenState extends State<StoreProductCreateScreen> {
  final UnitService _unitService = UnitService();
  final ProductService _productService = ProductService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  final List<TextEditingController> _labelControllers = [];
  final List<TextEditingController> _sizeControllers = [];
  final List<TextEditingController> _priceControllers = [];
  final List<TextEditingController> _stockControllers = [];
  final List<String> _unitCodeSelections = [];

  List<Unit> _dbUnits = [];
  int? _selectedCategoryId;
  Uint8List? _selectedImageBytes;
  bool _isSaving = false;

  Future<void> _pickProductImage() async {
    try {
      final picked = await ImagePickerHelper.pickFromGallery(context);
      if (picked == null) {
        return;
      }
      final bytes = await picked.readAsBytes();
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedImageBytes = bytes;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể chọn ảnh, vui lòng thử lại')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.categories.isNotEmpty ? widget.categories.first.id : null;
    _loadUnits();
    _addVariantRow();
  }

  Future<void> _loadUnits() async {
    try {
      final units = await _unitService.getAllUnits();
      if (!mounted) {
        return;
      }
      setState(() {
        _dbUnits = units;
        if (_unitCodeSelections.isEmpty) {
          _unitCodeSelections.add(_defaultUnitCode);
        }
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        if (_unitCodeSelections.isEmpty) {
          _unitCodeSelections.add(_defaultUnitCode);
        }
      });
    }
  }

  List<String> get _unitCodes {
    if (_dbUnits.isEmpty) {
      return const ['kg'];
    }
    return _dbUnits.map((u) => u.code).toList();
  }

  String get _defaultUnitCode => _unitCodes.first;

  Unit _fallbackUnit(String code) {
    return Unit(
      id: 0,
      categoryId: 0,
      code: code,
      name: code,
      symbol: code,
      baseUnit: null,
      conversionRate: 1,
      requiresQuantityInput: false,
    );
  }

  Unit _unitByCode(String code) {
    final match = _dbUnits.where((u) => u.code == code);
    if (match.isNotEmpty) {
      return match.first;
    }
    return _fallbackUnit(code);
  }

  bool _requiresQuantityInput(int index) {
    final code = _unitCodeSelections[index];
    return _unitByCode(code).requiresQuantityInput;
  }

  String _unitLabel(String code) {
    final unit = _unitByCode(code);
    return unit.symbol.isNotEmpty ? '${unit.name} (${unit.symbol})' : unit.name;
  }

  String _autoLabel(Unit unit, double quantity) {
    final normalized = quantity == quantity.roundToDouble()
        ? quantity.toInt().toString()
        : quantity.toString();
    return '$normalized${unit.symbol}';
  }

  void _addVariantRow() {
    setState(() {
      _labelControllers.add(TextEditingController());
      _sizeControllers.add(TextEditingController());
      _priceControllers.add(TextEditingController());
      _stockControllers.add(TextEditingController(text: '0'));
      _unitCodeSelections.add(_defaultUnitCode);
    });
  }

  void _removeVariantRow(int index) {
    if (_labelControllers.length <= 1) {
      return;
    }

    setState(() {
      _labelControllers[index].dispose();
      _sizeControllers[index].dispose();
      _priceControllers[index].dispose();
      _stockControllers[index].dispose();

      _labelControllers.removeAt(index);
      _sizeControllers.removeAt(index);
      _priceControllers.removeAt(index);
      _stockControllers.removeAt(index);
      _unitCodeSelections.removeAt(index);
    });
  }

  void _onUnitChanged(int index, String? code) {
    if (code == null || code.isEmpty) {
      return;
    }

    setState(() {
      _unitCodeSelections[index] = code;
      final unit = _unitByCode(code);
      if (unit.requiresQuantityInput) {
        final size = double.tryParse(_sizeControllers[index].text.trim());
        if (size != null && size > 0) {
          _labelControllers[index].text = _autoLabel(unit, size);
        } else {
          _labelControllers[index].clear();
        }
      }
    });
  }

  void _onSizeChanged(int index, String value) {
    final unit = _unitByCode(_unitCodeSelections[index]);
    if (!unit.requiresQuantityInput) {
      return;
    }

    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed <= 0) {
      return;
    }

    setState(() {
      _labelControllers[index].text = _autoLabel(unit, parsed);
    });
  }

  Future<void> _save() async {
    if (_isSaving) {
      return;
    }

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên sản phẩm')),
      );
      return;
    }

    final units = <CreateProductUnitRequest>[];
    for (int i = 0; i < _labelControllers.length; i++) {
      final unit = _unitByCode(_unitCodeSelections[i]);
      final price = double.tryParse(_priceControllers[i].text.trim());
      final stock = int.tryParse(_stockControllers[i].text.trim());

      if (price == null || price < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Giá không hợp lệ ở biến thể #${i + 1}')),
        );
        return;
      }
      if (stock == null || stock < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tồn kho không hợp lệ ở biến thể #${i + 1}')),
        );
        return;
      }

      String label;
      double? baseQuantity;
      String? baseUnit;

      if (unit.requiresQuantityInput) {
        final size = double.tryParse(_sizeControllers[i].text.trim());
        if (size == null || size <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Vui lòng nhập độ lớn ở biến thể #${i + 1}')),
          );
          return;
        }
        label = _autoLabel(unit, size);
        _labelControllers[i].text = label;
        baseQuantity = size;
        baseUnit = unit.baseUnit;
      } else {
        label = _labelControllers[i].text.trim();
        if (label.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Vui lòng nhập nhãn hiển thị ở biến thể #${i + 1}')),
          );
          return;
        }
        baseQuantity = null;
        baseUnit = null;
      }

      units.add(
        CreateProductUnitRequest(
          unitCode: unit.code,
          unitName: label,
          baseQuantity: baseQuantity,
          baseUnit: baseUnit,
          price: price,
          stockQuantity: stock,
        ),
      );
    }

    if (units.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cần ít nhất một biến thể hợp lệ')),
      );
      return;
    }

    final first = units.first;
    final request = CreateProductRequest(
      name: name,
      description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      categoryId: _selectedCategoryId,
      price: first.price,
      stock: first.stockQuantity,
      unit: first.unitCode,
      units: units,
    );

    setState(() => _isSaving = true);
    try {
      final createdProduct = await _productService.createProduct(request);

      if (_selectedImageBytes != null &&
          createdProduct.id != null &&
          createdProduct.id!.isNotEmpty) {
        await _productService.uploadProductImage(
          createdProduct.id!,
          _selectedImageBytes!,
          filename: 'product_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      }

      if (!mounted) {
        return;
      }
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) {
        return;
      }
      final message = e is ApiException ? (e.serverMessage ?? e.message) : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Thêm sản phẩm thất bại: $message')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    for (final c in _labelControllers) {
      c.dispose();
    }
    for (final c in _sizeControllers) {
      c.dispose();
    }
    for (final c in _priceControllers) {
      c.dispose();
    }
    for (final c in _stockControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Thêm sản phẩm mới'),
        backgroundColor: StoreTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: double.infinity,
                        height: 160,
                        color: Theme.of(context).colorScheme.surface,
                        child: _selectedImageBytes != null
                            ? Image.memory(_selectedImageBytes!, fit: BoxFit.cover)
                            : Icon(Icons.image, size: 56, color: Colors.grey[400]),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _isSaving ? null : _pickProductImage,
                      icon: const Icon(Icons.image_outlined),
                      label: Text(_isSaving ? 'Đang lưu...' : 'Chọn ảnh sản phẩm'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Tên sản phẩm *'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _selectedCategoryId,
                decoration: const InputDecoration(labelText: 'Danh mục'),
                items: widget.categories
                    .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name ?? 'Không tên')))
                    .toList(),
                onChanged: (value) => setState(() => _selectedCategoryId = value),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Mô tả'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Biến thể bán',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...List.generate(_labelControllers.length, (index) {
                final requiresInput = _requiresQuantityInput(index);
                final selectedCode = _unitCodeSelections[index];
                final unitSymbol = _unitByCode(selectedCode).symbol;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            'Biến thể #${index + 1}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          if (_labelControllers.length > 1)
                            IconButton(
                              onPressed: () => _removeVariantRow(index),
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                            ),
                        ],
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: _unitCodes.contains(selectedCode) ? selectedCode : null,
                        decoration: const InputDecoration(labelText: 'Đơn vị chuẩn'),
                        isExpanded: true,
                        items: _unitCodes
                            .map((code) => DropdownMenuItem(
                                  value: code,
                                  child: Text(_unitLabel(code)),
                                ))
                            .toList(),
                        onChanged: (value) => _onUnitChanged(index, value),
                      ),
                      const SizedBox(height: 8),
                      if (requiresInput) ...[
                        TextField(
                          controller: _sizeControllers[index],
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Nhập độ lớn ($unitSymbol)',
                          ),
                          onChanged: (value) => _onSizeChanged(index, value),
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Nhãn tự tạo: ${_labelControllers[index].text.isEmpty ? '-' : _labelControllers[index].text}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                          ),
                        ),
                      ] else
                        TextField(
                          controller: _labelControllers[index],
                          decoration: const InputDecoration(
                            labelText: 'Nhãn hiển thị (VD: Vỉ 10 quả, Thùng 24 lon)',
                          ),
                        ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _priceControllers[index],
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Giá (VNĐ) *'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _stockControllers[index],
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Tồn kho *'),
                      ),
                    ],
                  ),
                );
              }),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _addVariantRow,
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm biến thể'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: StoreTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(_isSaving ? 'Đang lưu...' : 'Lưu sản phẩm'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
