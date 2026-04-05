class StoreModel {

  final String name;
  final String address;
  final String status;
  final int revenueToday;
  final int ordersToday;

  StoreModel({
    required this.name,
    required this.address,
    required this.status,
    required this.revenueToday,
    required this.ordersToday,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {

    return StoreModel(
      name: json["name"] ?? "",
      address: json["address"] ?? "",
      status: json["status"] ?? "",
      revenueToday: json["revenueToday"] ?? 0,
      ordersToday: json["ordersToday"] ?? 0,
    );

  }
}