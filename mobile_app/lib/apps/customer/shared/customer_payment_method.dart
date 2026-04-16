import 'package:flutter/widgets.dart';

import '../utils/customer_l10n.dart';

enum CustomerPaymentMethod { cod, momo }

extension CustomerPaymentMethodX on CustomerPaymentMethod {
  String get label {
    switch (this) {
      case CustomerPaymentMethod.cod:
        return 'Tiền mặt khi nhận hàng';
      case CustomerPaymentMethod.momo:
        return 'Ví MoMo';
    }
  }

  String get backendValue {
    switch (this) {
      case CustomerPaymentMethod.cod:
        return 'COD';
      case CustomerPaymentMethod.momo:
        return 'MOMO';
    }
  }

  String labelOf(BuildContext context) {
    switch (this) {
      case CustomerPaymentMethod.cod:
        return context.tr(
          vi: 'Tiền mặt khi nhận hàng',
          en: 'Cash on delivery',
        );
      case CustomerPaymentMethod.momo:
        return context.tr(vi: 'Ví MoMo', en: 'MoMo Wallet');
    }
  }
}
