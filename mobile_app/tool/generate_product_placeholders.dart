// ignore_for_file: avoid_print
// One-off script: run from project root with `dart run tool/generate_product_placeholders.dart`
// Requires: dev_dependency image

import 'dart:io';
import 'package:image/image.dart' as img;

img.Color colorFromHex(int argb) {
  return img.ColorUint8.rgba(
    (argb >> 16) & 0xFF,
    (argb >> 8) & 0xFF,
    argb & 0xFF,
    (argb >> 24) & 0xFF,
  );
}

void main() {
  const size = 512;
  const lightBg = 0xFFF8F4E6; // light cream
  final outDir = Directory('assets/products');
  if (!outDir.existsSync()) outDir.createSync(recursive: true);

  const products = [
    ('tao_my.jpg', 'Táo Mỹ'),
    ('chuoi.jpg', 'Chuối'),
    ('cam.jpg', 'Cam'),
    ('xoai.jpg', 'Xoài'),
    ('dua_hau.jpg', 'Dưa hấu'),
    ('ca_chua.jpg', 'Cà chua'),
    ('bap_cai.jpg', 'Bắp cải'),
    ('nho.jpg', 'Nho'),
    ('le.jpg', 'Lê'),
    ('thanh_long.jpg', 'Thanh long'),
    ('oi.jpg', 'Ổi'),
    ('gung.jpg', 'Gừng'),
    ('toi.jpg', 'Tỏi'),
    ('ca_basa.jpg', 'Cá basa'),
    ('tom_tuoi.jpg', 'Tôm tươi'),
    ('cai_thao.jpg', 'Cải thảo'),
    ('can_tay.jpg', 'Cần tây'),
    ('bi_xanh.jpg', 'Bí xanh'),
    ('ca_tim.jpg', 'Cà tím'),
    ('mi_goi.jpg', 'Mì gói'),
  ];

  for (final p in products) {
    final image = img.Image(width: size, height: size);
    img.fill(image, color: colorFromHex(lightBg));
    const pad = 80;
    img.fillRect(
      image,
      x1: pad,
      y1: pad,
      x2: size - pad,
      y2: size - pad,
      color: colorFromHex(0xFFE8E0C8),
    );
    final label = p.$2;
    final textColor = colorFromHex(0xFF333333);
    try {
      img.drawString(
        image,
        p.$2,
        font: img.arial24,
        x: size ~/ 2 - 60,
        y: size ~/ 2 - 14,
        color: textColor,
      );
    } catch (_) {
      img.drawString(
        image,
        p.$1.replaceAll('.jpg', ''),
        font: img.arial24,
        x: size ~/ 2 - 50,
        y: size ~/ 2 - 14,
        color: textColor,
      );
    }
    final jpg = img.encodeJpg(image, quality: 85);
    final file = File('${outDir.path}/${p.$1}');
    file.writeAsBytesSync(jpg);
    print('Created ${p.$1} (${jpg.length ~/ 1024} KB)');
  }

  // default.jpg
  final def = img.Image(width: size, height: size);
  img.fill(def, color: colorFromHex(lightBg));
  img.drawString(
    def,
    'San pham',
    font: img.arial24,
    x: size ~/ 2 - 50,
    y: size ~/ 2 - 14,
    color: colorFromHex(0xFF333333),
  );
  File(
    '${outDir.path}/default.jpg',
  ).writeAsBytesSync(img.encodeJpg(def, quality: 85));
  print('Created default.jpg');
  print('Done. Generated ${products.length + 1} images in assets/products/');
}
