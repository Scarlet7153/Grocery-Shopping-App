import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../../../core/theme/store_theme.dart';
import '../../../../core/utils/image_picker_helper.dart';
import '../../../../features/products/data/product_model.dart';
import '../../../../features/products/data/unit_model.dart';
import '../../../../features/products/data/unit_service.dart';
import 'store_product_edit_screen.dart';
import '../../utils/store_localizations.dart';

class StoreProductDetailScreen extends StatefulWidget {
  final ProductModel product;
  final Future<bool> Function(ProductModel)? onEdit;
  final Function(String)? onDelete;

  const StoreProductDetailScreen({
    super.key,
    required this.product,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<StoreProductDetailScreen> createState() =>
      _StoreProductDetailScreenState();
}

class _StoreProductDetailScreenState extends State<StoreProductDetailScreen> {
  final UnitService _unitService = UnitService();
  List<Unit> _dbUnits = [];
  late ProductModel _currentProduct;
  Uint8List? _pendingImageBytes;
  bool _isEditing = false;
  final bool _isSaving = false;
  late TextEditingController _nameController;
  late TextEditingController _descController;
  final List<TextEditingController> _unitNameControllers = [];
  final List<TextEditingController> _unitSizeControllers = [];
  final List<TextEditingController> _unitPriceControllers = [];
  final List<TextEditingController> _unitStockControllers = [];
  final List<String> _unitCodeSelections = [];

  @override
  void initState() {
    super.initState();
    _currentProduct = widget.product;
    _loadUnitsFromDb();
    _initControllers();
  }

  Future<void> _loadUnitsFromDb() async {
    try {
      final units = await _unitService.getAllUnits();
      if (!mounted) {
        return;
      }
      setState(() {
        _dbUnits = units;
      });
    } catch (_) {
      // Keep previous units and fallback options if unit API is temporarily unavailable.
    }
  }

  List<String> get _unitCodes {
    if (_dbUnits.isEmpty) {
      return const ['kg'];
    }
    return _dbUnits.map((u) => u.code).toList();
  }

  String _unitLabelByCode(String code) {
    final matches = _dbUnits.where((u) => u.code == code);
    if (matches.isEmpty) {
      return code;
    }
    final unit = matches.first;
    return unit.symbol.isNotEmpty ? '${unit.name} (${unit.symbol})' : unit.name;
  }

  Map<String, String> get _unitCodeLabelMap => {
        for (final code in _unitCodes) code: _unitLabelByCode(code),
      };

  Unit? _unitByCode(String code) {
    final matches = _dbUnits.where((u) => u.code == code);
    return matches.isNotEmpty ? matches.first : null;
  }

  bool _requiresQuantityInput(String code) {
    return _unitByCode(code)?.requiresQuantityInput ?? false;
  }

  String _autoUnitLabel(String code, double quantity) {
    final symbol = _unitByCode(code)?.symbol ?? code;
    final normalized = quantity == quantity.roundToDouble()
        ? quantity.toInt().toString()
        : quantity.toString();
    return '$normalized$symbol';
  }

  void _initControllers() {
    _disposeUnitControllers();
    _nameController = TextEditingController(text: _currentProduct.name);
    _descController =
        TextEditingController(text: _currentProduct.description ?? '');

    final units =
        (_currentProduct.units != null && _currentProduct.units!.isNotEmpty)
            ? _currentProduct.units!.where((u) => u.isActive).toList()
            : <ProductUnitMapping>[];

    if (units.isEmpty) {
      _unitNameControllers.add(
        TextEditingController(
            text: _currentProduct.unit ?? _unitLabelByCode(_unitCodes.first)),
      );
      _unitSizeControllers.add(TextEditingController());
      _unitPriceControllers.add(TextEditingController(
          text: (_currentProduct.price ?? 0).toStringAsFixed(0)));
      _unitStockControllers.add(
          TextEditingController(text: (_currentProduct.stock ?? 0).toString()));
      _unitCodeSelections.add(_unitCodes.first);
      return;
    }

    for (final unit in units) {
      _unitNameControllers.add(TextEditingController(text: unit.displayName));
      _unitSizeControllers.add(
          TextEditingController(text: unit.baseQuantity?.toString() ?? ''));
      _unitPriceControllers
          .add(TextEditingController(text: unit.price.toStringAsFixed(0)));
      _unitStockControllers
          .add(TextEditingController(text: unit.stockQuantity.toString()));
      _unitCodeSelections.add(unit.unit.code);
    }
  }

  void _disposeUnitControllers() {
    for (final c in _unitNameControllers) {
      c.dispose();
    }
    for (final c in _unitSizeControllers) {
      c.dispose();
    }
    for (final c in _unitPriceControllers) {
      c.dispose();
    }
    for (final c in _unitStockControllers) {
      c.dispose();
    }
    _unitNameControllers.clear();
    _unitSizeControllers.clear();
    _unitPriceControllers.clear();
    _unitStockControllers.clear();
    _unitCodeSelections.clear();
  }

  void _addUnitRow() {
    setState(() {
      _unitNameControllers.add(TextEditingController());
      _unitSizeControllers.add(TextEditingController());
      _unitPriceControllers.add(TextEditingController(text: '0'));
      _unitStockControllers.add(TextEditingController(text: '0'));
      _unitCodeSelections.add(_unitCodes.first);
    });
  }

  void _removeUnitRow(int index) {
    if (_unitNameControllers.length <= 1) {
      return;
    }
    setState(() {
      _unitNameControllers[index].dispose();
      _unitSizeControllers[index].dispose();
      _unitPriceControllers[index].dispose();
      _unitStockControllers[index].dispose();
      _unitNameControllers.removeAt(index);
      _unitSizeControllers.removeAt(index);
      _unitPriceControllers.removeAt(index);
      _unitStockControllers.removeAt(index);
      _unitCodeSelections.removeAt(index);
    });
  }

  void _onUnitCodeChanged(int index, String? code) {
    if (code == null || code.isEmpty) {
      return;
    }
    setState(() {
      _unitCodeSelections[index] = code;
      if (_requiresQuantityInput(code)) {
        final quantity =
            double.tryParse(_unitSizeControllers[index].text.trim());
        if (quantity != null && quantity > 0) {
          _unitNameControllers[index].text = _autoUnitLabel(code, quantity);
        }
      } else if (_unitNameControllers[index].text.trim().isEmpty) {
        _unitNameControllers[index].text = _unitLabelByCode(code);
      }
    });
  }

  void _onUnitSizeChanged(int index, String value) {
    final code = _unitCodeSelections[index];
    if (!_requiresQuantityInput(code)) {
      return;
    }
    final quantity = double.tryParse(value.trim());
    if (quantity == null || quantity <= 0) {
      return;
    }
    _unitNameControllers[index].text = _autoUnitLabel(code, quantity);
    setState(() {});
  }

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
        _pendingImageBytes = bytes;
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
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _disposeUnitControllers();
    super.dispose();
  }

  Future<void> _toggleEdit() async {
    final updated = await Navigator.push<ProductModel>(
      context,
      MaterialPageRoute(
        builder: (_) => StoreProductEditScreen(
          product: _currentProduct,
          onSave: widget.onEdit,
        ),
      ),
    );

    if (updated != null && mounted) {
      setState(() {
        _currentProduct = updated;
        _pendingImageBytes = null;
      });
    }
  }

  void _showDeleteConfirm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.storeTr('delete_product')),
        content: Text(
            '${context.storeTr('delete_product_confirm')} "${_currentProduct.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.storeTr('cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              widget.onDelete?.call(_currentProduct.id.toString());
              Navigator.pop(context);
            },
            child: Text(context.storeTr('delete')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(
            _isEditing ? context.storeTr('edit_product') : context.storeTr('product_detail')),
        backgroundColor: StoreTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _toggleEdit,
            ),
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _showDeleteConfirm,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProductImage(
              product: _currentProduct,
              pendingImageBytes: _pendingImageBytes,
              isEditing: _isEditing,
              isSaving: _isSaving,
              onPickImage: _pickProductImage,
            ),
            const SizedBox(height: 16),
            _isEditing
                ? _EditForm(
                    nameController: _nameController,
                    descController: _descController,
                    unitNameControllers: _unitNameControllers,
                    unitSizeControllers: _unitSizeControllers,
                    unitPriceControllers: _unitPriceControllers,
                    unitStockControllers: _unitStockControllers,
                    unitCodeSelections: _unitCodeSelections,
                    unitCodeLabelMap: _unitCodeLabelMap,
                    requiresQuantityInputByCode: {
                      for (final code in _unitCodes)
                        code: _requiresQuantityInput(code),
                    },
                    unitSymbolByCode: {
                      for (final unit in _dbUnits) unit.code: unit.symbol,
                    },
                    onUnitCodeChanged: _onUnitCodeChanged,
                    onUnitSizeChanged: _onUnitSizeChanged,
                    onAddUnit: _addUnitRow,
                    onRemoveUnit: _removeUnitRow,
                  )
                : _ProductInfo(product: _currentProduct),
            const SizedBox(height: 24),
            if (_isEditing)
              _SaveButtons(
                onSave: _isSaving ? null : _toggleEdit,
                isSaving: _isSaving,
                onCancel: () {
                  _initControllers();
                  setState(() {
                    _pendingImageBytes = null;
                    _isEditing = false;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final ProductModel product;
  final Uint8List? pendingImageBytes;
  final bool isEditing;
  final bool isSaving;
  final VoidCallback onPickImage;

  const _ProductImage({
    required this.product,
    required this.pendingImageBytes,
    required this.isEditing,
    required this.isSaving,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.imageUrl;
    final resolvedImageUrl = imageUrl ?? '';
    final hasValidImage = imageUrl != null &&
        imageUrl.isNotEmpty &&
        !imageUrl.contains('example.com');

    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 250,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: pendingImageBytes != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    pendingImageBytes!,
                    fit: BoxFit.cover,
                  ),
                )
              : hasValidImage
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        resolvedImageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                              child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null));
                        },
                        errorBuilder: (_, __, ___) => _placeholder(context),
                      ),
                    )
                  : _placeholder(context),
        ),
        if (isEditing)
          Positioned(
            right: 12,
            bottom: 12,
            child: ElevatedButton.icon(
              onPressed: isSaving ? null : onPickImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
              ),
              icon: isSaving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.photo_library, size: 18),
              label: Text(
                  isSaving ? context.storeTr('saving') : context.storeTr('change_image')),
            ),
          ),
      ],
    );
  }

  Widget _placeholder(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(context.storeTr('no_image'),
              style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }
}

