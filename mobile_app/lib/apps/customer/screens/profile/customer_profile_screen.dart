import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/snackbar_utils.dart';

import '../../../../core/auth/auth_session.dart';
import '../auth/customer_login_screen.dart';
import 'recipient_info_screen.dart';
import '../cart/customer_payment_method_screen.dart';
import '../../shared/customer_payment_method.dart';
import '../../shared/customer_payment_preferences.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  bool _uploadingAvatar = false;

  Future<void> _pickAndUploadAvatar() async {
    if (_uploadingAvatar) return;

    final token = AuthSession.token;
    if (token == null || token.isEmpty) {
      SnackBarUtils.showError(
        context: context,
        message: 'Bạn cần đăng nhập để đổi ảnh đại diện',
      );
      return;
    }

    final picker = ImagePicker();
    final xfile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (xfile == null) return;

    setState(() => _uploadingAvatar = true);
    try {
      final bytes = kIsWeb ? await xfile.readAsBytes() : null;

      final formData = FormData.fromMap({
        'file': kIsWeb
            ? MultipartFile.fromBytes(bytes!, filename: xfile.name)
            : await MultipartFile.fromFile(xfile.path, filename: xfile.name),
      });

      final response = await ApiClient.dio.post('/upload/avatar', data: formData);
      final data = response.data;

      if (data is Map && data['success'] == true) {
        final imageUrl = (data['data'] ?? '').toString();
        if (imageUrl.isNotEmpty) {
          AuthSession.avatarUrl = imageUrl;
          if (mounted) {
            setState(() {});
          }
          if (mounted) {
            SnackBarUtils.showSuccess(
              context: context,
              message: 'Cập nhật ảnh đại diện thành công',
            );
          }
          return;
        }
      }

      if (mounted) {
        SnackBarUtils.showError(
          context: context,
          message: (data is Map && data['message'] != null)
              ? data['message'].toString()
              : 'Upload ảnh thất bại',
        );
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      if (mounted) {
        SnackBarUtils.showError(
          context: context,
          message: (data is Map && data['message'] != null)
              ? data['message'].toString()
              : 'Không thể kết nối đến máy chủ',
        );
      }
    } catch (_) {
      if (mounted) {
        SnackBarUtils.showError(context: context, message: 'Upload ảnh thất bại');
      }
    } finally {
      if (mounted) {
        setState(() => _uploadingAvatar = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = (AuthSession.fullName == null || AuthSession.fullName!.isEmpty)
        ? 'Kh\u00e1ch h\u00e0ng'
        : AuthSession.fullName!;
    final address =
        (AuthSession.address == null || AuthSession.address!.isEmpty)
        ? 'Ch\u01b0a c\u00f3 \u0111\u1ecba ch\u1ec9'
        : AuthSession.address!;
    final phone =
        (AuthSession.phoneNumber == null || AuthSession.phoneNumber!.isEmpty)
        ? 'Ch\u01b0a c\u00f3 s\u1ed1 \u0111i\u1ec7n tho\u1ea1i'
        : AuthSession.phoneNumber!;
    final avatarUrl = AuthSession.avatarUrl;

    return Container(
      color: const Color(0xFFF6F8FB),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black12),
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: const Color(0xFFEAF2FF),
                      backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: (avatarUrl == null || avatarUrl.isEmpty)
                          ? const Icon(
                              Icons.person,
                              color: Color(0xFF2F80ED),
                              size: 36,
                            )
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _uploadingAvatar ? null : _pickAndUploadAvatar,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.black12),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: _uploadingAvatar
                                ? const Padding(
                                    padding: EdgeInsets.all(6),
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.edit, size: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  phone,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  address,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.location_on),
                  title: const Text('\u0110\u1ecba ch\u1ec9 c\u1ee7a t\u00f4i'),
                  subtitle: Text(address),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RecipientInfoScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.payment),
                  title: const Text(
                    'Ph\u01b0\u01a1ng th\u1ee9c thanh to\u00e1n',
                  ),
                  subtitle: ValueListenableBuilder<CustomerPaymentMethod>(
                    valueListenable: CustomerPaymentPreferences.method,
                    builder: (context, method, _) => Text(method.label),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final selected =
                        await Navigator.of(context).push<CustomerPaymentMethod>(
                      MaterialPageRoute(
                        builder: (_) => CustomerPaymentMethodScreen(
                          initial: CustomerPaymentPreferences.method.value,
                        ),
                      ),
                    );
                    if (selected != null) {
                      CustomerPaymentPreferences.method.value = selected;
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text(
                    'L\u1ecbch s\u1eed \u0111\u01a1n h\u00e0ng',
                  ),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black12),
            ),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('\u0110\u0103ng xu\u1ea5t'),
              onTap: () {
                AuthSession.clear();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CustomerLoginScreen(),
                  ),
                  (route) => false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
