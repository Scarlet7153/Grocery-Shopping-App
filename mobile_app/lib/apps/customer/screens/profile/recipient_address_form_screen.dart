import 'package:flutter/material.dart';

import '../../../../core/auth/auth_session.dart';
import '../../../../core/location/province_api.dart';
import '../../services/province_api_v2.dart';

class RecipientAddressResult {
  final String address;
  final int? index;
  final bool isDefault;
  final bool hasOtherReceiver;
  final String? otherReceiverName;
  final String? otherReceiverPhone;
  final String? otherReceiverTitle;

  const RecipientAddressResult({
    required this.address,
    this.index,
    required this.isDefault,
    this.hasOtherReceiver = false,
    this.otherReceiverName,
    this.otherReceiverPhone,
    this.otherReceiverTitle,
  });
}

class RecipientAddressFormScreen extends StatefulWidget {
  final String? initialAddress;
  final int? editIndex;
  final bool isDefault;
  final bool hasOtherReceiver;
  final String? otherReceiverName;
  final String? otherReceiverPhone;
  final String? otherReceiverTitle;

  const RecipientAddressFormScreen({
    super.key,
    this.initialAddress,
    this.editIndex,
    this.isDefault = false,
    this.hasOtherReceiver = false,
    this.otherReceiverName,
    this.otherReceiverPhone,
    this.otherReceiverTitle,
  });

  @override
  State<RecipientAddressFormScreen> createState() =>
      _RecipientAddressFormScreenState();
}