class _ProductInfo extends StatelessWidget {
  final ProductModel product;
  const _ProductInfo({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(product.name ?? context.storeTr('product'),
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('${product.price?.toStringAsFixed(0) ?? 0}đ',
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: StoreTheme.primaryColor)),
              if (product.unit != null) ...[
                const Text(' / ',
                    style: TextStyle(fontSize: 16, color: Colors.grey)),
                Text(product.unit!,
                    style: const TextStyle(fontSize: 16, color: Colors.grey)),
              ],
            ],
          ),
          const SizedBox(height: 16),
          if (product.category != null)
            _InfoRow(
                label: tr(context, vi: 'Danh mục', en: 'Category'),
                value: product.category!),
          _InfoRow(
              label: tr(context, vi: 'Trạng thái', en: 'Status'),
              value: _getStatusLabel(context, product.status)),
          // Hiển thị danh sách đơn vị nếu có
          if (product.units != null && product.units!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(context.storeTr('product_units'),
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _ProductUnitsList(units: product.units!),
          ],

          if (product.description != null &&
              product.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(context.storeTr('description'),
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(product.description!,
                style: TextStyle(color: Colors.grey[700])),
          ],
        ],
      ),
    );
  }

  String _getStatusLabel(BuildContext context, String? status) {
    switch (status) {
      case 'AVAILABLE':
        return context.storeTr('available');
      case 'OUT_OF_STOCK':
        return context.storeTr('out_of_stock');
      case 'HIDDEN':
        return context.storeTr('hidden');
      default:
        return context.storeTr('available');
    }
  }
}

