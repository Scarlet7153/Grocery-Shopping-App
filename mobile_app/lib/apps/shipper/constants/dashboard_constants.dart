/// Constants for Shipper Dashboard
class DashboardConstants {
  // API Keys
  static const String graphHopperApiKey =
      'c251cd70-5c14-49fe-a134-0ad33f0bf0ed';
  // Sample data - for demo/preview purposes
  static const String sampleCustomerName = 'Nguyễn Văn A';
  static const String sampleShipperName = 'Nguyễn Văn A';
  static const String sampleShipperRole = 'Shipper';
  static const String sampleCustomerPhone = '0901234567';
  static const String sampleStoreName = 'Bách Hóa Xanh';
  static const String sampleStoreAddress = '456 Lê Lợi, Quận 1, TP.HCM';
  static const String sampleDeliveryAddress =
      '123 Đường Nguyễn Trãi, Quận 1, TP.HCM';
  static const String sampleCustomerName2 = 'Lê Thị C';
  static const String sampleCustomerPhone2 = '0909876543';
  static const String sampleStoreName2 = 'Mini Mart C';
  static const String sampleStoreAddress2 = '123 Nguyen Hue, District 1, HCMC';
  static const String sampleDeliveryAddress2 = '789 Đường C, Quận 5';

  // Sample amounts (in VND)
  static const double sampleAmount1 = 30000;
  static const double sampleShippingFee1 = 15000;
  static const double sampleGrandTotal1 = 45000;
  static const double sampleAmount2 = 40000;
  static const double sampleShippingFee2 = 12000;
  static const double sampleGrandTotal2 = 52000;

  // Sample distances
  static const double sampleDistance1 = 2.3;

  // Sample values
  static const double sampleOnlineEarnings = 120000.0;
  static const int sampleCompletedCount = 12;
  static const double sampleAcceptanceRate = 87.5;

  // Profile section labels
  static const String labelPersonalInfo = 'Thông tin cá nhân';
  static const String labelHelpCenter = 'Trung tâm trợ giúp';
  static const String labelAppSettings = 'Cài đặt ứng dụng';
  static const String labelLogout = 'Đăng xuất';

  // Help center topics
  static const String topicOrders = 'Vấn đề đơn hàng';
  static const String topicPayment = 'Thanh toán & Ví';
  static const String topicAccount = 'Tài khoản';
  static const String topicPolicy = 'Chính sách';

  // App info
  static const String appVersion = '1.0.0';
  static const String languageName = 'Tiếng Việt';

  // Avatar initials
  static const String avatarInitial = 'S';

  // Messages
  static const String msgNoAvailableOrders = 'Không có đơn hàng sẵn';
  static const String msgEnableOnlineStatus =
      'Hãy bật trạng thái hoạt động để nhận đơn hàng';
  static const String msgNoOrdersFound = 'Không tìm thấy đơn hàng';
  static const String msgTryClearFilters =
      'Thử bỏ qua bộ lọc để xem tất cả đơn hàng';
  static const String msgFilterReset = 'Bộ lọc được đặt lại';
  static const String msgDataUpdating = 'Đang cập nhật dữ liệu...';
  static const String msgChangeAvatarSimulated =
      'Mô phỏng thay đổi ảnh đại diện';
  static const String msgChangeSaved = 'Đã lưu thay đổi (mô phỏng)';
  static const String msgContactSupport = 'Gọi tổng đài 24/7 (mô phỏng)';
  static const String msgChatSupport = 'Chat với CSKH (mô phỏng)';
  static const String msgLogoutConfirm = 'Bạn có chắc muốn đăng xuất không?';
  static const String msgLogoutSuccess = 'Đã đăng xuất';
  static const String msgCancel = 'Hủy';
  static const String msgLogoutButton = 'Đăng xuất';

  // Dialog labels
  static const String dialogLogout = 'Đăng xuất?';

  // Field labels
  static const String labelIDNumberInfo =
      'Để thay đổi CCCD/CMND, vui lòng liên hệ tổng đài hỗ trợ.';
  static const String labelPopularTopics = 'Chủ đề phổ biến';
  static const String labelDirectSupport = 'Hỗ trợ trực tiếp';
  static const String labelLanguage = 'Ngôn ngữ';
  static const String labelAppVersion = 'Phiên bản ứng dụng';
  static const String labelDetails = 'Chi tiết';
  static const String labelOnlineHours = 'Giờ online';
  static const String labelWeeklyIncome = 'Thu nhập tuần';
  static const String labelAcceptanceRate = 'Tỷ lệ nhận đơn';
  static const String labelSearchHint = 'Tìm kiếm câu hỏi...';
  static const String labelPushNotifications = 'Thông báo đẩy';
  static const String labelSoundAlerts = 'Âm thanh đơn hàng mới';
  static const String labelAutoAccept = 'Tự động nhận đơn';
  static const String labelSaveChanges = 'Lưu thay đổi';
  static const String labelCallSupport = 'Gọi tổng đài';
  static const String labelChatSupport = 'Chat với CSKH';

  // Available orders list labels
  static const String msgNoAvailableOrdersEnglish = 'No Available Orders';
  static const String msgCheckBackSoon =
      'Check back soon for new delivery requests';
  static const String labelOrderNum = 'Đơn #';
  static const String labelCustomerPrefix = 'Khách: ';
  static const String labelAcceptOrder = 'Nhận đơn';
  static const String labelSkipOrder = 'Bỏ qua';
  static const String labelCompleteOrder = 'Hoàn thành';
}
