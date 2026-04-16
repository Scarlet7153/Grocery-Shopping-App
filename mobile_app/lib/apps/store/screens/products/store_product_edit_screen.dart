import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

import '../../../../core/api/api_error.dart';
import '../../../../core/theme/store_theme.dart';
import '../../../../features/products/data/product_model.dart';
import '../../../../features/products/data/product_service.dart';
import '../../../../features/products/data/unit_model.dart';
import '../../../../features/products/data/unit_service.dart';
import '../../utils/store_localizations.dart';

class StoreProductEditScreen extends StatefulWidget {
  final ProductModel product;
  final Future<bool> Function(ProductModel)? onSave;

  const StoreProductEditScreen({
    super.key,
    required this.product,
    this.onSave,
  });

  @override
  State<StoreProductEditScreen> createState() => _StoreProductEditScreenState();
}

class _StoreProductEditScreenState extends State<StoreProductEditScreen> {
  final UnitService _unitService = UnitService();
  final ProductService _productService = ProductService();
  final ImagePicker _imagePicker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _descController;

  final List<TextEditingController> _labelControllers = [];
  final List<TextEditingController> _sizeControllers = [];
  final List<TextEditingController> _priceControllers = [];
  final List<TextEditingController> _stockControllers = [];
  final List<String> _unitCodeSelections = [];

  List<Unit> _dbUnits = [];
  Uint8List? _selectedImageBytes;
  bool _isSaving = false;

