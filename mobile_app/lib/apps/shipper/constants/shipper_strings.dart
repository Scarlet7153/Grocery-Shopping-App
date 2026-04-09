/// Shipper App - UI Strings & Localization Constants
/// Mục đích: Tập trung quản lý tất cả UI strings tiếng Việt
class ShipperStrings {
  // ========== STATUS LABELS (Nhãn trạng thái đơn hàng) ==========
  static const String statusPickingUp = 'Đang lấy hàng';
  static const String statusDelivering = 'Đang giao hàng';
  static const String statusDelivered = 'Đã giao';
  static const String statusReady = 'Sẵn sàng';
  static const String statusPending = 'Chờ xử lý';
  static const String statusCancelled = 'Đã hủy';
  static const String statusUnknown = 'Không xác định';

  // ========== BUTTON LABELS (Văn bản nút bấm) ==========
  static const String buttonMap = 'Bản đồ';
  static const String buttonDetails = 'Chi tiết';
  static const String buttonStart = 'Nhận đơn';
  static const String buttonProcessing = 'Đang xử lý...';

  // ========== EMPTY STATES (Trạng thái trống) ==========
  static const String emptyOrdersTitle = 'Không có đơn hàng nào';
  static const String emptyOrdersSubtitle =
      'Vui lòng quay lại sau để xem đơn giao hàng mới';

  // ========== METRICS & INFO (Thông tin & Chỉ số) ==========
  static const String itemsLabel = 'sản phẩm';
  static const String kmUnit = 'km';

  // ========== DASHBOARD TABS (Tab trên dashboard) ==========
  static const String tabOverview = 'Tổng quan';
  static const String tabHistory = 'Lịch sử';
  static const String tabStats = 'Thống kê';
  static const String tabProfile = 'Hồ sơ';

  // ========== FILTER & SORTING ==========
  static const String filterAll = 'Tất cả';
  static const String filterCompleted = 'Đã hoàn thành';
  static const String filterCancelled = 'Đã hủy';

  // ========== DELIVERY INFO (Thông tin giao hàng) ==========
  static const String deliveryDistance = 'Khoảng cách';
  static const String deliveryFee = 'Phí giao';
  static const String deliveryItems = 'Số mặt hàng';
  static const String deliveryAddress = 'Địa chỉ giao';
  static const String customerName = 'Tên khách hàng';
  static const String storeName = 'Tên cửa hàng';
}
