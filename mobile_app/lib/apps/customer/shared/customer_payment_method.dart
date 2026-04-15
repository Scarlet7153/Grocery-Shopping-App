enum CustomerPaymentMethod { cod, momo, vnpay }

extension CustomerPaymentMethodX on CustomerPaymentMethod {
  String get label {
    switch (this) {
      case CustomerPaymentMethod.cod:
        return 'Tiền mặt khi nhận hàng';
      case CustomerPaymentMethod.momo:
        return 'Ví MoMo';
      case CustomerPaymentMethod.vnpay:
        return 'VNPay';
    }
  }

  String get backendValue {
    switch (this) {
      case CustomerPaymentMethod.cod:
        return 'COD';
      case CustomerPaymentMethod.momo:
        return 'MOMO';
      case CustomerPaymentMethod.vnpay:
        return 'VNPAY';
    }
  }
}

