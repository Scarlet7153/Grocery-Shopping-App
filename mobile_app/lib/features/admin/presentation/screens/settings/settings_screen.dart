import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../auth/bloc/auth_bloc.dart';
import '../../../../auth/bloc/auth_event.dart';
import '../../../../auth/bloc/auth_state.dart';
import '../../../../../core/utils/app_localizations.dart';
import '../../../bloc/settings_bloc.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  
  // Controllers for Profile
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  
  // Controllers for Password
  final TextEditingController _oldPassController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    _nameController = TextEditingController(
      text: authState is AuthAuthenticated ? authState.user.fullName : '',
    );
    _addressController = TextEditingController(
      text: authState is AuthAuthenticated ? authState.user.address ?? '' : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _oldPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settingsState) {
        final isDarkMode = settingsState.themeMode == ThemeMode.dark;
        final selectedLanguage = settingsState.locale.languageCode == 'vi' ? 'Tiếng Việt' : 'English';

        return BlocListener<AuthBloc, AuthState>(
          listener: (context, authState) {
            if (authState is AuthAuthenticated && context.mounted) {
              // Sync controllers if user data changed
              _nameController.text = authState.user.fullName;
              _addressController.text = authState.user.address ?? '';
            }
            if (authState is AuthPasswordResetSent) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(authState.message), backgroundColor: Colors.green),
              );
            }
            if (authState is AuthPasswordResetError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(authState.message), backgroundColor: Colors.red),
              );
            }
            if (authState is AuthProfileUpdateError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(authState.message), backgroundColor: Colors.red),
              );
            }
          },
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
            String userName = 'Admin';
            String userPhone = '0987654321';
            String? avatarUrl;
            
            if (authState is AuthAuthenticated) {
              userName = authState.user.fullName;
              userPhone = authState.user.phoneNumber.isNotEmpty ? authState.user.phoneNumber : 'N/A';
              avatarUrl = authState.user.avatarUrl;
            }

            return Scaffold(
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
              appBar: AppBar(
                title: Text(l.translate('settings_title'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
                foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
                elevation: 0.5,
                centerTitle: true,
              ),
              body: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _buildProfileHeader(context, userName, userPhone, avatarUrl),
                    const SizedBox(height: 8),
                    _buildSettingsSection(context, l.translate('settings_account'), [
                      _SettingsItem(
                        icon: Icons.person_outline,
                        color: Colors.blue,
                        title: l.translate('settings_personal'),
                        subtitle: 'Họ tên, số điện thoại, vai trò',
                        onTap: () => _showEditProfile(context, userName),
                      ),
                      _SettingsItem(
                        icon: Icons.lock_outline,
                        color: Colors.orange,
                        title: l.translate('settings_security'),
                        subtitle: 'Thay đổi mã PIN hoặc mật khẩu',
                        onTap: () => _showChangePassword(context),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    _buildSettingsSection(context, l.translate('settings_customization'), [
                      _SettingsItem(
                        icon: Icons.notifications_none_outlined,
                        color: Colors.purple,
                        title: l.translate('settings_notifications'),
                        subtitle: 'Quản lý thông báo đơn hàng mới',
                          trailing: Switch(
                          value: _notificationsEnabled,
                          onChanged: (v) => setState(() => _notificationsEnabled = v),
                          activeThumbColor: Colors.indigo,
                        ),
                      ),
                      _SettingsItem(
                        icon: Icons.palette_outlined,
                        color: Colors.teal,
                        title: l.translate('settings_dark_mode'),
                        subtitle: isDarkMode ? l.translate('dark_mode_on') : l.translate('dark_mode_off'),
                        trailing: Switch(
                          value: isDarkMode,
                          onChanged: (v) => context.read<SettingsBloc>().add(ThemeChanged(v)),
                          activeThumbColor: Colors.teal,
                        ),
                      ),
                      _SettingsItem(
                        icon: Icons.language_outlined,
                        color: Colors.blueGrey,
                        title: l.translate('settings_language'),
                        subtitle: selectedLanguage,
                        onTap: () => _showLanguagePicker(context, settingsState.locale.languageCode),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    _buildSettingsSection(context, l.translate('settings_support'), [
                      _SettingsItem(
                        icon: Icons.info_outline,
                        color: Colors.indigo,
                        title: l.translate('settings_about'),
                        onTap: () => _showAboutDialog(context),
                      ),
                      _SettingsItem(
                        icon: Icons.description_outlined,
                        color: Colors.green,
                        title: 'Điều khoản & Quy định',
                        onTap: () {},
                      ),
                      _SettingsItem(
                        icon: Icons.bug_report_outlined,
                        color: Colors.red,
                        title: 'Báo cáo sự cố kỹ thuật',
                        onTap: () {},
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildLogoutButton(context, l.translate('settings_logout')),
                    const SizedBox(height: 16),
                    Text('Admin Dashboard v3.1.5-final', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            );
          },
        ),
      );
    },
  );
}

  void _showEditProfile(BuildContext context, String currentName) {
    final l = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.translate('edit_profile'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l.translate('full_name'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Địa chỉ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Họ tên không được để trống')));
                  return;
                }
                context.read<AuthBloc>().add(ProfileUpdateRequested(userData: {
                  'fullName': _nameController.text.trim(),
                  'address': _addressController.text.trim(),
                }));
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(l.translate('save_changes'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePassword(BuildContext context) {
    _oldPassController.clear();
    _newPassController.clear();
    _confirmPassController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Đổi mật khẩu', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _oldPassController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu cũ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.lock_open),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _newPassController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu mới',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPassController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Xác nhận mật khẩu',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.check_circle_outline),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('HỦY', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              final oldP = _oldPassController.text;
              final newP = _newPassController.text;
              final confirmP = _confirmPassController.text;

              if (oldP.isEmpty || newP.isEmpty || confirmP.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')));
                return;
              }
              if (newP != confirmP) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mật khẩu xác nhận không khớp')));
                return;
              }
              if (newP.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mật khẩu mới phải có ít nhất 6 ký tự')));
                return;
              }

              context.read<AuthBloc>().add(ChangePasswordRequested(
                oldPassword: oldP,
                newPassword: newP,
                confirmPassword: confirmP,
              ));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('THAY ĐỔI', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, String currentCode) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Tiếng Việt'),
              trailing: currentCode == 'vi' ? const Icon(Icons.check, color: Colors.indigo) : null,
              onTap: () {
                context.read<SettingsBloc>().add(LanguageChanged('vi'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('English'),
              trailing: currentCode == 'en' ? const Icon(Icons.check, color: Colors.indigo) : null,
              onTap: () {
                context.read<SettingsBloc>().add(LanguageChanged('en'));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Grocery Admin',
      applicationVersion: '3.1.5',
      applicationIcon: const Icon(Icons.shopping_basket, size: 48, color: Colors.indigo),
      children: [
        const Text('Ứng dụng quản trị hệ thống đi chợ hộ.\nPhát triển bởi Đội ngũ kỹ thuật DACN 2024.'),
      ],
    );
  }

  Widget _buildProfileHeader(BuildContext context, String name, String phone, String? avatarUrl) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Row(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              gradient: avatarUrl == null || avatarUrl.isEmpty 
                  ? LinearGradient(colors: [Colors.indigo[400]!, Colors.indigo[700]!])
                  : null,
              borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: Colors.indigo.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))],
              image: avatarUrl != null && avatarUrl.isNotEmpty
                  ? DecorationImage(image: NetworkImage(avatarUrl), fit: BoxFit.cover)
                  : null,
            ),
            child: (avatarUrl == null || avatarUrl.isEmpty)
                ? Center(
                    child: Text(name.characters.first.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(phone, style: TextStyle(fontSize: 13, color: Colors.grey[600], letterSpacing: 0.5)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(color: Colors.indigo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Text('Administrators', style: TextStyle(color: Colors.indigo, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ),
              ],
            ),
          ),
          IconButton(onPressed: () {}, icon: Icon(Icons.qr_code_scanner, color: Colors.grey[400])),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context, String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[500], letterSpacing: 1.1)),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: List.generate(items.length, (index) {
              return Column(
                children: [
                  items[index],
                  if (index < items.length - 1) Divider(height: 1, indent: 64, color: Theme.of(context).dividerColor),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextButton(
        onPressed: () {
          context.read<AuthBloc>().add(const LogoutRequested());
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        },
        style: TextButton.styleFrom(
          foregroundColor: Colors.redAccent,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.red[100]!, width: 1)),
          backgroundColor: Colors.red[50]!.withValues(alpha: 0.3),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsItem({
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.only(left: 14, right: 10, top: 4, bottom: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: subtitle != null ? Text(subtitle!, style: TextStyle(fontSize: 11, color: Colors.grey[500])) : null,
      trailing: trailing ?? Icon(Icons.chevron_right, color: Colors.grey[300], size: 20),
      dense: true,
    );
  }
}