  Future<void> _pickProductImage() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );
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
        SnackBar(content: Text(context.storeTr('image_pick_error'))),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name ?? '');
    _descController =
        TextEditingController(text: widget.product.description ?? '');
    _initRows();
    _loadUnits();
  }

  void _initRows() {
    final activeUnits =
        widget.product.units?.where((u) => u.isActive).toList() ?? [];
    if (activeUnits.isEmpty) {
      _labelControllers
          .add(TextEditingController(text: widget.product.unit ?? ''));
      _sizeControllers.add(TextEditingController());
      _priceControllers.add(
        TextEditingController(
            text: (widget.product.price ?? 0).toStringAsFixed(0)),
      );
      _stockControllers.add(
        TextEditingController(text: (widget.product.stock ?? 0).toString()),
      );
      _unitCodeSelections.add(_defaultUnitCode);
      return;
    }

    for (final unit in activeUnits) {
      _labelControllers.add(TextEditingController(text: unit.displayName));
      _sizeControllers.add(TextEditingController(
          text: _initialSizeValue(unit) ?? ''));
      _priceControllers
          .add(TextEditingController(text: unit.price.toStringAsFixed(0)));
      _stockControllers
          .add(TextEditingController(text: unit.stockQuantity.toString()));
      _unitCodeSelections.add(unit.unit.code);
    }
  }

  String? _initialSizeValue(ProductUnitMapping unit) {
    final stored = unit.baseQuantity;
    if (stored == null || stored <= 0) {
      return null;
    }

    if (!unit.unit.requiresQuantityInput) {
      return stored.toString();
    }

    final symbol = unit.unit.symbol.trim();
    final label = unit.displayName.trim();
    if (symbol.isNotEmpty && label.endsWith(symbol)) {
      final raw = label.substring(0, label.length - symbol.length).trim();
      final parsed = double.tryParse(raw);
      if (parsed != null && parsed > 0) {
        return parsed.toString();
      }
    }

    final rate = unit.unit.conversionRate;
    if (rate > 0) {
      final normalized = stored / rate;
      if (normalized > 0) {
        return normalized.toString();
      }
    }

    return stored.toString();
  }

  Future<void> _loadUnits() async {
    try {
      final units = await _unitService.getAllUnits();
      if (!mounted) {
        return;
      }
      setState(() {
        _dbUnits = units;
      });
    } catch (_) {
      // Keep fallback data if API fails.
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
    return match.isNotEmpty ? match.first : _fallbackUnit(code);
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
      _priceControllers.add(TextEditingController(text: '0'));
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
        SnackBar(content: Text(context.storeTr('product_name_required'))),
      );
      return;
    }

    final existing =
        widget.product.units?.where((u) => u.isActive).toList() ?? [];
    final updatedUnits = <ProductUnitMapping>[];

    for (int i = 0; i < _labelControllers.length; i++) {
      final unit = _unitByCode(_unitCodeSelections[i]);
      final price = double.tryParse(_priceControllers[i].text.trim());
      final stock = int.tryParse(_stockControllers[i].text.trim());

      if (price == null || price < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('${context.storeTr('invalid_price_variant')}${i + 1}')),
        );
        return;
      }
      if (stock == null || stock < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('${context.storeTr('invalid_stock_variant')}${i + 1}')),
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
            SnackBar(
                content: Text(
                    '${context.storeTr('size_required_variant')}${i + 1}')),
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
            SnackBar(
                content: Text(
                    '${context.storeTr('label_required_variant')}${i + 1}')),
          );
          return;
        }
        baseQuantity = null;
        baseUnit = null;
      }

      final existingUnit = i < existing.length ? existing[i] : null;
      updatedUnits.add(
        ProductUnitMapping(
          id: existingUnit?.id ?? 0,
          productId: existingUnit?.productId ??
              int.tryParse(widget.product.id ?? '0') ??
              0,
          unit: unit,
          unitLabel: label,
          price: price,
          stockQuantity: stock,
          baseQuantity: baseQuantity,
          baseUnit: baseUnit,
          isDefault: i == 0,
          isActive: true,
        ),
      );
    }

    if (updatedUnits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.storeTr('at_least_one_variant'))),
      );
      return;
    }

    setState(() => _isSaving = true);

    final primary = updatedUnits.first;
    String? imageUrl = widget.product.imageUrl;

    if (_selectedImageBytes != null &&
        widget.product.id != null &&
        widget.product.id!.isNotEmpty) {
      imageUrl = await _productService.uploadProductImage(
        widget.product.id!,
        _selectedImageBytes!,
        filename: 'product_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
    }

    final updatedProduct = ProductModel(
      id: widget.product.id,
      name: name,
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
      price: primary.price,
      stock: primary.stockQuantity,
      unit: primary.displayName,
      category: widget.product.category,
      imageUrl: imageUrl,
      storeId: widget.product.storeId,
      storeName: widget.product.storeName,
      isActive: widget.product.isActive,
      status: widget.product.status,
      units: updatedUnits,
    );

    try {
      final saved =
          await (widget.onSave?.call(updatedProduct) ?? Future.value(true));
      if (!saved) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.storeTr('save_failed'))),
        );
        return;
      }
      if (!mounted) {
        return;
      }
      Navigator.pop(context, updatedProduct);
    } catch (e) {
      if (!mounted) {
        return;
      }
      final message =
          e is ApiException ? (e.serverMessage ?? e.message) : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('${context.storeTr('update_failed')}: $message')),
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
        title: Text(context.storeTr('edit_product')),
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
                            : (widget.product.imageUrl != null &&
                                    widget.product.imageUrl!.isNotEmpty)
                                ? Image.network(
                                    widget.product.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        Icon(Icons.image,
                                            size: 56,
                                            color: Colors.grey[400]),
                                  )
                                : Icon(Icons.image,
                                    size: 56, color: Colors.grey[400]),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _isSaving ? null : _pickProductImage,
                      icon: const Icon(Icons.image_outlined),
                      label: Text(_isSaving
                          ? context.storeTr('saving')
                          : context.storeTr('change_image')),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                    labelText: context.storeTr('product_name_required_field')),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descController,
                maxLines: 3,
                decoration: InputDecoration(
                    labelText: context.storeTr('description_label')),
              ),
              const SizedBox(height: 16),
              Text(
                context.storeTr('sale_variants'),
                style: const TextStyle(fontWeight: FontWeight.bold),
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
                            '${context.storeTr('variant')} #${index + 1}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          if (_labelControllers.length > 1)
                            IconButton(
                              onPressed: () => _removeVariantRow(index),
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                            ),
                        ],
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: _unitCodes.contains(selectedCode)
                            ? selectedCode
                            : null,
                        decoration: InputDecoration(
                            labelText: context.storeTr('standard_unit_label')),
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
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            labelText:
                                '${context.storeTr('enter_size_symbol')} ($unitSymbol)',
                          ),
                          onChanged: (value) => _onSizeChanged(index, value),
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${context.storeTr('auto_label_prefix')} ${_labelControllers[index].text.isEmpty ? '-' : _labelControllers[index].text}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[700]),
                          ),
                        ),
                      ] else
                        TextField(
                          controller: _labelControllers[index],
                          decoration: InputDecoration(
                            labelText: context.storeTr('unit_label'),
                          ),
                        ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _priceControllers[index],
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                            labelText: context.storeTr('price_vnd')),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _stockControllers[index],
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                            labelText: context.storeTr('stock_required')),
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
                  label: Text(context.storeTr('add_variant')),
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
                  child: Text(_isSaving
                      ? context.storeTr('saving')
                      : context.storeTr('save_changes')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
