/// Exactly 10 demo rows for POST /products — names match [productImages] keys in
/// [store_products_screen] so asset images align without imageUrl.
class StoreDemoProductRow {
  final String name;
  final String? description;
  final double price;
  final int stock;

  const StoreDemoProductRow({
    required this.name,
    this.description,
    required this.price,
    required this.stock,
  });
}

/// Mini grocery / đi chợ hộ — realistic VND prices and stock.
const List<StoreDemoProductRow> kStoreDemoProducts = [
  StoreDemoProductRow(
    name: 'Táo Mỹ',
    description: 'Táo đỏ nhập khẩu',
    price: 45000,
    stock: 42,
  ),
  StoreDemoProductRow(
    name: 'Chuối',
    description: 'Chuối tiêu hữu cơ',
    price: 18000,
    stock: 80,
  ),
  StoreDemoProductRow(
    name: 'Cam',
    description: 'Cam sành ngọt',
    price: 35000,
    stock: 55,
  ),
  StoreDemoProductRow(
    name: 'Xoài',
    description: 'Xoài cát Hòa Lộc',
    price: 65000,
    stock: 28,
  ),
  StoreDemoProductRow(
    name: 'Dưa hấu',
    description: 'Dưa hấu không hạt',
    price: 22000,
    stock: 36,
  ),
  StoreDemoProductRow(
    name: 'Cà chua',
    description: 'Cà chua Đà Lạt',
    price: 25000,
    stock: 48,
  ),
  StoreDemoProductRow(
    name: 'Bắp cải',
    description: 'Bắp cải trắng',
    price: 15000,
    stock: 12,
  ),
  StoreDemoProductRow(
    name: 'Nho',
    description: 'Nho xanh không hạt',
    price: 89000,
    stock: 8,
  ),
  StoreDemoProductRow(
    name: 'Lê',
    description: 'Lê Hàn Quốc',
    price: 75000,
    stock: 30,
  ),
  StoreDemoProductRow(
    name: 'Thanh long',
    description: 'Thanh long ruột đỏ',
    price: 32000,
    stock: 44,
  ),
];

/// Tên demo dùng để gom và xóa bản trùng (seed) an toàn.
const Set<String> kDemoProductNames = {
  'Táo Mỹ',
  'Chuối',
  'Cam',
  'Xoài',
  'Dưa hấu',
  'Cà chua',
  'Bắp cải',
  'Nho',
  'Lê',
  'Thanh long',
};
