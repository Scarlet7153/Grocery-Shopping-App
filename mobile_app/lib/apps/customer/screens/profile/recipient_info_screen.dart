import 'package:flutter/material.dart';

import '../../../../core/auth/auth_session.dart';
import 'recipient_address_form_screen.dart';

class RecipientInfoScreen extends StatefulWidget {
  const RecipientInfoScreen({super.key});

  @override
  State<RecipientInfoScreen> createState() => _RecipientInfoScreenState();
}

class _RecipientInfoScreenState extends State<RecipientInfoScreen> {
  final List<_SavedAddress> _extraAddresses = [];
  int _selectedIndex = 0;
  bool _defaultHasOtherReceiver = false;
  String? _defaultOtherReceiverName;
  String? _defaultOtherReceiverPhone;
  String? _defaultOtherReceiverTitle;

  @override
  void initState() {
    super.initState();
    _loadFromSession();
  }

  void _loadFromSession() {
    _selectedIndex = AuthSession.selectedAddressIndex;
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

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xóa địa chỉ'),
          content: const Text('Bạn có chắc chắn muốn xóa địa chỉ này?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Không xóa'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Xóa'),
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
                ? 'Khách hàng'
                : AuthSession.fullName!,
            phone:
                (AuthSession.phoneNumber == null ||
                    AuthSession.phoneNumber!.isEmpty)
                ? 'Chưa có số điện thoại'
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
        AuthSession.address = result.address.trim();
        _defaultHasOtherReceiver = result.hasOtherReceiver;
        _defaultOtherReceiverName = result.otherReceiverName;
        _defaultOtherReceiverPhone = result.otherReceiverPhone;
        _defaultOtherReceiverTitle = result.otherReceiverTitle;
        AuthSession.defaultHasOtherReceiver = _defaultHasOtherReceiver;
        AuthSession.defaultOtherReceiverName = _defaultOtherReceiverName;
        AuthSession.defaultOtherReceiverPhone = _defaultOtherReceiverPhone;
        AuthSession.defaultOtherReceiverTitle = _defaultOtherReceiverTitle;
      });
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
    final name = (AuthSession.fullName == null || AuthSession.fullName!.isEmpty)
        ? 'Khách hàng'
        : AuthSession.fullName!;
    final phone =
        (AuthSession.phoneNumber == null || AuthSession.phoneNumber!.isEmpty)
        ? 'Chưa có số điện thoại'
        : AuthSession.phoneNumber!;
    final address =
        (AuthSession.address == null || AuthSession.address!.isEmpty)
        ? 'Chưa có địa chỉ'
        : AuthSession.address!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin nhận hàng'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
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
                    selected: _selectedIndex == 0,
                    onSelect: () => setState(() => _selectedIndex = 0),
                  ),
                  const SizedBox(height: 16),
                  ..._extraAddresses.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AddressCard(
                        item: entry.value,
                        selected: _selectedIndex == entry.key + 1,
                        onSelect: () =>
                            setState(() => _selectedIndex = entry.key + 1),
                        onEdit: () => _editAddress(entry.key),
                        onDelete: () => _deleteAddress(entry.key),
                      ),
                    ),
                  ),
                  if (_extraAddresses.isNotEmpty) const SizedBox(height: 4),
                  TextButton.icon(
                    onPressed: _openAddAddress,
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm thông tin nhận hàng'),
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
                  onPressed: () {
                    final all = [
                      _SavedAddress(name: name, phone: phone, address: address),
                      ..._extraAddresses,
                    ];
                    if (_selectedIndex >= 0 && _selectedIndex < all.length) {
                      AuthSession.address = all[_selectedIndex].address;
                    }
                    AuthSession.selectedAddressIndex = _selectedIndex;
                    Navigator.pop(context);
                  },
                  child: const Text('Xác nhận'),
                ),
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
                color: const Color(0xFF2F80ED),
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
                  Text(address, style: const TextStyle(color: Colors.black54)),
                  if (hasOtherReceiver &&
                      otherReceiverName != null &&
                      otherReceiverPhone != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Người nhận: ${_formatOtherReceiver()} - $otherReceiverPhone',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ),
            Column(
              children: [
                TextButton(onPressed: onEdit, child: const Text('Sửa')),
                TextButton(onPressed: onDelete, child: const Text('Xóa')),
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
                color: const Color(0xFF2F80ED),
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
                    style: const TextStyle(color: Colors.black54),
                  ),
                  if (item.hasOtherReceiver &&
                      item.otherReceiverName != null &&
                      item.otherReceiverPhone != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Người nhận: ${_formatOtherReceiver(item)} - ${item.otherReceiverPhone}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ),
            Column(
              children: [
                TextButton(onPressed: onEdit, child: const Text('Sửa')),
                TextButton(onPressed: onDelete, child: const Text('Xóa')),
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
