import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../../../../core/auth/auth_session.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/snackbar_utils.dart';
import '../../utils/customer_l10n.dart';
import 'address_map_picker_screen.dart';
import 'recipient_address_form_screen.dart';

class RecipientInfoScreen extends StatefulWidget {
  const RecipientInfoScreen({super.key});

  @override
  State<RecipientInfoScreen> createState() => _RecipientInfoScreenState();
}

class _RecipientInfoScreenState extends State<RecipientInfoScreen> {
  final List<_SavedAddress> _extraAddresses = [];
  int _selectedIndex = 0;
  bool _selectCurrentGps = true;
  bool _defaultHasOtherReceiver = false;
  String? _defaultOtherReceiverName;
  String? _defaultOtherReceiverPhone;
  String? _defaultOtherReceiverTitle;

  @override
  void initState() {
    super.initState();
    _loadFromSession();
  }

  Future<void> _syncProfileToBackend() async {
    final token = AuthSession.token;
    if (token == null || token.isEmpty) return;

    final fullName = (AuthSession.fullName == null || AuthSession.fullName!.isEmpty)
      ? context.tr(vi: 'Khách hàng', en: 'Customer')
        : AuthSession.fullName!;
    final payload = <String, dynamic>{
      'fullName': fullName,
      'address': (AuthSession.address ?? '').toString(),
      'avatarUrl': AuthSession.avatarUrl,
    };

    try {
      final res = await ApiClient.dio.put('/users/profile', data: payload);
      final data = res.data;
      if (data is Map && data['success'] == true && data['data'] is Map) {
        final profile = Map<String, dynamic>.from(data['data'] as Map);
        AuthSession.fullName = (profile['fullName'] ?? fullName).toString();
        AuthSession.address = (profile['address'] ?? AuthSession.address ?? '').toString();
        AuthSession.avatarUrl = (profile['avatarUrl'] ?? AuthSession.avatarUrl ?? '').toString();
        if (AuthSession.avatarUrl != null && AuthSession.avatarUrl!.isEmpty) {
          AuthSession.avatarUrl = null;
        }
        return;
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      if (mounted) {
        SnackBarUtils.showError(
          context: context,
          message: (data is Map && data['message'] != null)
              ? data['message'].toString()
              : context.tr(vi: 'Không thể cập nhật địa chỉ', en: 'Unable to update address'),
        );
      }
    } catch (_) {
      if (mounted) {
        SnackBarUtils.showError(
          context: context,
          message: context.tr(vi: 'Không thể cập nhật địa chỉ', en: 'Unable to update address'),
        );
      }
    }
  }

  void _loadFromSession() {
    _selectedIndex = AuthSession.selectedAddressIndex;
    _selectCurrentGps = AuthSession.useCurrentLocation;
    _defaultHasOtherReceiver = AuthSession.defaultHasOtherReceiver;
    _defaultOtherReceiverName = AuthSession.defaultOtherReceiverName;
    _defaultOtherReceiverPhone = AuthSession.defaultOtherReceiverPhone;
    _defaultOtherReceiverTitle = AuthSession.defaultOtherReceiverTitle;

    _extraAddresses.clear();
    for (final item in AuthSession.savedAddresses) {
      _extraAddresses.add(
        _SavedAddress(
          name: (item['name'] ?? '').toString(),
          phone: (item['phone'] ?? '').toString(),
          address: (item['address'] ?? '').toString(),
          hasOtherReceiver: item['hasOtherReceiver'] == true,
          otherReceiverName: item['otherReceiverName']?.toString(),
          otherReceiverPhone: item['otherReceiverPhone']?.toString(),
          otherReceiverTitle: item['otherReceiverTitle']?.toString(),
        ),
      );
    }
  }

  Future<void> _openMapPicker() async {
    final picked = await Navigator.push<AddressMapPickerResult?>(
      context,
      MaterialPageRoute(builder: (_) => const AddressMapPickerScreen()),
    );

    if (!mounted || picked == null || picked.address.trim().isEmpty) {
      return;
    }

    setState(() {
      AuthSession.setManualAddressWithCoordinates(
        value: picked.address.trim(),
        latitude: picked.latitude,
        longitude: picked.longitude,
      );
      _selectCurrentGps = false;
      _selectedIndex = 0;
    });
    await _syncProfileToBackend();
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.tr(vi: 'Xóa địa chỉ', en: 'Delete address')),
          content: Text(
            context.tr(
              vi: 'Bạn có chắc chắn muốn xóa địa chỉ này?',
              en: 'Are you sure you want to delete this address?',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(context.tr(vi: 'Không xóa', en: 'Keep')),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(context.tr(vi: 'Xóa', en: 'Delete')),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<void> _openAddAddress() async {
    final result = await Navigator.push<RecipientAddressResult?>(
      context,
      MaterialPageRoute(builder: (_) => const RecipientAddressFormScreen()),
    );
    if (result != null && result.address.trim().isNotEmpty) {
      setState(() {
        _extraAddresses.add(
          _SavedAddress(
            name:
                (AuthSession.fullName == null || AuthSession.fullName!.isEmpty)
                ? context.tr(vi: 'Khách hàng', en: 'Customer')
                : AuthSession.fullName!,
            phone:
                (AuthSession.phoneNumber == null ||
                    AuthSession.phoneNumber!.isEmpty)
                ? context.tr(vi: 'Chưa có số điện thoại', en: 'No phone number')
                : AuthSession.phoneNumber!,
            address: result.address.trim(),
            otherReceiverName: result.otherReceiverName,
            otherReceiverPhone: result.otherReceiverPhone,
            otherReceiverTitle: result.otherReceiverTitle,
            hasOtherReceiver: result.hasOtherReceiver,
          ),
        );
        _syncExtraToSession();
      });
    }
  }

  Future<void> _editAddress(int index) async {
    final result = await Navigator.push<RecipientAddressResult?>(
      context,
      MaterialPageRoute(
        builder: (_) => RecipientAddressFormScreen(
          initialAddress: _extraAddresses[index].address,
          editIndex: index,
          hasOtherReceiver: _extraAddresses[index].hasOtherReceiver,
          otherReceiverName: _extraAddresses[index].otherReceiverName,
          otherReceiverPhone: _extraAddresses[index].otherReceiverPhone,
          otherReceiverTitle: _extraAddresses[index].otherReceiverTitle,
        ),
      ),
    );
    if (result != null && result.address.trim().isNotEmpty) {
      setState(() {
        _extraAddresses[index] = _SavedAddress(
          name: _extraAddresses[index].name,
          phone: _extraAddresses[index].phone,
          address: result.address.trim(),
          otherReceiverName: result.otherReceiverName,
          otherReceiverPhone: result.otherReceiverPhone,
          otherReceiverTitle: result.otherReceiverTitle,
          hasOtherReceiver: result.hasOtherReceiver,
        );
        _syncExtraToSession();
      });
    }
  }

  Future<void> _editDefaultAddress() async {
    final result = await Navigator.push<RecipientAddressResult?>(
      context,
      MaterialPageRoute(
        builder: (_) => RecipientAddressFormScreen(
          initialAddress: AuthSession.address,
          isDefault: true,
          hasOtherReceiver: _defaultHasOtherReceiver,
          otherReceiverName: _defaultOtherReceiverName,
          otherReceiverPhone: _defaultOtherReceiverPhone,
          otherReceiverTitle: _defaultOtherReceiverTitle,
        ),
      ),
    );
    if (result != null && result.address.trim().isNotEmpty) {
      setState(() {
        AuthSession.setManualAddress(result.address.trim());
        _defaultHasOtherReceiver = result.hasOtherReceiver;
        _defaultOtherReceiverName = result.otherReceiverName;
        _defaultOtherReceiverPhone = result.otherReceiverPhone;
        _defaultOtherReceiverTitle = result.otherReceiverTitle;
        AuthSession.defaultHasOtherReceiver = _defaultHasOtherReceiver;
        AuthSession.defaultOtherReceiverName = _defaultOtherReceiverName;
        AuthSession.defaultOtherReceiverPhone = _defaultOtherReceiverPhone;
        AuthSession.defaultOtherReceiverTitle = _defaultOtherReceiverTitle;
      });
      await _syncProfileToBackend();
    }
  }

  Future<void> _deleteAddress(int index) async {
    final ok = await _confirmDelete(context);
    if (!ok) return;
    setState(() {
      _extraAddresses.removeAt(index);
      if (_selectedIndex == index + 1) {
        _selectedIndex = 0;
      } else if (_selectedIndex > index + 1) {
        _selectedIndex -= 1;
      }
      _syncExtraToSession();
    });
  }

  Future<void> _deleteDefaultAddress() async {
    final ok = await _confirmDelete(context);
    if (!ok) return;
    setState(() {
      AuthSession.address = '';
      AuthSession.switchToCurrentLocation();
      _defaultHasOtherReceiver = false;
      _defaultOtherReceiverName = null;
      _defaultOtherReceiverPhone = null;
      _defaultOtherReceiverTitle = null;
      AuthSession.defaultHasOtherReceiver = false;
      AuthSession.defaultOtherReceiverName = null;
      AuthSession.defaultOtherReceiverPhone = null;
      AuthSession.defaultOtherReceiverTitle = null;
      if (_selectedIndex == 0 && _extraAddresses.isNotEmpty) {
        _selectedIndex = 1;
      }
    });
    await _syncProfileToBackend();
  }

  void _syncExtraToSession() {
    AuthSession.savedAddresses = _extraAddresses
        .map(
          (e) => {
            'name': e.name,
            'phone': e.phone,
            'address': e.address,
            'hasOtherReceiver': e.hasOtherReceiver,
            'otherReceiverName': e.otherReceiverName,
            'otherReceiverPhone': e.otherReceiverPhone,
            'otherReceiverTitle': e.otherReceiverTitle,
          },
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final name = (AuthSession.fullName == null || AuthSession.fullName!.isEmpty)
      ? context.tr(vi: 'Khách hàng', en: 'Customer')
        : AuthSession.fullName!;
    final phone =
        (AuthSession.phoneNumber == null || AuthSession.phoneNumber!.isEmpty)
        ? context.tr(vi: 'Chưa có số điện thoại', en: 'No phone number')
        : AuthSession.phoneNumber!;
    final address =
        (AuthSession.address == null || AuthSession.address!.isEmpty)
        ? context.tr(vi: 'Chưa có địa chỉ', en: 'No address yet')
        : AuthSession.address!;
    final currentGpsAddress =
        (AuthSession.currentLocationAddress == null ||
            AuthSession.currentLocationAddress!.trim().isEmpty)
        ? context.tr(vi: 'Đang lấy vị trí hiện tại', en: 'Getting current location')
        : AuthSession.currentLocationAddress!.trim();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(vi: 'Địa chỉ giao hàng', en: 'Delivery address')),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: context.tr(vi: 'Chọn vị trí trên bản đồ', en: 'Pick location on map'),
            onPressed: _openMapPicker,
            icon: const Icon(Icons.map_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    context.tr(vi: 'Địa chỉ hiện tại (GPS)', en: 'Current address (GPS)'),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _CurrentLocationCard(
                    address: currentGpsAddress,
                    selected: _selectCurrentGps,
                    onSelect: () => setState(() => _selectCurrentGps = true),
                  ),
                  _RecipientCard(
                    name: name,
                    phone: phone,
                    address: address,
                    hasOtherReceiver: _defaultHasOtherReceiver,
                    otherReceiverName: _defaultOtherReceiverName,
                    otherReceiverPhone: _defaultOtherReceiverPhone,
                    otherReceiverTitle: _defaultOtherReceiverTitle,
                    onEdit: _editDefaultAddress,
                    onDelete: _deleteDefaultAddress,
                    selected: !_selectCurrentGps && _selectedIndex == 0,
                    onSelect: () => setState(() {
                      _selectCurrentGps = false;
                      _selectedIndex = 0;
                    }),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.tr(vi: 'Địa chỉ đã lưu', en: 'Saved addresses'),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ..._extraAddresses.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AddressCard(
                        item: entry.value,
                        selected:
                            !_selectCurrentGps && _selectedIndex == entry.key + 1,
                        onSelect: () => setState(() {
                          _selectCurrentGps = false;
                          _selectedIndex = entry.key + 1;
                        }),
                        onEdit: () => _editAddress(entry.key),
                        onDelete: () => _deleteAddress(entry.key),
                      ),
                    ),
                  ),
                  if (_extraAddresses.isNotEmpty) const SizedBox(height: 4),
                  TextButton.icon(
                    onPressed: _openAddAddress,
                    icon: Icon(Icons.add, color: scheme.primary),
                    label: Text(context.tr(vi: 'Thêm thông tin nhận hàng', en: 'Add delivery info')),
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
                  onPressed: () async {
                    if (_selectCurrentGps) {
                      AuthSession.switchToCurrentLocation();
                    } else {
                      final all = [
                        _SavedAddress(name: name, phone: phone, address: address),
                        ..._extraAddresses,
                      ];
                      if (_selectedIndex >= 0 && _selectedIndex < all.length) {
                        AuthSession.setManualAddress(all[_selectedIndex].address);
                      }
                    }
                    AuthSession.selectedAddressIndex = _selectedIndex;
                    await _syncProfileToBackend();
                    Navigator.pop(context);
                  },
                  child: Text(context.tr(vi: 'Xác nhận', en: 'Confirm')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentLocationCard extends StatelessWidget {
  final String address;
  final bool selected;
  final VoidCallback onSelect;

  const _CurrentLocationCard({
    required this.address,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onSelect,
              child: Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: scheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr(vi: 'Vị trí hiện tại', en: 'Current location'),
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    address,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipientCard extends StatelessWidget {
  final String name;
  final String phone;
  final String address;
  final bool hasOtherReceiver;
  final String? otherReceiverName;
  final String? otherReceiverPhone;
  final String? otherReceiverTitle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool selected;
  final VoidCallback onSelect;

  const _RecipientCard({
    required this.name,
    required this.phone,
    required this.address,
    required this.hasOtherReceiver,
    this.otherReceiverName,
    this.otherReceiverPhone,
    this.otherReceiverTitle,
    required this.onEdit,
    required this.onDelete,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onSelect,
              child: Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: scheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _displayPrimaryName(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    address,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  if (hasOtherReceiver &&
                      otherReceiverName != null &&
                      otherReceiverPhone != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        context.tr(
                          vi: 'Người nhận: ${_formatOtherReceiver()} - $otherReceiverPhone',
                          en: 'Receiver: ${_formatOtherReceiver()} - $otherReceiverPhone',
                        ),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ),
            Column(
              children: [
                TextButton(
                  onPressed: onEdit,
                  child: Text(context.tr(vi: 'Sửa', en: 'Edit')),
                ),
                TextButton(
                  onPressed: onDelete,
                  child: Text(context.tr(vi: 'Xóa', en: 'Delete')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _displayPrimaryName() {
    if (hasOtherReceiver &&
        otherReceiverName != null &&
        otherReceiverPhone != null) {
      final title = otherReceiverTitle;
      final name = otherReceiverName ?? '';
      final display = (title == null || title.isEmpty) ? name : '$title $name';
      return '$display, $otherReceiverPhone';
    }
    return '$name, $phone';
  }

  String _formatOtherReceiver() {
    final title = otherReceiverTitle;
    final name = otherReceiverName ?? '';
    if (title == null || title.isEmpty) return name;
    return '$title $name';
  }
}

class _SavedAddress {
  final String name;
  final String phone;
  final String address;
  final bool hasOtherReceiver;
  final String? otherReceiverName;
  final String? otherReceiverPhone;
  final String? otherReceiverTitle;

  _SavedAddress({
    required this.name,
    required this.phone,
    required this.address,
    this.hasOtherReceiver = false,
    this.otherReceiverName,
    this.otherReceiverPhone,
    this.otherReceiverTitle,
  });
}

class _AddressCard extends StatelessWidget {
  final _SavedAddress item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool selected;
  final VoidCallback onSelect;

  const _AddressCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onSelect,
              child: Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: scheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _displayPrimaryName(item),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.address,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  if (item.hasOtherReceiver &&
                      item.otherReceiverName != null &&
                      item.otherReceiverPhone != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        context.tr(
                          vi: 'Người nhận: ${_formatOtherReceiver(item)} - ${item.otherReceiverPhone}',
                          en: 'Receiver: ${_formatOtherReceiver(item)} - ${item.otherReceiverPhone}',
                        ),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ),
            Column(
              children: [
                TextButton(
                  onPressed: onEdit,
                  child: Text(context.tr(vi: 'Sửa', en: 'Edit')),
                ),
                TextButton(
                  onPressed: onDelete,
                  child: Text(context.tr(vi: 'Xóa', en: 'Delete')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _displayPrimaryName(_SavedAddress item) {
    if (item.hasOtherReceiver &&
        item.otherReceiverName != null &&
        item.otherReceiverPhone != null) {
      final title = item.otherReceiverTitle;
      final name = item.otherReceiverName ?? '';
      final display = (title == null || title.isEmpty) ? name : '$title $name';
      return '$display, ${item.otherReceiverPhone}';
    }
    return '${item.name}, ${item.phone}';
  }

  String _formatOtherReceiver(_SavedAddress item) {
    final title = item.otherReceiverTitle;
    final name = item.otherReceiverName ?? '';
    if (title == null || title.isEmpty) return name;
    return '$title $name';
  }
}
