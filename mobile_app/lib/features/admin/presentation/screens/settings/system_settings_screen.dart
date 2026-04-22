import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  // Mock config state
  String _selectedLanguage = 'Tiếng Việt';
  bool _pushEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString('language') ?? 'Tiếng Việt';
      _pushEnabled = prefs.getBool('push_enabled') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', _selectedLanguage);
    await prefs.setBool('push_enabled', _pushEnabled);
  }

  void _showMockDialog(BuildContext context, String title, Widget content, {VoidCallback? onConfirm}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: content,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
          if (onConfirm != null)
            ElevatedButton(
              onPressed: () {
                onConfirm();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã cập nhật hệ thống!')));
              },
              child: const Text('Lưu thay đổi'),
            ),
        ],
      )
    );
  }

  void _handleTap(String id) {
    switch (id) {
      case 'role':
        _showMockDialog(
          context, 
          'Quản lý phân quyền', 
          const Text('Cấu hình chi tiết phân quyền cho Customer, Store, Shipper, Admin.\n(Chức năng đang được tích hợp vào Database).'),
        );
        break;
      case 'api':
        _showMockDialog(
          context,
          'Quản lý API Keys',
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Production Key'),
                subtitle: const Text('sk_live_123***890'),
                trailing: IconButton(icon: const Icon(Icons.copy), onPressed: () {}),
              ),
              ListTile(
                title: const Text('Test Key'),
                subtitle: const Text('sk_test_abc***xyz'),
                trailing: IconButton(icon: const Icon(Icons.copy), onPressed: () {}),
              ),
            ],
          ),
        );
        break;
      case 'theme':
        _showMockDialog(
          context,
          'Tùy chỉnh Giao diện',
          const Text('Lựa chọn bảng màu chủ đạo cho Admin Panel (Hiện tại mặc định: Tím DeepPurple).'),
          onConfirm: () {},
        );
        break;
      case 'push':
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Thông báo Firebase'),
            content: StatefulBuilder(
              builder: (context, setStateBuilder) {
                return SwitchListTile(
                  title: const Text('Bật thông báo Push'),
                  value: _pushEnabled,
                  onChanged: (val) {
                    setStateBuilder(() => _pushEnabled = val);
                  },
                );
              }
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
              ElevatedButton(
                onPressed: () async {
                  setState(() {});
                  await _saveSettings();
                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu cấu hình Push!')));
                  }
                },
                child: const Text('Lưu'),
              ),
            ],
          )
        );
        break;
      case 'language':
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Ngôn ngữ'),
            content: StatefulBuilder(
              builder: (context, setStateBuilder) {
                return RadioGroup<String>(
                  groupValue: _selectedLanguage,
                  onChanged: (val) {
                    if (val != null) {
                      setStateBuilder(() => _selectedLanguage = val);
                    }
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      RadioListTile<String>(
                        title: Text('Tiếng Việt'),
                        value: 'Tiếng Việt',
                      ),
                      RadioListTile<String>(
                        title: Text('English'),
                        value: 'English',
                      ),
                    ],
                  ),
                );
              }
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
              ElevatedButton(
                onPressed: () async {
                  setState(() {});
                  await _saveSettings();
                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã đổi ngôn ngữ sang $_selectedLanguage')));
                  }
                },
                child: const Text('Lưu'),
              ),
            ],
          )
        );
        break;
      case 'backup':
        _showMockDialog(
          context,
          'Sao lưu Dữ liệu',
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Đang nén cơ sở dữ liệu lên Cloud...'),
            ],
          ),
        );
        // Simulate backup success after delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context); // close dialog
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sao lưu hoàn tất!')));
          }
        });
        break;
      case 'update':
        _showMockDialog(
          context,
          'Cập nhật hệ thống',
          const Text('Phiên bản hiện tại v1.0.0 (Bản mới nhất). Không có bản cập nhật nào mới.'),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Cài đặt hệ thống'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSettingsSection(
            'Bảo mật & Phân quyền',
            [
              _buildSettingTile(Icons.security, 'Quản lý Role', 'Cấu hình quyền cho các vai trò', () => _handleTap('role')),
              _buildSettingTile(Icons.api, 'Quản lý API Keys', 'Tạo và thu hồi API keys', () => _handleTap('api')),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingsSection(
            'Cấu hình ứng dụng',
            [
              _buildSettingTile(Icons.color_lens, 'Giao diện', 'Tùy chỉnh màu sắc, theme', () => _handleTap('theme')),
              _buildSettingTile(Icons.notifications_active, 'Thông báo Push', 'Firebase FCM ($_pushEnabled)', () => _handleTap('push')),
              _buildSettingTile(Icons.language, 'Ngôn ngữ', _selectedLanguage, () => _handleTap('language')),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingsSection(
            'Hệ thống',
            [
              _buildSettingTile(Icons.storage, 'Sao lưu dữ liệu', 'Backup database định kỳ', () => _handleTap('backup')),
              _buildSettingTile(Icons.update, 'Cập nhật hệ thống', 'Phiên bản hiện tại: v1.0.0', () => _handleTap('update')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  const Divider(height: 1, indent: 56),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.blue[700]),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 13)),
      trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Theme.of(context).disabledColor),
      onTap: onTap,
    );
  }
}
