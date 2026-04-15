class AuthSession {
  static String? token;
  static String? fullName;
  static String? address;
  static String? phoneNumber;
  static String? avatarUrl;
  static List<Map<String, dynamic>> savedAddresses = [];
  static int selectedAddressIndex = 0;
  static bool defaultHasOtherReceiver = false;
  static String? defaultOtherReceiverName;
  static String? defaultOtherReceiverPhone;
  static String? defaultOtherReceiverTitle;

  static void clear() {
    token = null;
    fullName = null;
    address = null;
    phoneNumber = null;
    avatarUrl = null;
    savedAddresses = [];
    selectedAddressIndex = 0;
    defaultHasOtherReceiver = false;
    defaultOtherReceiverName = null;
    defaultOtherReceiverPhone = null;
    defaultOtherReceiverTitle = null;
  }
}
