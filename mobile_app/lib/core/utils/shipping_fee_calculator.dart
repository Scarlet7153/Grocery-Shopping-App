/// Tính phí vận chuyển theo khoảng cách (km)
///
/// Quy tắc (mặc định):
/// - 0 - 3.0 km     : 16,000đ
/// - 3.1 - 4.0 km   : 20,000đ
/// - 4.1 - 5.0 km   : 25,000đ
/// - > 5.0 km       : round(km) * 5,000đ
///
/// Ví dụ: 6.1km -> round(6.1)=6 -> 30,000đ
///         6.5km -> round(6.5)=7 -> 35,000đ
class ShippingFeeCalculator {
  static const double _tier1Max = 3.0;
  static const double _tier2Max = 4.0;
  static const double _tier3Max = 5.0;

  static const double _feeTier1 = 16000;
  static const double _feeTier2 = 20000;
  static const double _feeTier3 = 25000;
  static const double _feePerKmOver5 = 5000;

  /// Phí mặc định thấp nhất (0-3km)
  static double get defaultFee => _feeTier1;

  /// Tính phí ship theo km (distanceKm >= 0)
  static double calculate(double distanceKm) {
    if (distanceKm <= 0) return 0;

    if (distanceKm <= _tier1Max) {
      return _feeTier1;
    } else if (distanceKm <= _tier2Max) {
      return _feeTier2;
    } else if (distanceKm <= _tier3Max) {
      return _feeTier3;
    } else {
      final roundedKm = distanceKm.round();
      return roundedKm * _feePerKmOver5;
    }
  }

  /// Format tiền VNĐ
  static String format(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        )}đ';
  }
}
