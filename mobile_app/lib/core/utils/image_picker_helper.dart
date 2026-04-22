import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

/// Helper chọn ảnh với xin quyền runtime cho tất cả giao diện
class ImagePickerHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Chọn ảnh từ thư viện, tự động xin quyền nếu cần
  static Future<XFile?> pickFromGallery(BuildContext context) async {
    if (kIsWeb) {
      return await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
      );
    }

    // Android 13+ (API 33+) dùng Photo Picker API — không cần quyền
    // Android 12 trở xuống cần READ_EXTERNAL_STORAGE
    // iOS dùng Photo Library — cần NSPhotoLibraryUsageDescription
    if (Platform.isAndroid) {
      final status = await Permission.photos.request();
      if (status.isPermanentlyDenied) {
        _showSettingsDialog(context);
        return null;
      }
      if (status.isDenied) {
        return null;
      }
    }

    return await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
    );
  }

  /// Chụp ảnh từ camera, tự động xin quyền nếu cần
  static Future<XFile?> pickFromCamera(BuildContext context) async {
    if (kIsWeb) {
      return await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1024,
      );
    }

    final status = await Permission.camera.request();
    if (status.isPermanentlyDenied) {
      _showSettingsDialog(context);
      return null;
    }
    if (status.isDenied) {
      return null;
    }

    return await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1024,
    );
  }

  /// Chọn ảnh từ gallery HOẶC camera qua bottom sheet
  static Future<XFile?> pickImageWithChoice(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        top: false,
        left: false,
        right: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn từ thư viện'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Chụp ảnh'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return null;

    if (source == ImageSource.gallery) {
      return await pickFromGallery(context);
    } else {
      return await pickFromCamera(context);
    }
  }

  static void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cần quyền truy cập'),
        content: const Text(
          'Ứng dụng cần quyền truy cập thư viện ảnh/camera để chọn ảnh. Vui lòng bật quyền trong Cài đặt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('Mở Cài đặt'),
          ),
        ],
      ),
    );
  }
}
