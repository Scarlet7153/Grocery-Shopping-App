import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/store_theme.dart';
import '../../../../core/utils/app_localizations.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../features/store/data/store_model.dart';
import '../../bloc/store_blocs.dart';
import '../../bloc/store_language_cubit.dart';
import '../../bloc/store_theme_cubit.dart';
import '../../../../features/auth/bloc/auth_bloc.dart';
import '../../../../features/auth/bloc/auth_event.dart';
import '../../../../features/auth/repository/auth_repository.dart';
import '../../../../features/notification/presentation/widgets/notification_icon_button.dart';
import 'store_profile_edit_screen.dart';

String _tr(BuildContext context, {required String vi, required String en}) {
  final localizations = AppLocalizations.of(context);
  return localizations?.byLocale(vi: vi, en: en) ?? vi;
}

String _localizeChangePasswordError(BuildContext context, Object error) {
  var message = error is ServerException ? error.message : error.toString();
  message = message.trim();

  if (message.startsWith('ServerException:')) {
    message = message.substring('ServerException:'.length).trim();
  }
  if (message.startsWith('Exception:')) {
    message = message.substring('Exception:'.length).trim();
  }
  message = message.replaceFirst(RegExp(r'\s*\(Status:\s*\d+\)\s*$'), '').trim();

  final locale = AppLocalizations.of(context)?.locale.languageCode ?? 'vi';
  if (locale == 'vi') return message;

  final lower = message.toLowerCase();
  if (lower.contains('mật khẩu cũ không đúng')) {
    return 'Current password is incorrect';
  }
  if (lower.contains('xác nhận mật khẩu không khớp') ||
      lower.contains('mật khẩu không khớp')) {
    return 'Password confirmation does not match';
  }
  if (lower.contains('mật khẩu mới phải') && lower.contains('ký tự')) {
    return 'New password must be at least 6 characters';
  }
  if (lower.contains('thông tin đổi mật khẩu không hợp lệ')) {
    return 'Invalid password change information';
  }
  if (lower.contains('lỗi server khi đổi mật khẩu')) {
    return 'Server error while changing password';
  }
  if (lower.contains('đổi mật khẩu thất bại')) {
    return 'Password change failed';
  }

  final stillContainsVietnamese = RegExp(r'[\u00C0-\u1EF9]').hasMatch(message);
  if (stillContainsVietnamese) {
    return 'Unable to change password. Please try again.';
  }

  return message;
}

class StoreProfileScreen extends StatefulWidget {
  const StoreProfileScreen({super.key});
  @override
  State<StoreProfileScreen> createState() => _StoreProfileScreenState();
}

class _StoreProfileScreenState extends State<StoreProfileScreen> {
  @override
  void initState() {
    super.initState();
    context.read<StoreDashboardBloc>().add(LoadStoreDashboard());
  }

  Future<void> _openEditPage(StoreModel store) async {
    final result = await Navigator.push<StoreProfileEditResult>(
      context,
      MaterialPageRoute(
        builder: (_) => StoreProfileEditScreen(store: store),
      ),
    );

    if (!mounted || result == null || store.id == null) return;

    context.read<StoreDashboardBloc>().add(
          UpdateStoreProfileEvent(
            storeId: store.id!,
            storeName: result.storeName,
            address: result.address,
            imageUrl: result.imageUrl,
          ),
        );
  }

  String _languageLabel(StoreLanguagePreference preference) {
    switch (preference) {
      case StoreLanguagePreference.vietnamese:
        return _tr(context, vi: 'Tiếng Việt', en: 'Vietnamese');
      case StoreLanguagePreference.english:
        return 'English';
      case StoreLanguagePreference.system:
        return _tr(context, vi: 'Theo hệ thống', en: 'System default');
    }
  }

  String _themeLabel(StoreThemePreference preference) {
    switch (preference) {
      case StoreThemePreference.light:
        return _tr(context, vi: 'Sáng', en: 'Light');
      case StoreThemePreference.dark:
        return _tr(context, vi: 'Tối', en: 'Dark');
      case StoreThemePreference.system:
        return _tr(context, vi: 'Theo hệ thống', en: 'System default');
    }
  }