class _ProductUnitsList extends StatelessWidget {
  final List<ProductUnitMapping> units;
  const _ProductUnitsList({required this.units});

  double? _effectiveBaseQuantity(ProductUnitMapping unit) {
    final stored = unit.baseQuantity;
    if (stored == null) {
      return null;
    }

    final requiresInput = unit.unit.requiresQuantityInput;
    final conversionRate = unit.unit.conversionRate;
    final symbol = unit.unit.symbol;
    final label = unit.displayName.trim();

    if (!requiresInput ||
        conversionRate <= 1 ||
        symbol.isEmpty ||
        !label.endsWith(symbol)) {
      return stored;
    }

    final raw = label.substring(0, label.length - symbol.length).trim();
    final quantityMatch = RegExp(r'([0-9]+(?:\.[0-9]+)?)$').firstMatch(raw);
    final parsedInput = quantityMatch != null
        ? double.tryParse(quantityMatch.group(1)!)
        : double.tryParse(raw);
    if (parsedInput == null || parsedInput <= 0) {
      return stored;
    }

    final expectedBase = parsedInput * conversionRate;
    final isLegacyInputStored = (stored - parsedInput).abs() < 0.0001;
    final alreadyCorrect = (stored - expectedBase).abs() < 0.0001;
    if (isLegacyInputStored && !alreadyCorrect) {
      return expectedBase;
    }
    return stored;
  }

