import 'package:flutter/foundation.dart';

import 'customer_payment_method.dart';

class CustomerPaymentPreferences {
  CustomerPaymentPreferences._();

  static final ValueNotifier<CustomerPaymentMethod> method =
      ValueNotifier<CustomerPaymentMethod>(CustomerPaymentMethod.cod);
}