  Future<void> _openLanguageSelector() async {
    final selected = await showModalBottomSheet<StoreLanguagePreference>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final current =
            sheetContext.watch<StoreLanguageCubit>().state.preference;
        return SafeArea(
          top: false,
          left: false,
          right: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  _tr(context, vi: 'Chọn ngôn ngữ', en: 'Choose language'),
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              RadioGroup<StoreLanguagePreference>(
                groupValue: current,
                onChanged: (value) {
                  if (value == null) return;
                  Navigator.of(sheetContext).pop(value);
                },
                child: Column(
                  children: [
                    RadioListTile<StoreLanguagePreference>(
                      value: StoreLanguagePreference.vietnamese,
                      title: Text(
                        _tr(context, vi: 'Tiếng Việt', en: 'Vietnamese'),
                      ),
                    ),
                    const RadioListTile<StoreLanguagePreference>(
                      value: StoreLanguagePreference.english,
                      title: Text('English'),
                    ),
                    RadioListTile<StoreLanguagePreference>(
                      value: StoreLanguagePreference.system,
                      title: Text(
                        _tr(context, vi: 'Theo hệ thống', en: 'System default'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (selected != null && mounted) {
      await context.read<StoreLanguageCubit>().setLanguagePreference(selected);
    }
  }

  Future<void> _openThemeSelector() async {
    final selected = await showModalBottomSheet<StoreThemePreference>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final current = sheetContext.watch<StoreThemeCubit>().state.preference;
        return SafeArea(
          top: false,
          left: false,
          right: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  _tr(context, vi: 'Chọn chủ đề', en: 'Choose theme'),
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              RadioGroup<StoreThemePreference>(
                groupValue: current,
                onChanged: (value) {
                  if (value == null) return;
                  Navigator.of(sheetContext).pop(value);
                },
                child: Column(
                  children: [
                    RadioListTile<StoreThemePreference>(
                      value: StoreThemePreference.light,
                      title: Text(_tr(context, vi: 'Sáng', en: 'Light')),
                    ),
                    RadioListTile<StoreThemePreference>(
                      value: StoreThemePreference.dark,
                      title: Text(_tr(context, vi: 'Tối', en: 'Dark')),
                    ),
                    RadioListTile<StoreThemePreference>(
                      value: StoreThemePreference.system,
                      title: Text(
                        _tr(context, vi: 'Theo hệ thống', en: 'System default'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (selected != null && mounted) {
      await context.read<StoreThemeCubit>().setThemePreference(selected);
    }
  }

  Future<void> _openChangePasswordPage() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const _ChangePasswordPage()),
    );

    if (changed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _tr(
              context,
              vi: 'Đổi mật khẩu thành công',
              en: 'Password changed successfully',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(
          title: Text(_tr(context, vi: 'Cửa hàng', en: 'Store')),
          backgroundColor: StoreTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: const [
            NotificationIconButton(color: Colors.white),
          ]),
      body: BlocBuilder<StoreDashboardBloc, StoreDashboardState>(
        builder: (context, state) {
          if (state is StoreDashboardLoading)
            return const Center(child: CircularProgressIndicator());
          if (state is StoreDashboardError)
            return Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(state.message),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context
                        .read<StoreDashboardBloc>()
                        .add(LoadStoreDashboard());
                  },
                  child: Text(_tr(context, vi: 'Thử lại', en: 'Retry')),
                ),
              ],
            ));
          if (state is StoreDashboardLoaded) {
            final store = state.store;
            final languagePreference =
                context.watch<StoreLanguageCubit>().state.preference;
            final themePreference =
                context.watch<StoreThemeCubit>().state.preference;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StoreHeader(
                    store: store,
                    onEdit: () => _openEditPage(store),
                  ),
                  const SizedBox(height: 16),
                  _QuickPreferencesSection(
                    languageLabel: _languageLabel(languagePreference),
                    themeLabel: _themeLabel(themePreference),
                    languageTitle:
                      _tr(context, vi: 'Ngôn ngữ', en: 'Language'),
                    themeTitle: _tr(context, vi: 'Chủ đề', en: 'Theme'),
                    changePasswordTitle:
                      _tr(context, vi: 'Đổi mật khẩu', en: 'Change password'),
                    securityLabel:
                      _tr(context, vi: 'Cập nhật bảo mật', en: 'Security settings'),
                    onLanguageTap: _openLanguageSelector,
                    onThemeTap: _openThemeSelector,
                    onChangePasswordTap: _openChangePasswordPage,
                  ),
                  const SizedBox(height: 16),
                  _StoreSettings(store: store),
                  const SizedBox(height: 24),
                  _LogoutButton(),
                ],
              ),
            );
          }
          return Center(
            child: Text(_tr(context, vi: 'Lỗi tải dữ liệu', en: 'Failed to load data')),
          );
        },
      ),
    );
  }
}

class _QuickPreferencesSection extends StatelessWidget {
  final String languageLabel;
  final String themeLabel;
  final String languageTitle;
  final String themeTitle;
  final String changePasswordTitle;
  final String securityLabel;
  final VoidCallback onLanguageTap;
  final VoidCallback onThemeTap;
  final VoidCallback onChangePasswordTap;

  const _QuickPreferencesSection({
    required this.languageLabel,
    required this.themeLabel,
    required this.languageTitle,
    required this.themeTitle,
    required this.changePasswordTitle,
    required this.securityLabel,
    required this.onLanguageTap,
    required this.onThemeTap,
    required this.onChangePasswordTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
        children: [
          _ActionSettingsTile(
            icon: Icons.language,
            title: languageTitle,
            value: languageLabel,
            onTap: onLanguageTap,
          ),
          const Divider(height: 1),
          _ActionSettingsTile(
            icon: Icons.palette_outlined,
            title: themeTitle,
            value: themeLabel,
            onTap: onThemeTap,
          ),
          const Divider(height: 1),
          _ActionSettingsTile(
            icon: Icons.lock_reset,
            title: changePasswordTitle,
            value: securityLabel,
            onTap: onChangePasswordTap,
          ),
        ],
      ),
    );
  }
}

class _ActionSettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  const _ActionSettingsTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: StoreTheme.primaryColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: StoreTheme.primaryColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(value),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

class _StoreHeader extends StatelessWidget {
  final StoreModel store;
  final VoidCallback onEdit;
  const _StoreHeader({required this.store, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final isOpen = store.isOpen == true;
    final hasImage =
      store.imageUrl != null && store.imageUrl!.trim().isNotEmpty;
    final imageUrl = hasImage
      ? '${store.imageUrl}${store.imageUrl!.contains('?') ? '&' : '?'}t=${Uri.encodeComponent(store.updatedAt ?? DateTime.now().millisecondsSinceEpoch.toString())}'
      : null;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ]),
      child: Row(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.store,
                        size: 34,
                        color: StoreTheme.primaryColor,
                      ),
                    )
                  : const Icon(
                      Icons.store,
                      size: 34,
                      color: StoreTheme.primaryColor,
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.storeName ?? _tr(context, vi: 'Cửa hàng', en: 'Store'),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isOpen
                        ? StoreTheme.primaryColor.withValues(alpha: 0.12)
                        : Colors.grey.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isOpen
                        ? _tr(context, vi: 'Đang mở cửa', en: 'Open now')
                        : _tr(context, vi: 'Đã đóng cửa', en: 'Closed'),
                    style: TextStyle(
                      color: isOpen ? StoreTheme.primaryColor : Colors.grey[700],
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 16),
                  label: Text(_tr(context, vi: 'Chỉnh sửa', en: 'Edit')),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(120, 38),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreSettings extends StatelessWidget {
  final StoreModel store;
  const _StoreSettings({required this.store});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(_tr(context, vi: 'Thông tin cửa hàng', en: 'Store information'),
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
          ),
          _SettingsTile(
            icon: Icons.location_on,
            title: _tr(context, vi: 'Địa chỉ', en: 'Address'),
            value: store.address ?? _tr(context, vi: 'Chưa cập nhật', en: 'Not updated'),
          ),
          const Divider(height: 1),
          _SettingsTile(
            icon: Icons.phone,
            title: _tr(context, vi: 'Số điện thoại', en: 'Phone number'),
            value: store.ownerPhone ??
                store.phoneNumber ??
                _tr(context, vi: 'Chưa cập nhật', en: 'Not updated'),
          ),
          const Divider(height: 1),
          _SettingsTile(
            icon: Icons.person,
            title: _tr(context, vi: 'Chủ cửa hàng', en: 'Owner'),
            value: store.ownerName ?? _tr(context, vi: 'Chưa cập nhật', en: 'Not updated'),
          ),
          const Divider(height: 1),
          _SettingsTile(
            icon: Icons.calendar_today,
            title: _tr(context, vi: 'Ngày tạo', en: 'Created date'),
            value: _formatDate(store.createdAt),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '—';
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return dateStr;
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _SettingsTile(
      {required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: StoreTheme.primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: StoreTheme.primaryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF7A818C))),
                const SizedBox(height: 3),
                Text(value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => context.read<AuthBloc>().add(const LogoutRequested()),
        icon: const Icon(Icons.logout, color: Colors.red),
        label: Text(_tr(context, vi: 'Đăng xuất', en: 'Logout'),
          style: const TextStyle(color: Colors.red)),
        style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.red),
            backgroundColor: Theme.of(context)
                .colorScheme
                .errorContainer
                .withValues(alpha: 0.25),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(16)),
      ),
    );
  }
}

