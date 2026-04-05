class AuthSession {
  static String? token;
  static String? fullName;
  static String? address;
  static String? phoneNumber;

  static void clear() {
    token = null;
    fullName = null;
    address = null;
    phoneNumber = null;
  }
}
