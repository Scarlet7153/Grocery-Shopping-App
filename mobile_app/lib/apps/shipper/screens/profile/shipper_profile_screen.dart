import 'dart:async' show StreamSubscription, unawaited;
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grocery_shopping_app/core/utils/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/utils/image_picker_helper.dart';
import '../../bloc/shipper_auth_bloc.dart';
import '../../bloc/shipper_language_cubit.dart';
import '../../bloc/shipper_theme_cubit.dart';
import '../../repository/shipper_repository.dart';
import '../../services/shipper_realtime_stomp_service.dart';
import '../../../../core/location/province_api.dart';
import '../../../../core/theme/shipper_theme.dart';
import '../../../../shared/widgets/searchable_dropdown.dart';
import '../auth/shipper_login_screen.dart';
import '../../widgets/avatar_cropper.dart';

class ShipperProfileScreen extends StatefulWidget {
  const ShipperProfileScreen({super.key});

  @override
  State<ShipperProfileScreen> createState() => _ShipperProfileScreenState();
}

class _ShipperProfileScreenState extends State<ShipperProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _error;
  XFile? _pendingImage;
  Uint8List? _pendingImageBytes;
  Uint8List? _localAvatarPreviewBytes;
  StreamSubscription<ShipperRealtimeEvent>? _realtimeSubscription;
  final ShipperRealtimeStompService _realtimeService =
      ShipperRealtimeStompService();

  String _tr(String vi, String en) {
    final l = AppLocalizations.of(context);
    if (l == null) return vi;
    return l.byLocale(vi: vi, en: en);
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initRealtimeStreaming();
      }
    });
  }

  Future<void> _initRealtimeStreaming() async {
    _realtimeSubscription?.cancel();
    _realtimeSubscription = _realtimeService.events.listen((event) {
      switch (event.type) {
        case ShipperRealtimeEventType.profileUpdated:
          _applyRealtimeProfilePayload(event.payload);
          break;
        case ShipperRealtimeEventType.error:
          debugPrint('Profile STOMP error: ${event.message}');
          break;
        case ShipperRealtimeEventType.connected:
        case ShipperRealtimeEventType.disconnected:
        case ShipperRealtimeEventType.notificationReceived:
        case ShipperRealtimeEventType.notificationUnreadCountUpdated:
        case ShipperRealtimeEventType.orderCreated:
        case ShipperRealtimeEventType.orderAccepted:
        case ShipperRealtimeEventType.orderStatusChanged:
          break;
      }
    });

    await _realtimeService.connect();
  }

  void _applyRealtimeProfilePayload(Map<String, dynamic>? payload) {
    if (!mounted || payload == null) return;

    final eventUserId = _parseInt(payload['userId'] ?? payload['id']);
    final localUserId = _parseInt(_userData?['id']);

    if (eventUserId != null && localUserId != null && eventUserId != localUserId) {
      return;
    }

    if (_userData == null) {
      _loadUserData();
      return;
    }

    setState(() {
      _userData = {
        ...?_userData,
        'fullName': payload['fullName'] ?? _userData?['fullName'],
        'address': payload['address'] ?? _userData?['address'],
        'avatarUrl': payload['avatarUrl'] ?? _userData?['avatarUrl'],
      };
    });
  }

  int? _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final repository = context.read<ShipperRepository>();
      final data = await repository.getCurrentUser();
      if (mounted) {
        setState(() {
          _userData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(
          _tr('Cá nhân', 'Profile'),
          style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: Colors.white) ??
              const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
        ),
        centerTitle: true,
        backgroundColor: ShipperTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _buildProfileContent(),
    );
  }

  Widget _buildErrorState() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: colorScheme.error),
          const SizedBox(height: 16),
          Text(
            _tr('Không thể tải thông tin', 'Unable to load profile data'),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ) ??
                TextStyle(fontSize: 16, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadUserData,
            child: Text(_tr('Thử lại', 'Retry')),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    final name = _userData?['fullName'] ?? 'Shipper';
    final phone = _userData?['phoneNumber'] ?? '';
    final avatarUrl = _userData?['avatarUrl'];
    final address = _userData?['address'];
    final role = _userData?['role'] ?? 'SHIPPER';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildProfileHeader(name, phone, avatarUrl, role),
          const SizedBox(height: 24),
          _buildInfoCard(address),
          const SizedBox(height: 24),
          _buildSettingsCard(),
          const SizedBox(height: 32),
          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
    String name,
    String phone,
    String? avatarUrl,
    String role,
  ) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildAvatar(avatarUrl, name),
              const SizedBox(height: 20),
              Text(
                name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ) ??
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                phone,
                style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ) ??
                    TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: ShipperTheme.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: ShipperTheme.primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  role,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: ShipperTheme.primaryColor,
                            fontWeight: FontWeight.w700,
                          ) ??
                      const TextStyle(
                        color: ShipperTheme.primaryColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String? avatarUrl, String name) {
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final hasLocalAvatar = _localAvatarPreviewBytes != null;
    final hasRemoteAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
    final hasAvatar = hasLocalAvatar || hasRemoteAvatar;

    ImageProvider? avatarImage;
    if (hasLocalAvatar) {
      avatarImage = MemoryImage(_localAvatarPreviewBytes!);
    } else if (hasRemoteAvatar) {
      avatarImage = NetworkImage(avatarUrl);
    }

    return GestureDetector(
      onTap: _showImagePickerOptions,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: hasAvatar
              ? null
              : LinearGradient(
                  colors: [
                    ShipperTheme.primaryColor,
                    ShipperTheme.primaryColor.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          border: Border.all(
            color: surfaceColor,
            width: 4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
              spreadRadius: 2,
            ),
          ],
          image: hasAvatar
              ? DecorationImage(
                  image: avatarImage!,
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (!hasAvatar)
              Center(
                child: Text(
                  _getInitials(name),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.0),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ShipperTheme.primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: surfaceColor,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          top: false,
          left: false,
          right: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _tr('Thay đổi ảnh đại diện', 'Change avatar'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                _tr(
                  'Chọn ảnh từ thư viện hoặc chụp ảnh mới',
                  'Choose from gallery or take a new photo',
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPickerOption(
                    icon: Icons.camera_alt,
                    label: _tr('Chụp ảnh', 'Camera'),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  _buildPickerOption(
                    icon: Icons.photo_library,
                    label: _tr('Thư viện', 'Gallery'),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                  if (_userData?['avatarUrl'] != null)
                    _buildPickerOption(
                      icon: Icons.delete,
                      label: _tr('Xóa ảnh', 'Remove photo'),
                      color: Theme.of(context).colorScheme.error,
                      onTap: () {
                        Navigator.pop(context);
                        _removeAvatar();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _tr('Hủy', 'Cancel'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPickerOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color:
                  (color ?? ShipperTheme.primaryColor).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color ?? ShipperTheme.primaryColor,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color ?? Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      debugPrint('Picking image from: $source');

      final XFile? image = source == ImageSource.gallery
          ? await ImagePickerHelper.pickFromGallery(context)
          : await ImagePickerHelper.pickFromCamera(context);

      debugPrint('Picked image: ${image?.path}');

      if (image != null && mounted) {
        Uint8List? imageBytes;

        if (kIsWeb) {
          imageBytes = await image.readAsBytes();
          debugPrint('Web platform - Read ${imageBytes.length} bytes');
        } else {
          final file = File(image.path);
          final exists = await file.exists();
          if (!exists) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_tr('Không thể đọc file ảnh', 'Unable to read image file')),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
        }

        setState(() {
          _pendingImage = image;
          _pendingImageBytes = imageBytes;
        });

        await _showCropEditor();

        setState(() {
          _pendingImage = null;
          _pendingImageBytes = null;
        });
      } else {
        debugPrint('No image selected');
      }
    } catch (e, stackTrace) {
      debugPrint('Error picking image: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _error = '${_tr('Lỗi', 'Error')}: ${e.toString()}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_tr('Lỗi', 'Error')}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _pendingImage = null;
          _pendingImageBytes = null;
        });
      }
    }
  }

  /// Mở crop editor để căn chỉnh và upload ảnh đã crop
  Future<bool?> _showCropEditor() async {
    final image = _pendingImage;
    final imageBytes = _pendingImageBytes;

    if (image == null) return false;

    Uint8List? croppedBytes;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AvatarCropper(
        image: image,
        imageBytes: imageBytes,
        onConfirm: (bytes) {
          croppedBytes = bytes;
          Navigator.pop(ctx);
        },
        onCancel: () => Navigator.pop(ctx),
      ),
    );

    // Nếu có ảnh đã crop thì upload
    if (croppedBytes != null && mounted) {
      final uploadFilename = '${DateTime.now().millisecondsSinceEpoch}_avatar.jpg';
      unawaited(_uploadAvatarBytes(croppedBytes!, uploadFilename));
      return true;
    }

    return false;
  }

  /// Upload avatar bytes đã crop
  Future<void> _uploadAvatarBytes(Uint8List bytes, String filename) async {
    final previousPreview = _localAvatarPreviewBytes;
    setState(() {
      _localAvatarPreviewBytes = bytes;
      _error = null;
    });

    try {
      final imageUrl = await context
          .read<ShipperRepository>()
          .uploadAvatarBytes(bytes, filename);

      if (!mounted) return;

      if (imageUrl != null) {
        setState(() {
          _userData = {
            ...?_userData,
            'avatarUrl': imageUrl,
          };
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_tr('Cập nhật avatar thành công', 'Avatar updated successfully')),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _error = _tr('Upload avatar thất bại', 'Avatar upload failed');
          _localAvatarPreviewBytes = previousPreview;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_tr('Upload avatar thất bại', 'Avatar upload failed')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '${_tr('Lỗi', 'Error')}: ${e.toString()}';
          _localAvatarPreviewBytes = previousPreview;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_tr('Lỗi', 'Error')}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Xóa avatar
  Future<void> _removeAvatar() async {
    setState(() {
      _localAvatarPreviewBytes = null;
    });
    // TODO: Implement xóa avatar trên server
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_tr('Tính năng xóa avatar đang phát triển', 'Remove avatar is under development')),
      ),
    );
  }

  /// Lấy chữ cái đầu từ tên
  String _getInitials(String name) {
    if (name.isEmpty) return 'S';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Widget _buildInfoCard(String? address) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _tr('Thông tin cá nhân', 'Personal information'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ) ??
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 18),
            _buildInfoRow(
              Icons.phone,
              _tr('Số điện thoại', 'Phone number'),
              _userData?['phoneNumber'] ?? '',
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.location_on,
              _tr('Địa chỉ', 'Address'),
              address ?? _tr('Chưa cập nhật', 'Not updated yet'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard() {
    final languagePreference =
        context.watch<ShipperLanguageCubit>().state.preference;
    final themePreference = context.watch<ShipperThemeCubit>().state.preference;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Column(
        children: [
          _buildSettingTile(
            icon: Icons.language,
            title: _tr('Ngôn ngữ', 'Language'),
            subtitle: _languageLabel(languagePreference),
            onTap: _openLanguageSelector,
          ),
          Divider(
            height: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          _buildSettingTile(
            icon: Icons.brightness_6,
            title: _tr('Giao diện hệ thống', 'Appearance'),
            subtitle: _themeModeLabel(themePreference),
            onTap: _openThemeModeSelector,
          ),
          Divider(
            height: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          _buildSettingTile(
            icon: Icons.lock,
            title: _tr('Đổi mật khẩu', 'Change password'),
            onTap: _openChangePasswordPage,
          ),
          Divider(
            height: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          _buildSettingTile(
            icon: Icons.edit,
            title: _tr('Chỉnh sửa thông tin', 'Edit profile'),
            onTap: _openEditProfilePage,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Icon(icon, color: ShipperTheme.primaryColor, size: 24),
      title: Text(
        title,
        style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500) ??
            const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
      trailing: Icon(
        Icons.chevron_right,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        size: 24,
      ),
      onTap: onTap,
    );
  }

  String _themeModeLabel(ShipperThemePreference preference) {
    switch (preference) {
      case ShipperThemePreference.light:
        return _tr('Giao diện sáng', 'Light mode');
      case ShipperThemePreference.dark:
        return _tr('Giao diện tối', 'Dark mode');
      case ShipperThemePreference.system:
        return _tr('Tùy chỉnh theo hệ thống', 'System default');
    }
  }

  String _languageLabel(ShipperLanguagePreference preference) {
    switch (preference) {
      case ShipperLanguagePreference.vietnamese:
        return _tr('Tiếng Việt', 'Vietnamese');
      case ShipperLanguagePreference.english:
        return _tr('English', 'English');
      case ShipperLanguagePreference.system:
        return _tr('Theo hệ thống', 'System default');
    }
  }

  Future<void> _openLanguageSelector() async {
    final selected = await showModalBottomSheet<ShipperLanguagePreference>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      builder: (sheetContext) {
        final currentPreference =
            sheetContext.watch<ShipperLanguageCubit>().state.preference;

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(sheetContext).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                title: Text(
                  _tr('Chọn ngôn ngữ', 'Choose language'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              RadioGroup<ShipperLanguagePreference>(
                groupValue: currentPreference,
                onChanged: (value) {
                  Navigator.pop(sheetContext, value);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioListTile<ShipperLanguagePreference>(
                      value: ShipperLanguagePreference.vietnamese,
                      title: Text(_tr('Tiếng Việt', 'Vietnamese')),
                    ),
                    RadioListTile<ShipperLanguagePreference>(
                      value: ShipperLanguagePreference.english,
                      title: Text(_tr('English', 'English')),
                    ),
                    RadioListTile<ShipperLanguagePreference>(
                      value: ShipperLanguagePreference.system,
                      title: Text(_tr('Theo hệ thống', 'System default')),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );

    if (selected != null && mounted) {
      await context.read<ShipperLanguageCubit>().setLanguagePreference(selected);
    }
  }

  Future<void> _openThemeModeSelector() async {
    final selected = await showModalBottomSheet<ShipperThemePreference>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      builder: (sheetContext) {
        final currentPreference =
            sheetContext.watch<ShipperThemeCubit>().state.preference;

        return SafeArea(
          top: false,
          left: false,
          right: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(sheetContext).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                title: Text(
                  _tr('Chọn giao diện', 'Choose appearance'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              RadioGroup<ShipperThemePreference>(
                groupValue: currentPreference,
                onChanged: (value) {
                  Navigator.pop(sheetContext, value);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioListTile<ShipperThemePreference>(
                      value: ShipperThemePreference.light,
                      title: Text(_tr('Giao diện sáng', 'Light mode')),
                    ),
                    RadioListTile<ShipperThemePreference>(
                      value: ShipperThemePreference.dark,
                      title: Text(_tr('Giao diện tối', 'Dark mode')),
                    ),
                    RadioListTile<ShipperThemePreference>(
                      value: ShipperThemePreference.system,
                      title: Text(_tr('Tùy chỉnh theo hệ thống', 'System default')),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );

    if (selected != null && mounted) {
      await context.read<ShipperThemeCubit>().setThemePreference(selected);
    }
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _confirmLogout,
        icon: const Icon(Icons.logout, size: 22),
        label: Text(
          _tr('Đăng xuất', 'Logout'),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ) ??
              const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.error,
          foregroundColor: Theme.of(context).colorScheme.onError,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Icon(icon, size: 22, color: ShipperTheme.primaryColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ) ??
                    TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ) ??
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openChangePasswordPage() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const _ChangePasswordPage()),
    );

    if (changed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_tr('Đổi mật khẩu thành công', 'Password changed successfully')),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _openEditProfilePage() async {
    final updated = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => _EditProfilePage(userData: _userData),
      ),
    );

    if (updated != null && mounted) {
      setState(() {
        _userData = {
          ...?_userData,
          ...updated,
        };
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_tr('Cập nhật thành công', 'Profile updated successfully')),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_tr('Đăng xuất', 'Logout')),
        content: Text(_tr('Bạn có chắc chắn muốn đăng xuất?', 'Are you sure you want to logout?')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_tr('Hủy', 'Cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ShipperAuthBloc>().add(ShipperLogoutRequested());
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const ShipperLoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text(_tr('Đăng xuất', 'Logout')),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    _realtimeService.dispose();
    super.dispose();
  }
}

class _ChangePasswordPage extends StatefulWidget {
  const _ChangePasswordPage();

  @override
  State<_ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<_ChangePasswordPage> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  String _tr(String vi, String en) {
    final l = AppLocalizations.of(context);
    if (l == null) return vi;
    return l.byLocale(vi: vi, en: en);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(_tr('Đổi mật khẩu', 'Change password')),
        backgroundColor: ShipperTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: _oldPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: _tr('Mật khẩu cũ', 'Current password'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _newPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: _tr('Mật khẩu mới', 'New password'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: _tr('Xác nhận mật khẩu mới', 'Confirm new password'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleChangePassword,
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_tr('Đổi mật khẩu', 'Change password')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleChangePassword() async {
    final oldPassword = _oldPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      setState(() => _error = _tr('Vui lòng điền đầy đủ thông tin', 'Please fill in all required fields'));
      return;
    }
    if (newPassword.length < 6) {
      setState(() => _error = _tr('Mật khẩu mới phải có ít nhất 6 ký tự', 'New password must be at least 6 characters'));
      return;
    }
    if (oldPassword == newPassword) {
      setState(() => _error = _tr('Mật khẩu mới không được trùng mật khẩu cũ', 'New password must be different from current password'));
      return;
    }
    if (newPassword != confirmPassword) {
      setState(() => _error = _tr('Mật khẩu xác nhận không khớp', 'Password confirmation does not match'));
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final success = await context.read<ShipperRepository>().changePassword(
            oldPassword: oldPassword,
            newPassword: newPassword,
            confirmPassword: confirmPassword,
          );

      if (mounted) {
        if (success) {
          Navigator.pop(context, true);
        } else {
          setState(() => _error = _tr('Đổi mật khẩu thất bại', 'Password change failed'));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}

class _EditProfilePage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const _EditProfilePage({this.userData});

  @override
  State<_EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<_EditProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _streetController;
  final ProvinceApi _provinceApi = ProvinceApi();
  List<LocationItem> _provinces = [];
  List<LocationItem> _wards = [];
  LocationItem? _selectedProvince;
  LocationItem? _selectedWard;
  bool _isLoading = false;
  bool _isLoadingLocation = false;
  String? _error;
  String? _locationError;
  String? _initialProvinceName;
  String? _initialWardName;

  String _tr(String vi, String en) {
    final l = AppLocalizations.of(context);
    if (l == null) return vi;
    return l.byLocale(vi: vi, en: en);
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.userData?['fullName'] ?? '',
    );

    _prefillAddress(widget.userData?['address']?.toString());
    _loadProvinces();
  }

  void _prefillAddress(String? address) {
    _streetController = TextEditingController();

    if (address == null || address.trim().isEmpty) {
      return;
    }

    final parts = address
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    if (parts.length >= 3) {
      _initialProvinceName = parts.last;
      _initialWardName = parts[parts.length - 2];
      _streetController.text = parts.take(parts.length - 2).join(', ');
      return;
    }

    if (parts.length == 2) {
      _initialProvinceName = parts.last;
      _streetController.text = parts.first;
      return;
    }

    _streetController.text = address.trim();
  }

  String _normalizeLocationName(String value) {
    return value
        .toLowerCase()
        .replaceAll('thành phố', '')
        .replaceAll('tỉnh', '')
        .replaceAll('tp.', '')
        .replaceAll('tp', '')
        .replaceAll('quận', '')
        .replaceAll('huyện', '')
        .replaceAll('phường', '')
        .replaceAll('xã', '')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  LocationItem? _findByName(List<LocationItem> items, String? name) {
    if (name == null || name.trim().isEmpty) {
      return null;
    }

    final target = _normalizeLocationName(name);
    if (target.isEmpty) {
      return null;
    }

    for (final item in items) {
      final normalized = _normalizeLocationName(item.name);
      if (normalized == target || normalized.contains(target)) {
        return item;
      }
    }

    return null;
  }

  Future<void> _loadProvinces() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      final provinces = await _provinceApi.getProvincesV2();
      if (!mounted) {
        return;
      }

      final selectedProvince = _findByName(provinces, _initialProvinceName);

      setState(() {
        _provinces = provinces;
        _selectedProvince = selectedProvince;
      });

      if (selectedProvince != null) {
        await _loadWardsByProvince(
          selectedProvince,
          preserveInitialWard: true,
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _locationError = _tr(
          'Không thể tải danh sách tỉnh/phường',
          'Unable to load province/ward list',
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _loadWardsByProvince(
    LocationItem province, {
    bool preserveInitialWard = false,
  }) async {
    try {
      final wards = await _provinceApi.getWardsByProvince(province.code);
      if (!mounted) {
        return;
      }

      LocationItem? selectedWard;
      if (preserveInitialWard) {
        selectedWard = _findByName(wards, _initialWardName);
      } else if (_selectedWard != null) {
        final selectedCode = _selectedWard!.code;
        for (final item in wards) {
          if (item.code == selectedCode) {
            selectedWard = item;
            break;
          }
        }
      }

      setState(() {
        _wards = wards;
        _selectedWard = selectedWard;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _wards = [];
        _selectedWard = null;
        _locationError = _tr(
          'Không thể tải danh sách phường',
          'Unable to load ward list',
        );
      });
    }
  }

  Future<void> _onProvinceChanged(LocationItem? item) async {
    setState(() {
      _selectedProvince = item;
      _selectedWard = null;
      _wards = [];
      _locationError = null;
    });

    if (item == null) {
      return;
    }

    await _loadWardsByProvince(item);
  }

  void _onWardChanged(LocationItem? item) {
    setState(() {
      _selectedWard = item;
    });
  }

  Widget _buildLocationDropdown({
    required String label,
    required List<LocationItem> items,
    required ValueChanged<LocationItem?>? onChanged,
    LocationItem? value,
    String? hintText,
  }) {
    return SearchableDropdown<LocationItem>(
      label: label,
      items: items,
      selectedItem: value,
      displayStringForItem: (item) => item.name,
      onChanged: onChanged,
      hintText: hintText ?? label,
      searchHint: _tr('Tìm kiếm...', 'Search...'),
      emptyMessage: _tr('Không tìm thấy', 'No results found'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(_tr('Chỉnh sửa thông tin', 'Edit profile')),
        backgroundColor: ShipperTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: _tr('Họ và tên', 'Full name'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_isLoadingLocation)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: LinearProgressIndicator(minHeight: 3),
                        ),
                      _buildLocationDropdown(
                        label: _tr('Tỉnh/Thành phố', 'Province/City'),
                        value: _selectedProvince,
                        items: _provinces,
                        onChanged: _isLoadingLocation ? null : _onProvinceChanged,
                        hintText: _tr('Chọn tỉnh/thành phố', 'Select province/city'),
                      ),
                      const SizedBox(height: 12),
                      _buildLocationDropdown(
                        label: _tr('Phường/Xã', 'Ward/Commune'),
                        value: _selectedWard,
                        items: _wards,
                        onChanged: (_selectedProvince == null || _isLoadingLocation)
                            ? null
                            : _onWardChanged,
                        hintText: _tr('Chọn phường/xã', 'Select ward/commune'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _streetController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: _tr('Đường', 'Street'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      if (_locationError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _locationError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleUpdate,
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_tr('Cập nhật', 'Update')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleUpdate() async {
    final name = _nameController.text.trim();
    final street = _streetController.text.trim();

    if (name.isEmpty) {
      setState(() => _error = _tr('Vui lòng nhập họ tên', 'Please enter full name'));
      return;
    }

    if (_selectedProvince == null) {
      setState(() => _error = _tr('Vui lòng chọn tỉnh/thành phố', 'Please select province/city'));
      return;
    }

    if (_selectedWard == null) {
      setState(() => _error = _tr('Vui lòng chọn phường/xã', 'Please select ward/commune'));
      return;
    }

    if (street.isEmpty) {
      setState(() => _error = _tr('Vui lòng nhập đường', 'Please enter street'));
      return;
    }

    final address = '$street, ${_selectedWard!.name}, ${_selectedProvince!.name}';

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final updatedProfile = await context
          .read<ShipperRepository>()
          .updateProfile(fullName: name, address: address);

      if (mounted) {
        if (updatedProfile) {
          Navigator.pop(context, {
            'fullName': name,
            'address': address,
          });
        } else {
          setState(() => _error = _tr('Cập nhật thất bại', 'Update failed'));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _streetController.dispose();
    super.dispose();
  }
}
