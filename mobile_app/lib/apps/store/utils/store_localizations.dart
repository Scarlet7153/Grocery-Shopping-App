import 'package:flutter/material.dart';

/// Store App Localization Helper
/// Cách dùng: StoreLocalizations.of(context).tr('key') hoặc tr(context, vi: '', en: '')
class StoreLocalizations {
  final Locale locale;

  StoreLocalizations(this.locale);

  static StoreLocalizations of(BuildContext context) {
    return StoreLocalizations(Localizations.localeOf(context));
  }

  static final Map<String, Map<String, String>> _strings = {
    // Dashboard
    'dashboard_title': {'vi': 'Tổng quan', 'en': 'Dashboard'},
    'retry': {'vi': 'Thử lại', 'en': 'Retry'},
    'store': {'vi': 'Cửa hàng', 'en': 'Store'},
    'open_now': {'vi': 'Đang mở', 'en': 'Open now'},
    'closed': {'vi': 'Đã đóng', 'en': 'Closed'},
    'today_revenue': {'vi': 'Doanh thu hôm nay', 'en': "Today's Revenue"},
    'total_orders': {'vi': 'Tổng đơn', 'en': 'Total Orders'},
    'pending': {'vi': 'Chờ xác nhận', 'en': 'Pending'},
    'preparing': {'vi': 'Đang chuẩn bị', 'en': 'Preparing'},
    'delivering': {'vi': 'Đang giao', 'en': 'Delivering'},
    'recent_orders': {'vi': 'Đơn hàng gần đây', 'en': 'Recent Orders'},
    'view_all': {'vi': 'Xem tất cả', 'en': 'View all'},
    'confirmed': {'vi': 'Đã xác nhận', 'en': 'Confirmed'},
    'completed': {'vi': 'Hoàn thành', 'en': 'Completed'},
    'cancelled': {'vi': 'Đã hủy', 'en': 'Cancelled'},
    'all': {'vi': 'Tất cả', 'en': 'All'},

    // Orders
    'orders': {'vi': 'Đơn hàng', 'en': 'Orders'},
    'no_orders': {'vi': 'Chưa có đơn hàng nào', 'en': 'No orders yet'},
    'customer': {'vi': 'Khách hàng', 'en': 'Customer'},
    'cancel': {'vi': 'Hủy', 'en': 'Cancel'},
    'confirm': {'vi': 'Xác nhận', 'en': 'Confirm'},
    'cancel_order': {'vi': 'Hủy đơn', 'en': 'Cancel order'},
    'cancel_order_confirm': {
      'vi': 'Bạn có chắc muốn hủy đơn hàng này?',
      'en': 'Are you sure you want to cancel this order?'
    },
    'close': {'vi': 'Đóng', 'en': 'Close'},

    // Order Detail
    'order_number': {'vi': 'Đơn hàng', 'en': 'Order'},
    'customer_info': {
      'vi': 'Thông tin khách hàng',
      'en': 'Customer information'
    },
    'customer_name': {'vi': 'Tên khách hàng', 'en': 'Customer name'},
    'customer_phone': {'vi': 'Số điện thoại', 'en': 'Phone number'},
    'delivery_address': {'vi': 'Địa chỉ giao hàng', 'en': 'Delivery address'},
    'items': {'vi': 'Sản phẩm', 'en': 'Items'},
    'payment': {'vi': 'Thanh toán', 'en': 'Payment'},
    'subtotal': {'vi': 'Tạm tính', 'en': 'Subtotal'},
    'shipping_fee': {'vi': 'Phí vận chuyển', 'en': 'Shipping fee'},
    'total_amount': {'vi': 'Tổng cộng', 'en': 'Total amount'},
    'cod_payment': {'vi': 'Thanh toán khi nhận hàng', 'en': 'Cash on delivery'},
    'ordered_at': {'vi': 'Đặt lúc', 'en': 'Ordered at'},

    'order_confirmed': {'vi': 'Đã xác nhận đơn hàng', 'en': 'Order confirmed'},
    'order_preparing': {
      'vi': 'Đơn hàng đang được chuẩn bị',
      'en': 'Order is being prepared'
    },
    'order_delivering': {
      'vi': 'Đơn hàng đang giao',
      'en': 'Order is delivering'
    },
    'order_completed': {
      'vi': 'Đơn hàng đã hoàn thành',
      'en': 'Order completed'
    },
    'order_cancelled': {
      'vi': 'Đơn hàng đã bị hủy',
      'en': 'Order has been cancelled'
    },
    'status_updated': {
      'vi': 'Cập nhật trạng thái thành công',
      'en': 'Status updated successfully'
    },

    // Products
    'products': {'vi': 'Sản phẩm', 'en': 'Products'},
    'no_products': {'vi': 'Chưa có sản phẩm nào', 'en': 'No products yet'},
    'search_products': {
      'vi': 'Tìm kiếm sản phẩm...',
      'en': 'Search products...'
    },
    'add_product': {'vi': 'Thêm sản phẩm', 'en': 'Add product'},
    'edit_product': {'vi': 'Sửa sản phẩm', 'en': 'Edit product'},
    'product_name': {'vi': 'Tên sản phẩm', 'en': 'Product name'},
    'price': {'vi': 'Giá', 'en': 'Price'},
    'stock': {'vi': 'Tồn kho', 'en': 'Stock'},
    'category': {'vi': 'Danh mục', 'en': 'Category'},
    'description': {'vi': 'Mô tả', 'en': 'Description'},
    'unit': {'vi': 'Đơn vị', 'en': 'Unit'},
    'save': {'vi': 'Lưu', 'en': 'Save'},
    'delete': {'vi': 'Xóa', 'en': 'Delete'},
    'success': {'vi': 'thành công', 'en': 'successfully'},
    'add_product_success': {
      'vi': 'Thêm sản phẩm thành công',
      'en': 'Product added successfully'
    },
    'delete_product_success': {
      'vi': 'Xóa sản phẩm thành công',
      'en': 'Product deleted successfully'
    },
    'delete_product': {'vi': 'Xóa sản phẩm', 'en': 'Delete product'},
    'save_failed': {'vi': 'Lưu thất bại', 'en': 'Save failed'},
    'product': {'vi': 'Sản phẩm', 'en': 'Product'},
    'delete_confirm': {
      'vi': 'Bạn có chắc muốn xóa?',
      'en': 'Are you sure you want to delete?'
    },
    'available': {'vi': 'Còn hàng', 'en': 'Available'},
    'out_of_stock': {'vi': 'Hết hàng', 'en': 'Out of stock'},
    'hidden': {'vi': 'Đã ẩn', 'en': 'Hidden'},

    // Product Detail
    'product_detail': {'vi': 'Chi tiết sản phẩm', 'en': 'Product detail'},
    'delete_product_confirm': {
      'vi': 'Bạn có chắc muốn xóa sản phẩm này?',
      'en': 'Are you sure you want to delete this product?'
    },
    'product_units': {'vi': 'Các đơn vị bán', 'en': 'Product units'},
    'default': {'vi': 'Mặc định', 'en': 'Default'},
    'stock_count': {'vi': 'Tồn', 'en': 'Stock'},
    'add_unit': {'vi': 'Thêm đơn vị', 'en': 'Add unit'},
    'unit_label': {'vi': 'Nhãn hiển thị', 'en': 'Display label'},
    'standard_unit': {'vi': 'Đơn vị chuẩn', 'en': 'Standard unit'},
    'unit_size': {'vi': 'Độ lớn', 'en': 'Size'},
    'price_vnd': {'vi': 'Giá (VNĐ)', 'en': 'Price (VND)'},
    'quantity_stock': {'vi': 'Số lượng tồn', 'en': 'Stock quantity'},
    'change_image': {'vi': 'Đổi ảnh', 'en': 'Change image'},
    'saving': {'vi': 'Đang lưu...', 'en': 'Saving...'},
    'no_image': {'vi': 'Chưa có ảnh', 'en': 'No image'},
    'image_pick_error': {
      'vi': 'Không thể chọn ảnh, vui lòng thử lại',
      'en': 'Cannot select image, please try again'
    },
    'product_name_required': {
      'vi': 'Vui lòng nhập tên sản phẩm',
      'en': 'Please enter product name'
    },
    'invalid_price_variant': {
      'vi': 'Giá không hợp lệ ở biến thể #',
      'en': 'Invalid price at variant #'
    },
    'invalid_stock_variant': {
      'vi': 'Tồn kho không hợp lệ ở biến thể #',
      'en': 'Invalid stock at variant #'
    },
    'size_required_variant': {
      'vi': 'Vui lòng nhập độ lớn ở biến thể #',
      'en': 'Please enter size at variant #'
    },
    'label_required_variant': {
      'vi': 'Vui lòng nhập nhãn hiển thị ở biến thể #',
      'en': 'Please enter display label at variant #'
    },
    'at_least_one_variant': {
      'vi': 'Cần ít nhất một biến thể hợp lệ',
      'en': 'At least one valid variant required'
    },
    'update_failed': {'vi': 'Cập nhật thất bại', 'en': 'Update failed'},
    'add_variant': {'vi': 'Thêm biến thể', 'en': 'Add variant'},
    'select_category': {'vi': 'Chọn danh mục', 'en': 'Select category'},
    'product_name_required_field': {
      'vi': 'Tên sản phẩm *',
      'en': 'Product name *'
    },
    'description_label': {'vi': 'Mô tả', 'en': 'Description'},
    'sale_variants': {'vi': 'Biến thể bán', 'en': 'Sale variants'},
    'variant': {'vi': 'Biến thể', 'en': 'Variant'},
    'standard_unit_label': {'vi': 'Đơn vị chuẩn', 'en': 'Standard unit'},
    'enter_size_symbol': {'vi': 'Nhập độ lớn', 'en': 'Enter size'},
    'auto_label_prefix': {'vi': 'Nhãn tự tạo:', 'en': 'Auto label:'},
    'stock_required': {'vi': 'Tồn kho *', 'en': 'Stock *'},
    'save_changes': {'vi': 'Lưu thay đổi', 'en': 'Save changes'},

    // Reviews
    'reviews': {'vi': 'Đánh giá', 'en': 'Reviews'},
    'no_reviews': {'vi': 'Chưa có đánh giá nào', 'en': 'No reviews yet'},
    'rating_out_of': {'vi': '/ 5.0', 'en': '/ 5.0'},
    'total_reviews_count': {'vi': 'đánh giá', 'en': 'reviews'},
    'anonymous': {'vi': 'Ẩn danh', 'en': 'Anonymous'},

    // Profile
    'language': {'vi': 'Ngôn ngữ', 'en': 'Language'},
    'theme': {'vi': 'Chủ đề', 'en': 'Theme'},
    'change_password': {'vi': 'Đổi mật khẩu', 'en': 'Change password'},
    'security_settings': {'vi': 'Cập nhật bảo mật', 'en': 'Security settings'},
    'logout': {'vi': 'Đăng xuất', 'en': 'Logout'},
    'vietnamese': {'vi': 'Tiếng Việt', 'en': 'Vietnamese'},
    'english': {'vi': 'English', 'en': 'English'},
    'system_default': {'vi': 'Theo hệ thống', 'en': 'System default'},
    'light': {'vi': 'Sáng', 'en': 'Light'},
    'dark': {'vi': 'Tối', 'en': 'Dark'},
    'choose_language': {'vi': 'Chọn ngôn ngữ', 'en': 'Choose language'},
    'choose_theme': {'vi': 'Chọn chủ đề', 'en': 'Choose theme'},
    'address': {'vi': 'Địa chỉ', 'en': 'Address'},
    'phone_number': {'vi': 'Số điện thoại', 'en': 'Phone number'},
    'owner': {'vi': 'Chủ cửa hàng', 'en': 'Owner'},
    'created_date': {'vi': 'Ngày tạo', 'en': 'Created date'},
    'not_updated': {'vi': 'Chưa cập nhật', 'en': 'Not updated'},
    'store_info': {'vi': 'Thông tin cửa hàng', 'en': 'Store information'},
    'edit': {'vi': 'Chỉnh sửa', 'en': 'Edit'},
    'store_status': {'vi': 'Trạng thái cửa hàng', 'en': 'Store status'},
    'open': {'vi': 'Đang mở cửa', 'en': 'Open now'},
    'loading_error': {'vi': 'Lỗi tải dữ liệu', 'en': 'Failed to load data'},

    // Store Profile Edit
    'edit_store': {'vi': 'Chỉnh sửa cửa hàng', 'en': 'Edit store'},
    'store_information': {
      'vi': 'Thông tin cửa hàng',
      'en': 'Store information'
    },
    'store_name': {'vi': 'Tên cửa hàng', 'en': 'Store name'},
    'store_name_hint': {'vi': 'Nhập tên cửa hàng', 'en': 'Enter store name'},
    'store_name_required': {
      'vi': 'Vui lòng nhập tên cửa hàng',
      'en': 'Please enter store name'
    },
    'store_name_too_short': {
      'vi': 'Tên cửa hàng quá ngắn',
      'en': 'Store name too short'
    },
    'province_city': {'vi': 'Tỉnh/Thành phố', 'en': 'Province/City'},
    'province_required': {
      'vi': 'Vui lòng chọn Tỉnh/Thành phố',
      'en': 'Please select province'
    },
    'ward_district': {'vi': 'Phường/Xã', 'en': 'Ward/District'},
    'ward_required': {
      'vi': 'Vui lòng chọn Phường/Xã',
      'en': 'Please select ward'
    },
    'street': {'vi': 'Đường', 'en': 'Street'},
    'street_hint': {'vi': 'Ví dụ: 123 Lê Lợi', 'en': 'E.g., 123 Le Loi'},
    'street_required': {
      'vi': 'Vui lòng nhập tên đường',
      'en': 'Please enter street'
    },
    'street_too_short': {
      'vi': 'Tên đường quá ngắn',
      'en': 'Street name too short'
    },
    'load_province_error': {
      'vi': 'Không tải được danh sách Tỉnh/Thành phố',
      'en': 'Failed to load provinces'
    },
    'load_ward_error': {
      'vi': 'Không tải được danh sách Phường/Xã',
      'en': 'Failed to load wards'
    },

    // Store Auth
    'store_login_title': {'vi': 'Chào mừng\nChủ cửa hàng!', 'en': 'Welcome\nStore Owner!'},
    'store_login_subtitle': {
      'vi': 'Đăng nhập để quản lý cửa hàng',
      'en': 'Sign in to manage your store'
    },
    'store_no_permission': {
      'vi': 'Tài khoản không có quyền Chủ cửa hàng',
      'en': 'This account does not have Store Owner permission'
    },
    'store_no_account': {
      'vi': 'Chưa có tài khoản cửa hàng?',
      'en': 'Don\'t have a store account?'
    },
    'store_register_now': {'vi': 'Đăng ký ngay', 'en': 'Register now'},
    'sign_in': {'vi': 'Đăng nhập', 'en': 'Sign in'},
    'sign_up_store': {'vi': 'Đăng ký cửa hàng', 'en': 'Register store'},
    'full_name': {'vi': 'Họ và tên', 'en': 'Full name'},
    'full_name_hint': {'vi': 'Nhập họ và tên', 'en': 'Enter your full name'},
    'full_name_required': {
      'vi': 'Vui lòng nhập họ và tên',
      'en': 'Please enter your full name'
    },
    'full_name_too_short': {'vi': 'Họ và tên quá ngắn', 'en': 'Full name is too short'},
    'phone_hint': {'vi': 'Nhập số điện thoại', 'en': 'Enter phone number'},
    'phone_required': {'vi': 'Vui lòng nhập số điện thoại', 'en': 'Please enter phone number'},
    'phone_invalid': {'vi': 'Số điện thoại không hợp lệ', 'en': 'Invalid phone number'},
    'password': {'vi': 'Mật khẩu', 'en': 'Password'},
    'password_hint': {'vi': 'Nhập mật khẩu', 'en': 'Enter password'},
    'password_required': {'vi': 'Vui lòng nhập mật khẩu', 'en': 'Please enter password'},
    'password_min_6': {'vi': 'Mật khẩu tối thiểu 6 ký tự', 'en': 'Password must be at least 6 characters'},
    'confirm_password': {'vi': 'Nhập lại mật khẩu', 'en': 'Confirm password'},
    'confirm_password_hint': {'vi': 'Nhập lại mật khẩu', 'en': 'Re-enter password'},
    'confirm_password_required': {
      'vi': 'Vui lòng nhập lại mật khẩu',
      'en': 'Please confirm your password'
    },
    'confirm_password_mismatch': {
      'vi': 'Mật khẩu nhập lại không khớp',
      'en': 'Password confirmation does not match'
    },
    'store_register_title': {
      'vi': 'Tạo tài khoản chủ cửa hàng',
      'en': 'Create a store owner account'
    },
    'store_register_desc': {
      'vi': 'Sau khi đăng ký, tài khoản sẽ ở trạng thái chờ Admin phê duyệt trước khi đăng nhập.',
      'en': 'After registration, your account will be pending Admin approval before sign in.'
    },
    'login_failed_prefix': {'vi': 'Đăng nhập thất bại: ', 'en': 'Login failed: '},
    'register_failed_prefix': {'vi': 'Đăng ký thất bại: ', 'en': 'Registration failed: '},
    'store_pending_approval': {
      'vi': 'Tài khoản cửa hàng đang chờ Admin phê duyệt',
      'en': 'Store account is pending Admin approval'
    },
    'invalid_login_credentials': {
      'vi': 'Thông tin đăng nhập không hợp lệ (sai số điện thoại hoặc mật khẩu)',
      'en': 'Invalid login credentials (wrong phone number or password)'
    },
    'account_not_activated': {
      'vi': 'Tài khoản chưa được kích hoạt. Vui lòng liên hệ quản trị viên.',
      'en': 'Account is not activated. Please contact administrator.'
    },
    'account_blocked': {
      'vi': 'Tài khoản đã bị khóa. Vui lòng liên hệ quản trị viên.',
      'en': 'Account is blocked. Please contact administrator.'
    },
    'phone_not_registered': {
      'vi': 'Số điện thoại chưa được đăng ký',
      'en': 'Phone number is not registered'
    },
    'phone_used_prefix': {
      'vi': 'Số điện thoại ',
      'en': 'Phone number '
    },
    'phone_used_suffix': {'vi': ' đã được sử dụng', 'en': ' is already in use'},
    'phone_invalid_backend': {
      'vi': 'Số điện thoại không hợp lệ (phải có 10 chữ số, bắt đầu bằng 0)',
      'en': 'Invalid phone number (must be 10 digits and start with 0)'
    },
    'phone_empty_backend': {
      'vi': 'Số điện thoại không được để trống',
      'en': 'Phone number must not be empty'
    },
    'password_empty_backend': {
      'vi': 'Mật khẩu không được để trống',
      'en': 'Password must not be empty'
    },
    'password_min_6_backend': {
      'vi': 'Mật khẩu phải có ít nhất 6 ký tự',
      'en': 'Password must be at least 6 characters'
    },
    'general_server_error': {'vi': 'Lỗi máy chủ, vui lòng thử lại', 'en': 'Server error, please try again'},
    'auth_request_failed': {
      'vi': 'Yêu cầu xác thực thất bại. Vui lòng thử lại sau',
      'en': 'Authentication request failed. Please try again later'
    },
    'please_try_again_later': {'vi': 'Vui lòng thử lại sau', 'en': 'Please try again later'},
    'unknown_error': {'vi': 'Đã xảy ra lỗi không xác định', 'en': 'An unknown error occurred'},
    'store_name_example_hint': {'vi': 'Ví dụ: Tạp hóa Cô Ba', 'en': 'E.g. Co Ba Grocery'},
    'store_name_required_msg': {'vi': 'Vui lòng nhập tên cửa hàng', 'en': 'Please enter store name'},
    'store_name_too_short_msg': {'vi': 'Tên cửa hàng quá ngắn', 'en': 'Store name is too short'},
    'province_ward_required': {
      'vi': 'Vui lòng chọn đầy đủ Tỉnh/Thành phố và Phường/Xã',
      'en': 'Please select both Province/City and Ward/District'
    },
    'street_example_hint': {'vi': 'Ví dụ: 273 An Dương Vương', 'en': 'E.g. 273 An Duong Vuong'},

    // Bottom nav
    'dashboard': {'vi': 'Tổng quan', 'en': 'Dashboard'},

    // Status
    'pending_status': {'vi': 'Chờ xác nhận', 'en': 'Pending'},
    'confirmed_status': {'vi': 'Đã xác nhận', 'en': 'Confirmed'},
    'preparing_status': {'vi': 'Đang chuẩn bị', 'en': 'Preparing'},
    'delivering_status': {'vi': 'Đang giao', 'en': 'Delivering'},
    'completed_status': {'vi': 'Hoàn thành', 'en': 'Completed'},
    'cancelled_status': {'vi': 'Đã hủy', 'en': 'Cancelled'},
  };

