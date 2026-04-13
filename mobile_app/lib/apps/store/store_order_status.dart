/// Trạng thái đơn (chuỗi backend) được coi là "Đang chuẩn bị" — dùng chung cho
/// dashboard và màn Đơn (tab/chip), khớp các giá trị enum backend hiện có trong app.
bool storeOrderStatusIsPreparing(String? status) {
  switch ((status ?? '').toUpperCase()) {
    case 'CONFIRMED':
    case 'PICKING_UP':
    case 'PROCESSING':
      return true;
    default:
      return false;
  }
}
