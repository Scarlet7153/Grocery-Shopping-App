import 'package:flutter/material.dart';
import 'package:grocery_shopping_app/core/utils/app_localizations.dart';

class ContactSupportScreen extends StatefulWidget {
  const ContactSupportScreen({super.key});

  @override
  State<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen> {
  final _formKey = GlobalKey<FormState>();
  String _hotline = '1900 1234';
  String _email = 'support@dichoho.vn';
  String _address = 'Tòa nhà Bitexco, Quận 1, TP. HCM';

  void _saveContact() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.byLocale(vi: 'Đã cập nhật cấu hình liên hệ!', en: 'Contact settings updated!'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l.byLocale(vi: 'Thông Tin Liên Hệ (CSKH)', en: 'Contact Information (Support)')),
        backgroundColor: Colors.indigo[600],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.byLocale(
                  vi: 'Chỉnh sửa thông tin hiển thị trên app khách hàng:',
                  en: 'Edit the contact details displayed in the customer app:',
                ),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextFormField(
                        initialValue: _hotline,
                        decoration: InputDecoration(
                          labelText: l.byLocale(vi: 'Hotline CSKH', en: 'Support hotline'),
                          prefixIcon: const Icon(Icons.phone),
                        ),
                        validator: (v) => v!.isEmpty ? l.byLocale(vi: 'Không được để trống', en: 'Cannot be empty') : null,
                        onSaved: (v) => _hotline = v!,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: _email,
                        decoration: InputDecoration(
                          labelText: l.byLocale(vi: 'Email hỗ trợ', en: 'Support email'),
                          prefixIcon: const Icon(Icons.email),
                        ),
                        validator: (v) => v!.isEmpty || !v.contains('@') ? l.byLocale(vi: 'Email không hợp lệ', en: 'Invalid email') : null,
                        onSaved: (v) => _email = v!,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: _address,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: l.byLocale(vi: 'Địa chỉ trụ sở', en: 'Head office address'),
                          prefixIcon: const Icon(Icons.location_city),
                        ),
                        validator: (v) => v!.isEmpty ? l.byLocale(vi: 'Không được để trống', en: 'Cannot be empty') : null,
                        onSaved: (v) => _address = v!,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveContact,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(l.byLocale(vi: 'Lưu Thay Đổi', en: 'Save Changes'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
