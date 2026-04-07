import 'package:intl/intl.dart';

String formatVnd(num value) {
  final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  return formatter.format(value);
}