class _RecipientAddressFormScreenState
    extends State<RecipientAddressFormScreen> {
  final _houseController = TextEditingController();
  final _provinceApi = ProvinceApiV2();
  List<LocationItem> _provinces = [];
  List<LocationItem> _districts = [];
  List<LocationItem> _wards = [];
  LocationItem? _selectedProvince;
  LocationItem? _selectedDistrict;
  LocationItem? _selectedWard;
  bool _loading = false;
  bool _otherReceiver = false;
  String? _initialProvinceName;
  String? _initialDistrictName;
  String? _initialWardName;
  String? _otherReceiverName;
  String? _otherReceiverPhone;
  String? _otherReceiverTitle;

  @override
  void initState() {
    super.initState();
    _otherReceiver = widget.hasOtherReceiver;
    _otherReceiverName = widget.otherReceiverName;
    _otherReceiverPhone = widget.otherReceiverPhone;
    _otherReceiverTitle = widget.otherReceiverTitle;
    _prefillFromAddress(widget.initialAddress);
    _loadProvinces();
  }

  void _prefillFromAddress(String? address) {
    if (address == null || address.trim().isEmpty) return;
    final parts = address.split(',').map((e) => e.trim()).toList();
    if (parts.length < 3) {
      _houseController.text = address;
      return;
    }
    _initialProvinceName = parts.last;
    _initialDistrictName = parts[parts.length - 2];
    if (parts.length >= 4) {
      _initialWardName = parts[parts.length - 3];
      _houseController.text = parts.take(parts.length - 3).join(', ');
    } else {
      _initialWardName = null;
      _houseController.text = parts.take(parts.length - 2).join(', ');
    }
  }

  String _normalizeLocationName(String value) {
    var s = value.trim().toLowerCase();
    s = s.replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a');
    s = s.replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e');
    s = s.replaceAll(RegExp(r'[ìíịỉĩ]'), 'i');
    s = s.replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o');
    s = s.replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u');
    s = s.replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y');
    s = s.replaceAll(RegExp(r'[đ]'), 'd');
    s = s.replaceAll(RegExp(r'[^a-z0-9]'), '');
    return s;
  }

  LocationItem? _findByName(List<LocationItem> items, String? name) {
    if (name == null || name.trim().isEmpty) return null;
    final target = _normalizeLocationName(name);
    if (target.isEmpty) return null;
    for (final item in items) {
      final normalized = _normalizeLocationName(item.name);
      if (normalized == target || normalized.contains(target)) {
        return item;
      }
    }
    return null;
  }

  Future<void> _loadProvinces() async {
    setState(() => _loading = true);
    try {
      _provinces = await _provinceApi.getProvinces();
      if (_initialProvinceName != null) {
        final matched =
            _findByName(_provinces, _initialProvinceName) ?? _provinces.first;
        _selectedProvince = matched;
        final districts = await _provinceApi.getDistricts(matched.code);
        _districts = districts;
        if (_districts.isEmpty) {
          _wards = await _provinceApi.getWardsByProvince(matched.code);
          _selectedWard = _findByName(_wards, _initialWardName ?? _initialDistrictName) ??
              (_wards.isNotEmpty ? _wards.first : null);
        } else if (_initialDistrictName != null) {
          final districtMatched =
              _findByName(_districts, _initialDistrictName) ?? _districts.first;
          _selectedDistrict = districtMatched;
          _wards = await _provinceApi.getWards(districtMatched.code);
          if (_initialWardName != null) {
            _selectedWard = _findByName(_wards, _initialWardName) ??
                (_wards.isNotEmpty ? _wards.first : null);
          }
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onProvinceChanged(LocationItem? item) async {
    setState(() {
      _selectedProvince = item;
      _selectedDistrict = null;
      _selectedWard = null;
      _districts = [];
      _wards = [];
    });
    if (item == null) return;
    final districts = await _provinceApi.getDistricts(item.code);
    if (!mounted) return;
    if (districts.isEmpty) {
      final wards = await _provinceApi.getWardsByProvince(item.code);
      if (!mounted) return;
      setState(() {
        _districts = [];
        _wards = wards;
      });
    } else {
      setState(() {
        _districts = districts;
        _wards = [];
      });
    }
  }

  Future<void> _onDistrictChanged(LocationItem? item) async {
    setState(() {
      _selectedDistrict = item;
      _selectedWard = null;
      _wards = [];
    });
    if (item == null) return;
    final wards = await _provinceApi.getWards(item.code);
    if (mounted) {
      setState(() => _wards = wards);
    }
  }

  void _onComplete() {
    if (_selectedProvince == null ||
        (_districts.isNotEmpty && _selectedDistrict == null) ||
        _selectedWard == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn đầy đủ địa chỉ')),
      );
      return;
    }
    final house = _houseController.text.trim();
    if (house.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số nhà, tên đường')),
      );
      return;
    }

    final addressParts = <String>[
      house,
      _selectedWard!.name,
      if (_selectedDistrict != null) _selectedDistrict!.name,
      _selectedProvince!.name,
    ];
    final address = addressParts.join(', ');
    Navigator.pop(
      context,
      RecipientAddressResult(
        address: address,
        index: widget.editIndex,
        isDefault: widget.isDefault,
        hasOtherReceiver: _otherReceiver,
        otherReceiverName: _otherReceiverName,
        otherReceiverPhone: _otherReceiverPhone,
        otherReceiverTitle: _otherReceiverTitle,
      ),
    );
  }

  @override
  void dispose() {
    _houseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = (AuthSession.fullName == null || AuthSession.fullName!.isEmpty)
        ? 'Khách hàng'
        : AuthSession.fullName!;
    final phone =
        (AuthSession.phoneNumber == null || AuthSession.phoneNumber!.isEmpty)
        ? 'Chưa có số điện thoại'
        : AuthSession.phoneNumber!;

    return Scaffold(
      appBar: AppBar(title: const Text('Địa chỉ nhận hàng'), centerTitle: true),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildDropdown(
                    label: 'Tỉnh/Thành phố',
                    value: _selectedProvince,
                    items: _provinces,
                    onChanged: _loading ? null : _onProvinceChanged,
                  ),
                  if (_districts.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildDropdown(
                      label: 'Quận/Huyện',
                      value: _selectedDistrict,
                      items: _districts,
                      onChanged: _selectedProvince == null ? null : _onDistrictChanged,
                    ),
                  ],
                  const SizedBox(height: 12),
                  _buildDropdown(
                    label: 'Phường/Xã',
                    value: _selectedWard,
                    items: _wards,
                    onChanged: (_districts.isNotEmpty ? (_selectedDistrict == null) : (_selectedProvince == null))
                        ? null
                        : _onWardChanged,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _houseController,
                    decoration: InputDecoration(
                      labelText: 'Số nhà, tên đường',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!_otherReceiver)
                    Text(
                      'Người nhận: $name - $phone',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (!_otherReceiver) const SizedBox(height: 8),
                  Row(
                    children: [
                      Checkbox(
                        value: _otherReceiver,
                        onChanged: (value) {
                          final checked = value ?? false;
                          if (checked) {
                            _openOtherReceiverForm();
                          } else {
                            setState(() {
                              _otherReceiver = false;
                              _otherReceiverName = null;
                              _otherReceiverPhone = null;
                              _otherReceiverTitle = null;
                            });
                          }
                        },
                      ),
                      const Expanded(
                        child: Text('Gọi người nhận khác nhận hàng (nếu có)'),
                      ),
                    ],
                  ),
                  if (_otherReceiver &&
                      _otherReceiverName != null &&
                      _otherReceiverPhone != null)
                    const SizedBox(height: 8),
                  if (_otherReceiver &&
                      _otherReceiverName != null &&
                      _otherReceiverPhone != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'NgÆ°á»i nháº­n: ${_formatReceiverName()} - $_otherReceiverPhone',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _openOtherReceiverForm,
                            icon: const Icon(Icons.edit_outlined),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _onComplete,
                  child: const Text('Hoàn tất'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onWardChanged(LocationItem? item) {
    setState(() => _selectedWard = item);
  }

  Widget _buildDropdown({
    required String label,
    required List<LocationItem> items,
    required ValueChanged<LocationItem?>? onChanged,
    LocationItem? value,
  }) {
    return DropdownButtonFormField<LocationItem>(
      initialValue: value,
      items: items
          .map(
            (item) => DropdownMenuItem<LocationItem>(
              value: item,
              child: Text(item.name),
            ),
          )
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _formatReceiverName() {
    final title = _otherReceiverTitle;
    final name = _otherReceiverName ?? '';
    if (title == null || title.isEmpty) return name;
    return '$title $name';
  }

  Future<void> _openOtherReceiverForm() async {
    final phoneController = TextEditingController(
      text: _otherReceiverPhone ?? '',
    );
    final nameController = TextEditingController(
      text: _otherReceiverName ?? '',
    );
    String? selectedTitle = _otherReceiverTitle;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Gọi người khác nhận hàng',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context, false),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  RadioGroup<String>(
                    groupValue: selectedTitle,
                    onChanged: (value) {
                      setModalState(() => selectedTitle = value);
                    },
                    child: Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Anh'),
                            value: 'Anh',
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Chị'),
                            value: 'Chị',
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Họ và tên *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        final phone = phoneController.text.trim();
                        final name = nameController.text.trim();
                        if (!_isValidPhone(phone)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Số điện thoại không hợp lệ (10 số, bắt đầu bằng 0)',
                              ),
                            ),
                          );
                          return;
                        }
                        if (name.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Vui lòng nhập họ và tên'),
                            ),
                          );
                          return;
                        }
                        setState(() {
                          _otherReceiver = true;
                          _otherReceiverPhone = phone;
                          _otherReceiverName = name;
                          _otherReceiverTitle = selectedTitle;
                        });
                        Navigator.pop(context, true);
                      },
                      child: const Text('Hoàn tất'),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (ok != true && !_otherReceiver) {
      setState(() {});
    }
  }

  bool _isValidPhone(String value) {
    if (value.isEmpty) return false;
    if (value.length != 10) return false;
    if (!RegExp(r'^0[0-9]{9}$').hasMatch(value)) return false;
    return true;
  }
}
