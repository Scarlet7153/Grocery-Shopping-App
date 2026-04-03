//import 'package:flutter/material.dart';
import 'apps/customer/main_customer.dart' as customer;
import 'apps/store/main_store.dart' as store;
import 'apps/shipper/main_shipper.dart' as shipper;
import 'apps/admin/main_admin.dart' as admin;
import 'core/config/app_config.dart';
import 'core/enums/app_type.dart'; 

void main() {
  // Có thể thay đổi AppType để build app khác nhau
  switch (AppConfig.currentApp) {
    case AppType.customer:
      customer.main();
      break;
    case AppType.store:
      store.main();
      break;
    case AppType.shipper:
      shipper.main();
      break;
    case AppType.admin:
      admin.main();
      break;
  }
}