  String _formatBaseQuantity(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value
        .toStringAsFixed(4)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: units.where((u) => u.isActive).map((unit) {
        final isDefault = unit.isDefault;
        final effectiveBaseQuantity = _effectiveBaseQuantity(unit);
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDefault
                ? StoreTheme.primaryColor.withValues(alpha: 0.1)
                : Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDefault ? StoreTheme.primaryColor : Colors.grey[300]!,
              width: isDefault ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          unit.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: StoreTheme.primaryColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              context.storeTr('default'),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${unit.price.toStringAsFixed(0)}đ / ${unit.unit.symbol}',
                      style: TextStyle(
                        color: StoreTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (effectiveBaseQuantity != null &&
                        unit.baseUnit != null &&
                        unit.baseUnit!.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        '≈ ${_formatBaseQuantity(effectiveBaseQuantity)} ${unit.baseUnit}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${context.storeTr('stock_count')}: ${unit.stockQuantity}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    unit.stockQuantity > 0 ? Icons.check_circle : Icons.cancel,
                    color: unit.stockQuantity > 0 ? Colors.green : Colors.red,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _EditForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController descController;
  final List<TextEditingController> unitNameControllers;
  final List<TextEditingController> unitSizeControllers;
  final List<TextEditingController> unitPriceControllers;
  final List<TextEditingController> unitStockControllers;
  final List<String> unitCodeSelections;
  final Map<String, String> unitCodeLabelMap;
  final Map<String, bool> requiresQuantityInputByCode;
  final Map<String, String> unitSymbolByCode;
  final void Function(int index, String? code) onUnitCodeChanged;
  final void Function(int index, String value) onUnitSizeChanged;
  final VoidCallback onAddUnit;
  final Function(int) onRemoveUnit;

  const _EditForm({
    required this.nameController,
    required this.descController,
    required this.unitNameControllers,
    required this.unitSizeControllers,
    required this.unitPriceControllers,
    required this.unitStockControllers,
    required this.unitCodeSelections,
    required this.unitCodeLabelMap,
    required this.requiresQuantityInputByCode,
    required this.unitSymbolByCode,
    required this.onUnitCodeChanged,
    required this.onUnitSizeChanged,
    required this.onAddUnit,
    required this.onRemoveUnit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
              controller: nameController,
              decoration:
                  InputDecoration(labelText: context.storeTr('product_name'))),
          const SizedBox(height: 12),
          Text(
            context.storeTr('product_units'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...List.generate(unitNameControllers.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _UnitEditRow(
                index: index,
                unitCodes: unitCodeLabelMap.keys.toList(),
                selectedUnitCode: unitCodeSelections[index],
                unitCodeLabelMap: unitCodeLabelMap,
                requiresQuantityInputByCode: requiresQuantityInputByCode,
                unitSymbolByCode: unitSymbolByCode,
                onUnitCodeChanged: (code) => onUnitCodeChanged(index, code),
                onUnitSizeChanged: (value) => onUnitSizeChanged(index, value),
                nameController: unitNameControllers[index],
                sizeController: unitSizeControllers[index],
                priceController: unitPriceControllers[index],
                stockController: unitStockControllers[index],
                canRemove: unitNameControllers.length > 1,
                onRemove: () => onRemoveUnit(index),
              ),
            );
          }),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onAddUnit,
              icon: const Icon(Icons.add),
              label: Text(context.storeTr('add_unit')),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
              controller: descController,
              maxLines: 3,
              decoration:
                  InputDecoration(labelText: context.storeTr('description'))),
        ],
      ),
    );
  }
}

class _UnitEditRow extends StatelessWidget {
  final int index;
  final List<String> unitCodes;
  final String selectedUnitCode;
  final Map<String, String> unitCodeLabelMap;
  final Map<String, bool> requiresQuantityInputByCode;
  final Map<String, String> unitSymbolByCode;
  final void Function(String?) onUnitCodeChanged;
  final void Function(String) onUnitSizeChanged;
  final TextEditingController nameController;
  final TextEditingController sizeController;
  final TextEditingController priceController;
  final TextEditingController stockController;
  final bool canRemove;
  final VoidCallback onRemove;