  String tr(String key) {
    final lang = locale.languageCode;
    return _strings[key]?[lang] ?? _strings[key]?['vi'] ?? key;
  }
}

/// Extension để dùng dễ hơn
extension StoreLocalizationsExtension on BuildContext {
  StoreLocalizations get storeLoc => StoreLocalizations.of(this);
  String storeTr(String key) => StoreLocalizations.of(this).tr(key);
}

/// Helper function để dùng inline
String tr(BuildContext context, {required String vi, required String en}) {
  final locale = Localizations.localeOf(context);
  return locale.languageCode == 'vi' ? vi : en;
}

String localizeStoreAuthMessage(BuildContext context, String rawMessage) {
  final locale = Localizations.localeOf(context);
  if (locale.languageCode == 'vi') return rawMessage;

  var message = rawMessage.trim();
  final loc = StoreLocalizations.of(context);

  if (message.startsWith('Exception: ')) {
    message = message.substring(11).trim();
  }

  final lower = message.toLowerCase();

  final usedPhone = RegExp(r'Số điện thoại\s+(\d+)\s+đã được sử dụng').firstMatch(message);
  if (usedPhone != null) {
    final phone = usedPhone.group(1) ?? '';
    return '${loc.tr('phone_used_prefix')}$phone${loc.tr('phone_used_suffix')}';
  }

  if (lower.contains('thông tin đăng nhập không hợp lệ') ||
      lower.contains('sai số điện thoại hoặc mật khẩu') ||
      lower.contains('bad credentials') ||
      lower.contains('unauthorized')) {
    final hasPrefix = lower.contains('đăng nhập thất bại');
    return hasPrefix
        ? '${loc.tr('login_failed_prefix')}${loc.tr('invalid_login_credentials')}'
        : loc.tr('invalid_login_credentials');
  }

  if (lower.contains('tài khoản cửa hàng đang chờ admin phê duyệt')) {
    final hasPrefix = lower.contains('đăng nhập thất bại');
    final body =
        '${loc.tr('store_pending_approval')}. ${loc.tr('please_try_again_later')}';
    return hasPrefix ? '${loc.tr('login_failed_prefix')}$body' : body;
  }

  if (lower.contains('tài khoản chưa được kích hoạt') ||
      lower.contains('not activated') ||
      lower.contains('inactive')) {
    return loc.tr('account_not_activated');
  }

  if (lower.contains('tài khoản đã bị khóa') ||
      lower.contains('tài khoản của bạn đã bị khóa') ||
      lower.contains('blocked') ||
      lower.contains('banned')) {
    return loc.tr('account_blocked');
  }

  if (lower.contains('số điện thoại chưa được đăng ký') ||
      lower.contains('không tìm thấy tài khoản') ||
      lower.contains('not found')) {
    return loc.tr('phone_not_registered');
  }

  if (lower.contains('số điện thoại không được để trống')) {
    return loc.tr('phone_empty_backend');
  }

  if (lower.contains('số điện thoại không hợp lệ (phải có 10 chữ số, bắt đầu bằng 0)')) {
    return loc.tr('phone_invalid_backend');
  }

  if (lower.contains('mật khẩu không được để trống')) {
    return loc.tr('password_empty_backend');
  }

  if (lower.contains('mật khẩu phải có ít nhất 6 ký tự')) {
    return loc.tr('password_min_6_backend');
  }

  if (lower.contains('lỗi máy chủ')) {
    return loc.tr('general_server_error');
  }

  if (lower.contains('đã xảy ra lỗi không xác định')) {
    return loc.tr('unknown_error');
  }

  message = message.replaceAll('Đăng nhập thất bại: ', loc.tr('login_failed_prefix'));
  message = message.replaceAll('Đăng ký thất bại: ', loc.tr('register_failed_prefix'));
  message = message.replaceAll(
    'Tài khoản cửa hàng đang chờ Admin phê duyệt',
    loc.tr('store_pending_approval'),
  );
  message = message.replaceAll('Vui lòng thử lại sau', loc.tr('please_try_again_later'));
  message = message.replaceAll('Đã xảy ra lỗi không xác định', loc.tr('unknown_error'));

  final stillContainsVietnamese = RegExp(r'[\u00C0-\u1EF9]').hasMatch(message);
  if (stillContainsVietnamese) {
    if (lower.contains('đăng nhập')) {
      return '${loc.tr('login_failed_prefix')}${loc.tr('auth_request_failed')}';
    }
    if (lower.contains('đăng ký')) {
      return '${loc.tr('register_failed_prefix')}${loc.tr('auth_request_failed')}';
    }
    return loc.tr('auth_request_failed');
  }

  return message;
}
