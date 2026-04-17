// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/snackbar_utils.dart';

import '../../../../core/auth/auth_session.dart';
import '../auth/customer_login_screen.dart';
import '../orders/customer_orders_screen.dart';
import 'recipient_info_screen.dart';
import '../cart/customer_payment_method_screen.dart';
import '../../bloc/customer_language_cubit.dart';
import '../../bloc/customer_theme_cubit.dart';
import '../../shared/customer_payment_method.dart';
import '../../shared/customer_payment_preferences.dart';
import '../../utils/customer_l10n.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  bool _uploadingAvatar = false;

  String _themeLabel(CustomerThemePreference preference, BuildContext context) {
    switch (preference) {
      case CustomerThemePreference.system:
        return context.tr(vi: 'Theo hệ thống', en: 'System');
      case CustomerThemePreference.light:
        return context.tr(vi: 'Sáng', en: 'Light');
      case CustomerThemePreference.dark:
        return context.tr(vi: 'Tối', en: 'Dark');
    }
  }

  String _languageLabel(
      CustomerLanguagePreference preference, BuildContext context) {
    switch (preference) {
      case CustomerLanguagePreference.system:
        return context.tr(vi: 'Theo hệ thống', en: 'System');
      case CustomerLanguagePreference.vietnamese:
        return context.tr(vi: 'Tiếng Việt', en: 'Vietnamese');
      case CustomerLanguagePreference.english:
        return context.tr(vi: 'Tiếng Anh', en: 'English');
    }
  }

  Future<void> _showLanguagePicker(
    BuildContext context,
    CustomerLanguagePreference current,
  ) async {
    final selected = await showModalBottomSheet<CustomerLanguagePreference>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  context.tr(vi: 'Chọn ngôn ngữ', en: 'Choose language'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              RadioListTile<CustomerLanguagePreference>(
                value: CustomerLanguagePreference.system,
                groupValue: current,
                title: Text(context.tr(vi: 'Theo hệ thống', en: 'System')),
                onChanged: (value) => Navigator.of(sheetContext).pop(value),
              ),
              RadioListTile<CustomerLanguagePreference>(
                value: CustomerLanguagePreference.vietnamese,
                groupValue: current,
                title: Text(context.tr(vi: 'Tiếng Việt', en: 'Vietnamese')),
                onChanged: (value) => Navigator.of(sheetContext).pop(value),
              ),
              RadioListTile<CustomerLanguagePreference>(
                value: CustomerLanguagePreference.english,
                groupValue: current,
                title: Text(context.tr(vi: 'Tiếng Anh', en: 'English')),
                onChanged: (value) => Navigator.of(sheetContext).pop(value),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (selected != null && mounted) {
      context.read<CustomerLanguageCubit>().setLanguagePreference(selected);
    }
  }

  Future<void> _showThemeModePicker(
    BuildContext context,
    CustomerThemePreference current,
  ) async {
    final selected = await showModalBottomSheet<CustomerThemePreference>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  context.tr(vi: 'Chọn giao diện', en: 'Choose theme'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              RadioListTile<CustomerThemePreference>(
                value: CustomerThemePreference.system,
                groupValue: current,
                title: Text(context.tr(vi: 'Theo hệ thống', en: 'System')),
                subtitle: Text(context.tr(
                  vi: 'Tự động theo cài đặt thiết bị',
                  en: 'Follow device setting',
                )),
                onChanged: (value) {
                  Navigator.of(sheetContext).pop(value);
                },
              ),
              RadioListTile<CustomerThemePreference>(
                value: CustomerThemePreference.light,
                groupValue: current,
                title: Text(context.tr(vi: 'Sáng', en: 'Light')),
                onChanged: (value) {
                  Navigator.of(sheetContext).pop(value);
                },
              ),
              RadioListTile<CustomerThemePreference>(
                value: CustomerThemePreference.dark,
                groupValue: current,
                title: Text(context.tr(vi: 'Tối', en: 'Dark')),
                onChanged: (value) {
                  Navigator.of(sheetContext).pop(value);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (selected != null && mounted) {
      context.read<CustomerThemeCubit>().setThemePreference(selected);
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    if (_uploadingAvatar) return;

    final token = AuthSession.token;
    if (token == null || token.isEmpty) {
      SnackBarUtils.showError(
        context: context,
        message: context.tr(
          vi: 'Bạn cần đăng nhập để đổi ảnh đại diện',
          en: 'You need to sign in to change avatar',
        ),
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

      final response =
          await ApiClient.dio.post('/upload/avatar', data: formData);
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
              message: context.tr(
                vi: 'Cập nhật ảnh đại diện thành công',
                en: 'Avatar updated successfully',
              ),
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
              : context.tr(
                  vi: 'Upload ảnh thất bại', en: 'Avatar upload failed'),
        );
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      if (mounted) {
        SnackBarUtils.showError(
          context: context,
          message: (data is Map && data['message'] != null)
              ? data['message'].toString()
              : context.tr(
                  vi: 'Không thể kết nối đến máy chủ',
                  en: 'Cannot connect to server',
                ),
        );
      }
    } catch (_) {
      if (mounted) {
        SnackBarUtils.showError(
          context: context,
          message:
              context.tr(vi: 'Upload ảnh thất bại', en: 'Avatar upload failed'),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _uploadingAvatar = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final name = (AuthSession.fullName == null || AuthSession.fullName!.isEmpty)
        ? context.tr(vi: 'Khách hàng', en: 'Customer')
        : AuthSession.fullName!;
    final address =
        (AuthSession.address == null || AuthSession.address!.isEmpty)
            ? context.tr(vi: 'Chưa có địa chỉ', en: 'No address')
            : AuthSession.address!;
    final phone =
        (AuthSession.phoneNumber == null || AuthSession.phoneNumber!.isEmpty)
            ? context.tr(vi: 'Chưa có số điện thoại', en: 'No phone number')
            : AuthSession.phoneNumber!;
    final avatarUrl = AuthSession.avatarUrl;

    return Container(
      color: scheme.surfaceContainerLowest,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: scheme.primaryContainer,
                      backgroundImage:
                          (avatarUrl != null && avatarUrl.isNotEmpty)
                              ? NetworkImage(avatarUrl)
                              : null,
                      child: (avatarUrl == null || avatarUrl.isEmpty)
                          ? Icon(
                              Icons.person,
                              color: scheme.primary,
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
                              color: scheme.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: scheme.outlineVariant),
                              boxShadow: [
                                BoxShadow(
                                  color: scheme.shadow.withValues(alpha: 0.12),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: _uploadingAvatar
                                ? const Padding(
                                    padding: EdgeInsets.all(6),
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
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
                  style:
                      TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  address,
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
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
                  title: Text(
                      context.tr(vi: 'Địa chỉ của tôi', en: 'My addresses')),
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
                  title: Text(context.tr(
                      vi: 'Phương thức thanh toán', en: 'Payment methods')),
                  subtitle: ValueListenableBuilder<CustomerPaymentMethod>(
                    valueListenable: CustomerPaymentPreferences.method,
                    builder: (context, method, _) =>
                        Text(method.labelOf(context)),
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
                  title: Text(
                      context.tr(vi: 'Lịch sử đơn hàng', en: 'Order history')),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const CustomerOrdersScreen()),
                    );
                  },
                ),
                const Divider(height: 1),
                BlocBuilder<CustomerThemeCubit, CustomerThemeState>(
                  builder: (context, themeState) {
                    return ListTile(
                      leading: const Icon(Icons.palette_outlined),
                      title:
                          Text(context.tr(vi: 'Giao diện', en: 'Appearance')),
                      subtitle:
                          Text(_themeLabel(themeState.preference, context)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showThemeModePicker(
                        context,
                        themeState.preference,
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                BlocBuilder<CustomerLanguageCubit, CustomerLanguageState>(
                  builder: (context, languageState) {
                    return ListTile(
                      leading: const Icon(Icons.language_outlined),
                      title: Text(context.tr(vi: 'Ngôn ngữ', en: 'Language')),
                      subtitle: Text(
                        _languageLabel(languageState.preference, context),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showLanguagePicker(
                        context,
                        languageState.preference,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: ListTile(
              leading: Icon(Icons.logout, color: scheme.error),
              title: Text(context.tr(vi: 'Đăng xuất', en: 'Logout')),
              onTap: () async {
                await AuthSession.clearPersistedToken();
                AuthSession.clear();
                if (!mounted) return;
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