  const _UnitEditRow({
    required this.index,
    required this.unitCodes,
    required this.selectedUnitCode,
    required this.unitCodeLabelMap,
    required this.requiresQuantityInputByCode,
    required this.unitSymbolByCode,
    required this.onUnitCodeChanged,
    required this.onUnitSizeChanged,
    required this.nameController,
    required this.sizeController,
    required this.priceController,
    required this.stockController,
    required this.canRemove,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final requiresInput =
        requiresQuantityInputByCode[selectedUnitCode] ?? false;
    final symbol = unitSymbolByCode[selectedUnitCode] ?? selectedUnitCode;

    return Container(
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
                '${context.storeTr('unit')} #${index + 1}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (canRemove)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: onRemove,
                ),
            ],
          ),
          TextField(
            controller: requiresInput ? sizeController : nameController,
            keyboardType: requiresInput
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            onChanged: requiresInput ? onUnitSizeChanged : null,
            decoration: InputDecoration(
              labelText: requiresInput
                  ? '${context.storeTr('unit_size')} ($symbol)'
                  : context.storeTr('unit_label'),
            ),
          ),
          if (requiresInput) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${context.storeTr('unit_label')}: ${nameController.text.isEmpty ? '-' : nameController.text}',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ),
          ],
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue:
                unitCodes.contains(selectedUnitCode) ? selectedUnitCode : null,
            isExpanded: true,
            menuMaxHeight: 280,
            dropdownColor: Theme.of(context).colorScheme.surface,
            decoration:
                InputDecoration(labelText: context.storeTr('standard_unit')),
            items: unitCodes
                .map((code) => DropdownMenuItem(
                    value: code, child: Text(unitCodeLabelMap[code] ?? code)))
                .toList(),
            onChanged: onUnitCodeChanged,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: priceController,
            keyboardType: TextInputType.number,
            decoration:
                InputDecoration(labelText: context.storeTr('price_vnd')),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: stockController,
            keyboardType: TextInputType.number,
            decoration:
                InputDecoration(labelText: context.storeTr('quantity_stock')),
          ),
        ],
      ),
    );
  }
}

class _SaveButtons extends StatelessWidget {
  final Future<void> Function()? onSave;
  final VoidCallback onCancel;
  final bool isSaving;

  const _SaveButtons(
      {required this.onSave, required this.onCancel, required this.isSaving});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: isSaving ? null : onCancel,
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
            child: Text(context.storeTr('cancel')),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: onSave,
            style: ElevatedButton.styleFrom(
                backgroundColor: StoreTheme.primaryColor,
                padding: const EdgeInsets.all(16)),
            child: Text(
                isSaving ? context.storeTr('saving') : context.storeTr('save')),
          ),
        ),
      ],
    );
  }
}
