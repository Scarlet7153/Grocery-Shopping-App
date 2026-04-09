// One-off: compress product JPGs to 512x512 and ~100-200KB. Run: dart run tool/compress_product_images.dart
import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  const targetSize = 512;
  const minKB = 100;
  const maxKB = 200;
  final dir = Directory('assets/products');
  final files = [
    'tao_my.jpg',
    'chuoi.jpg',
    'cam.jpg',
    'xoai.jpg',
    'dua_hau.jpg',
    'ca_chua.jpg',
    'bap_cai.jpg',
    'nho.jpg',
    'le.jpg',
    'thanh_long.jpg',
    'oi.jpg',
    'gung.jpg',
    'toi.jpg',
    'ca_basa.jpg',
    'tom_tuoi.jpg',
    'cai_thao.jpg',
    'can_tay.jpg',
    'bi_xanh.jpg',
    'ca_tim.jpg',
    'mi_goi.jpg',
  ];

  for (final name in files) {
    final file = File('${dir.path}/$name');
    if (!file.existsSync()) {
      print('Skip (not found): $name');
      continue;
    }
    final bytes = file.readAsBytesSync();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) {
      print('Skip (decode fail): $name');
      continue;
    }
    if (image.width != targetSize || image.height != targetSize) {
      image = img.copyResize(image, width: targetSize, height: targetSize);
    }
    int quality = 78;
    for (final q in [78, 72, 68, 65, 60]) {
      final jpg = img.encodeJpg(image, quality: q);
      if (jpg.length >= minKB * 1024 && jpg.length <= maxKB * 1024) {
        quality = q;
        break;
      }
      if (jpg.length <= maxKB * 1024) {
        quality = q;
        break;
      }
      quality = q;
    }
    final jpg = img.encodeJpg(image, quality: quality);
    file.writeAsBytesSync(jpg);
    print('$name: ${jpg.length ~/ 1024} KB (quality $quality)');
  }
  print('Done.');
}
