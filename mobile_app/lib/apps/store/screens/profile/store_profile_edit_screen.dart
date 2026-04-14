import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

import '../../../../core/location/province_api.dart';
import '../../../../core/theme/store_theme.dart';
import '../../../../features/store/data/store_model.dart';
import '../../../../features/store/data/store_service.dart';
import '../../utils/store_localizations.dart';

class StoreProfileEditResult {
  final String storeName;
  final String address;
  final String? imageUrl;

  const StoreProfileEditResult({
    required this.storeName,
    required this.address,
    this.imageUrl,
  });
}

class StoreProfileEditScreen extends StatefulWidget {
  final StoreModel store;

  const StoreProfileEditScreen({
    super.key,
    required this.store,
  });

  @override
  State<StoreProfileEditScreen> createState() => _StoreProfileEditScreenState();
}

class _StoreProfileEditScreenState extends State<StoreProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProvinceApi _provinceApi = ProvinceApi();
  final StoreService _storeService = StoreService();
  final ImagePicker _imagePicker = ImagePicker();
  late final TextEditingController _nameController;
  late final TextEditingController _streetController;

  List<LocationItem> _provinces = const [];
  List<LocationItem> _wards = const [];
  LocationItem? _selectedProvince;
  LocationItem? _selectedWard;

  bool _isLoadingProvince = true;
  bool _isLoadingWard = false;
  String? _locationError;

  String? _initialProvinceName;
  String? _initialWardName;
  Uint8List? _selectedImageBytes;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.store.storeName ?? '');
    _streetController = TextEditingController();
    _prefillAddressParts(widget.store.address);
    _loadProvinces();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  void _prefillAddressParts(String? fullAddress) {
    final raw = fullAddress?.trim() ?? '';
    if (raw.isEmpty) return;

    final parts =
        raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    if (parts.isEmpty) return;
    if (parts.length == 1) {
      _streetController.text = parts.first;
      return;
    }

    _initialProvinceName = parts.last;
    _initialWardName = parts.length >= 2 ? parts[parts.length - 2] : null;
    final streetParts =
        parts.length > 2 ? parts.sublist(0, parts.length - 2) : <String>[];
    _streetController.text =
        streetParts.isNotEmpty ? streetParts.join(', ') : '';
  }

  Future<void> _loadProvinces() async {
    try {
      final provinces = await _provinceApi.getProvincesV2();
      provinces.sort((a, b) => a.name.compareTo(b.name));

      if (!mounted) return;

      LocationItem? selectedProvince;
      if (_initialProvinceName != null) {
        selectedProvince = _findByName(provinces, _initialProvinceName!);
      }

      setState(() {
        _provinces = provinces;
        _selectedProvince = selectedProvince;
        _isLoadingProvince = false;
        _locationError = null;
      });

      if (selectedProvince != null) {
        await _loadWards(selectedProvince.code,
            preselectWardName: _initialWardName);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingProvince = false;
        _locationError = 'load_province_error';
      });
    }
  }

  Future<void> _loadWards(int provinceCode, {String? preselectWardName}) async {
    setState(() {
      _isLoadingWard = true;
      _wards = const [];
      _selectedWard = null;
    });

    try {
      final wards = await _provinceApi.getWardsByProvince(provinceCode);
      if (!mounted) return;

      setState(() {
        _wards = wards;
        _selectedWard = preselectWardName == null
            ? null
            : _findByName(wards, preselectWardName);
        _isLoadingWard = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingWard = false;
        _locationError = 'load_ward_error';
      });
    }
  }

  LocationItem? _findByName(List<LocationItem> items, String rawName) {
    final target = _normalizeName(rawName);
    for (final item in items) {
      if (_normalizeName(item.name) == target) return item;
    }
    for (final item in items) {
      final current = _normalizeName(item.name);
      if (current.contains(target) || target.contains(current)) return item;
    }
    return null;
  }

  String _normalizeName(String value) {
    var text = value.toLowerCase().trim();
    text = text
        .replaceAll('thanh pho', '')
        .replaceAll('tp.', '')
        .replaceAll('tp', '')
        .replaceAll('tinh', '')
        .replaceAll('phuong', '')
        .replaceAll('xa', '')
        .replaceAll('thi tran', '')
        .replaceAll('.', '')
        .replaceAll(',', '');
    return text.trim();
  }

  Future<void> _pickStoreImage() async {
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
      if (!mounted) return;
      setState(() {
        _selectedImageBytes = bytes;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.storeTr('image_pick_error'))),
      );
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedProvince == null || _selectedWard == null) return;
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    final street = _streetController.text.trim();
    final address =
        '$street, ${_selectedWard!.name}, ${_selectedProvince!.name}';

    String? uploadedImageUrl;
    if (_selectedImageBytes != null && widget.store.id != null) {
      uploadedImageUrl = await _storeService.uploadStoreImage(
        widget.store.id!,
        _selectedImageBytes!,
        filename: 'store_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      if (_selectedImageBytes != null && uploadedImageUrl == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.storeTr('image_pick_error'))),
        );
        setState(() {
          _isSubmitting = false;
        });
        return;
      }
    }

    if (!mounted) return;

    Navigator.pop(
      context,
      StoreProfileEditResult(
        storeName: _nameController.text.trim(),
        address: address,
        imageUrl: uploadedImageUrl,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(context.storeTr('edit_store')),
        backgroundColor: StoreTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.storeTr('store_information'),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
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
                                  : (widget.store.imageUrl != null &&
                                          widget.store.imageUrl!.isNotEmpty)
                                      ? Image.network(
                                          widget.store.imageUrl!,
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
                            onPressed: _isSubmitting ? null : _pickStoreImage,
                            icon: const Icon(Icons.image_outlined),
                            label: Text(_isSubmitting
                                ? context.storeTr('saving')
                                : context.storeTr('change_image')),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: context.storeTr('store_name'),
                        hintText: context.storeTr('store_name_hint'),
                        prefixIcon: const Icon(Icons.store),
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty)
                          return context.storeTr('store_name_required');
                        if (text.length < 2)
                          return context.storeTr('store_name_too_short');
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<LocationItem>(
                      initialValue: _selectedProvince,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: context.storeTr('province_city'),
                        prefixIcon: const Icon(Icons.map_outlined),
                      ),
                      items: _provinces
                          .map(
                            (item) => DropdownMenuItem<LocationItem>(
                              value: item,
                              child: Text(item.name,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          )
                          .toList(),
                      onChanged: _isLoadingProvince
                          ? null
                          : (value) {
                              if (value == null) return;
                              setState(() {
                                _selectedProvince = value;
                                _selectedWard = null;
                                _wards = const [];
                              });
                              _loadWards(value.code);
                            },
                      validator: (value) {
                        if (value == null) {
                          return context.storeTr('province_required');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<LocationItem>(
                      initialValue: _selectedWard,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: context.storeTr('ward_district'),
                        prefixIcon: const Icon(Icons.location_city_outlined),
                      ),
                      items: _wards
                          .map(
                            (item) => DropdownMenuItem<LocationItem>(
                              value: item,
                              child: Text(item.name,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          )
                          .toList(),
                      onChanged: (_selectedProvince == null || _isLoadingWard)
                          ? null
                          : (value) {
                              setState(() {
                                _selectedWard = value;
                              });
                            },
                      validator: (value) {
                        if (value == null) {
                          return context.storeTr('ward_required');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _streetController,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: context.storeTr('street'),
                        hintText: context.storeTr('street_hint'),
                        prefixIcon: const Icon(Icons.route),
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty)
                          return context.storeTr('street_required');
                        if (text.length < 3)
                          return context.storeTr('street_too_short');
                        return null;
                      },
                    ),
                    if (_isLoadingProvince || _isLoadingWard) ...[
                      const SizedBox(height: 10),
                      const LinearProgressIndicator(),
                    ],
                    if (_locationError != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        context.storeTr(_locationError!),
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 14),
                    TextFormField(
                      initialValue: widget.store.ownerPhone ??
                          widget.store.phoneNumber ??
                          'Chưa cập nhật',
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: context.storeTr('phone_number'),
                        prefixIcon: const Icon(Icons.phone_outlined),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(context.storeTr('cancel')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () {
                        _submit();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: StoreTheme.primaryColor,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(context.storeTr('save_changes')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