class _ChangePasswordPage extends StatefulWidget {
  const _ChangePasswordPage();

  @override
  State<_ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<_ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSubmitting = false;
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _error;

  void _onFieldChanged(String _) {
    if (_error != null) {
      setState(() {
        _error = null;
      });
    }
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await context.read<AuthRepository>().changePassword(
            oldPassword: _oldPasswordController.text.trim(),
            newPassword: _newPasswordController.text.trim(),
            confirmPassword: _confirmPasswordController.text.trim(),
          );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _localizeChangePasswordError(context, e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  InputDecoration _passwordDecoration(
      String label, bool obscure, VoidCallback onToggle) {
    return InputDecoration(
      labelText: label,
      suffixIcon: IconButton(
        icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
        onPressed: onToggle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tr(context, vi: 'Đổi mật khẩu', en: 'Change password')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _oldPasswordController,
                  onChanged: _onFieldChanged,
                  obscureText: _obscureOld,
                  decoration: _passwordDecoration(
                    _tr(context, vi: 'Mật khẩu hiện tại', en: 'Current password'),
                    _obscureOld,
                    () => setState(() => _obscureOld = !_obscureOld),
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return _tr(
                        context,
                        vi: 'Vui lòng nhập mật khẩu hiện tại',
                        en: 'Please enter current password',
                      );
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _newPasswordController,
                  onChanged: _onFieldChanged,
                  obscureText: _obscureNew,
                  decoration: _passwordDecoration(
                    _tr(context, vi: 'Mật khẩu mới', en: 'New password'),
                    _obscureNew,
                    () => setState(() => _obscureNew = !_obscureNew),
                  ),
                  validator: (value) {
                    final text = (value ?? '').trim();
                    if (text.isEmpty) {
                      return _tr(
                        context,
                        vi: 'Vui lòng nhập mật khẩu mới',
                        en: 'Please enter new password',
                      );
                    }
                    if (text.length < 6) {
                      return _tr(
                        context,
                        vi: 'Mật khẩu mới phải ít nhất 6 ký tự',
                        en: 'New password must be at least 6 characters',
                      );
                    }
                    if (text == _oldPasswordController.text.trim()) {
                      return _tr(
                        context,
                        vi: 'Mật khẩu mới không được trùng với mật khẩu cũ',
                        en: 'New password must not be the same as old password',
                      );
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmPasswordController,
                  onChanged: _onFieldChanged,
                  obscureText: _obscureConfirm,
                  decoration: _passwordDecoration(
                    _tr(
                      context,
                      vi: 'Xác nhận mật khẩu mới',
                      en: 'Confirm new password',
                    ),
                    _obscureConfirm,
                    () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  validator: (value) {
                    final text = (value ?? '').trim();
                    if (text.isEmpty) {
                      return _tr(
                        context,
                        vi: 'Vui lòng nhập lại mật khẩu mới',
                        en: 'Please confirm new password',
                      );
                    }
                    if (text != _newPasswordController.text.trim()) {
                      return _tr(
                        context,
                        vi: 'Xác nhận mật khẩu không khớp',
                        en: 'Password confirmation does not match',
                      );
                    }
                    return null;
                  },
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _tr(
                              context,
                              vi: 'Đổi mật khẩu',
                              en: 'Change password',
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
