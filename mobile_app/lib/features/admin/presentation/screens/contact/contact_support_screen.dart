import 'package:flutter/material.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã cập nhật cấu hình liên hệ!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Thông Tin Liên Hệ (CSKH)'),
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
              const Text(
                'Chín sửa thông tin hiển thị trên app khách hàng:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                        decoration: const InputDecoration(
                          labelText: 'Hotline CSKH',
                          prefixIcon: Icon(Icons.phone),
                        ),
                        validator: (v) => v!.isEmpty ? 'Không được để trống' : null,
                        onSaved: (v) => _hotline = v!,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: _email,
                        decoration: const InputDecoration(
                          labelText: 'Email hỗ trợ',
                          prefixIcon: Icon(Icons.email),
                        ),
                        validator: (v) => v!.isEmpty || !v.contains('@') ? 'Email không hợp lệ' : null,
                        onSaved: (v) => _email = v!,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: _address,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Địa chỉ trụ sở',
                          prefixIcon: Icon(Icons.location_city),
                        ),
                        validator: (v) => v!.isEmpty ? 'Không được để trống' : null,
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
                  backgroundColor: Colors.indigo[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Lưu Thay Đổi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
